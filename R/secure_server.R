#' Secure your Shiny app's server
#'
#' This function is used to secure your Shiny app's server function.  Make sure to pass
#' your Shiny app's server function as the first argument to \code{secure_server()} at
#' the bottom of your Shiny app's \code{server.R} file.
#'
#' @param server A Shiny server function (e.g \code{function(input, output, session) {}})
#' @param custom_admin_server Either \code{NULL}, the default, or a Shiny module server function containing your custom admin
#' server functionality.
#' @param custom_sign_in_server Either \code{NULL}, the default, or a Shiny module server containing your custom
#' sign in server logic.
#' @param allow_reconnect argument to pass to the Shiny \code{session$allowReconnect()} function. Defaults to
#' \code{FALSE}.  Set to \code{TRUE} to allow reconnect with shiny-server and Rstudio Connect.  Set to \code{"force"}
#' for local testing.  See \url{https://shiny.rstudio.com/articles/reconnecting.html} for more information.
#' @param account_module the server code for the user account module.
#' @param splash_module the server code for the splash page.
#'
#' @export
#'
#' @importFrom shiny observeEvent getQueryString callModule
#' @importFrom digest digest
#'
#'
secure_server <- function(
  server,
  custom_sign_in_server = NULL,
  custom_admin_server = NULL,
  allow_reconnect = FALSE,
  account_module = NULL,
  splash_module = NULL
) {

  server <- force(server)

  function(input, output, session) {
    session$userData$user <- reactiveVal(NULL)

    if (isTRUE(allow_reconnect) || allow_reconnect == "force") {
      session$allowReconnect(allow_reconnect)
    }


    # handle the initial input$hashed_cookie
    shiny::observeEvent(input$hashed_cookie, {
      hashed_cookie <- input$hashed_cookie

      if (isTRUE(.global_sessions$get_admin_mode())) {
        session$userData$user(list(
          session_uid = uuid::UUIDgenerate(),
          user_uid = "00000000-0000-0000-0000-000000000000",
          email = "admin@tychobra.com",
          is_admin = TRUE,
          hashed_cookie = character(0),
          email_verified = TRUE,
          roles = NA
        ))

        shiny::updateQueryString(
          queryString = paste0("?page=admin_panel"),
          session = session,
          mode = "push"
        )
        return()
      }

      # attempt to find the signed in user.  If user is signed in, `global_user`
      # will be a list of user data.  If the user is not signed in, `global_user`
      # will be `NULL`
      query_list <- shiny::getQueryString()
      page <- query_list$page
      global_user <- .global_sessions$find(hashed_cookie, paste0("server-", page))

      if (is.null(global_user)) {
        # user is not signed in

        # if the user is not on the sign in page, redirect to sign in and reload
        if ((!identical(page, "sign_in") || (is.null(splash_module) && is.null(page))) &&
            isTRUE(.global_sessions$is_auth_required)) {

          shiny::updateQueryString(
            queryString = paste0("?page=sign_in"),
            session = session,
            mode = "replace"
          )
          session$reload()
        } else {

        session$userData$user(NULL)
          return()
        }



      } else {
        # the user is signed in

        # if the user somehow ends up on the sign_in page, redirect them to the
        # Shiny app and reload

        if (identical(query_list$page, "sign_in")) {
          remove_query_string()
          session$reload()
        }

        #if (isTRUE(global_user$email_verified)) {
        if (is.na(global_user$signed_in_as) || !is.null(query_list$page)) {

          # user is not on the custom Shiny app, so clear the signed in as user
          if (!is.na(global_user$signed_in_as)) {
            # clear signed in as in .global_sessions
            .global_sessions$set_signed_in_as(
              global_user$session_uid,
              NA,
              user_uid = global_user$user_uid
            )
          }

          user_out <- global_user[
            c("session_uid", "user_uid", "email", "is_admin", "hashed_cookie", "email_verified", "roles")
          ]

          session$userData$user(user_out)

        } else {

          signed_in_as_user <- .global_sessions$get_signed_in_as_user(global_user$signed_in_as)
          signed_in_as_user$session_uid <- global_user$session_uid
          signed_in_as_user$hashed_cookie <- global_user$hashed_cookie

          # set email verified to TRUE, so that you go directly to app
          signed_in_as_user$email_verified <- TRUE
          session$userData$user(signed_in_as_user)
        }
      }


    }, ignoreNULL = TRUE)





    # if the user is an admin and on the admin page, set up the admin server
    shiny::observeEvent(session$userData$user(), {
      query_list <- shiny::getQueryString()
      hold_user <- session$userData$user()

      if (isTRUE(hold_user$email_verified) ||
          isFALSE(.global_sessions$is_email_verification_required)) {


        is_on_admin_page <- if (
          isTRUE(.global_sessions$get_admin_mode()) ||
          identical(query_list$page, 'admin_panel')) TRUE else FALSE


        if (isTRUE(hold_user$is_admin) && isTRUE(is_on_admin_page)) {


          shiny::callModule(
            admin_module,
            "admin"
          )

          # custom admin server functionality
          if (isTRUE(!is.null(custom_admin_server))) {
            if (names(formals(custom_admin_server))[[1]] == "id") {
              # new-style Shiny module
              custom_admin_server("custom_admin")
            } else {
              # old-style Shiny module
              callModule(
                custom_admin_server,
                "custom_admin"
              )
            }


          }
        } else if (identical(query_list$page, "account")) {


          # load up the account module
          if (names(formals(account_module))[[1]] == "id") {
            # new-style Shiny module
            account_module("account")
          } else {
            # old-style Shiny module
            shiny::callModule(
              account_module,
              "account"
            )
          }




        } else if (is.null(query_list$page)) {

          # go to the custom app
          if (isTRUE(.global_sessions$is_auth_required)) {
            server(input, output, session)
          }



          # go to admin panel button.  Must load this whether or not the user is an
          # admin so that if an admin is signed in as a non admin, they can still
          # click the button to return to the admin panel.
          shiny::callModule(
            admin_button,
            "polished"
          )


          # set the session to inactive when the session ends
          shiny::onStop(fun = function() {

            tryCatch({

              .global_sessions$set_inactive(
                session_uid = hold_user$session_uid,
                user_uid = hold_user$user_uid
              )

            }, catch = function(err) {
              print('error setting the session to incative')
              print(err)
            })

          })


        }

      } else {

        # go to email verification view.
        # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)

        callModule(
          verify_email_module,
          "verify"
        )
      }

    }, once = TRUE)


    if (isFALSE(.global_sessions$is_auth_required)) {
      server(input, output, session)
    }

    # load up the sign in module server logic if the user in on "sign_in" page

    observeEvent(session$userData$user(), {
      req(is.null(session$userData$user()))

      query_list <- shiny::getQueryString()
      page <- query_list$page

      if (identical(page, "sign_in")) {

        if (is.null(custom_sign_in_server)) {

          shiny::callModule(
            sign_in_module,
            "sign_in"
          )

        } else {


          if (names(formals(custom_sign_in_server))[[1]] == "id") {
            custom_sign_in_server("sign_in")
          } else {
            shiny::callModule(
              custom_sign_in_server,
              "sign_in"
            )
          }

        }
      } else if (is.null(page)) {

        if (!is.null(splash_module) && isTRUE(isFALSE(.global_sessions$is_auth_required))) {

          if (names(formals(splash_module))[[1]] == "id") {
            splash_module("splash")
          } else {
            callModule(
              splash_module,
              "splash"
            )
          }

        }
      }

    }, ignoreNULL = FALSE, once = TRUE)





  }

}
