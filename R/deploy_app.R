#' Deploy a Shiny app to Polished Hosting
#'
#' @param app_name You Shiny app's name.
#' @param app_dir The path to the directory containing your Shiny app.
#' @param api_key Your polished.tech API key.  Defaults to \code{getOption("polished")$api_key}.
#' @param api_url The Polished API url.  Defaults to "https://api.polished.tech".
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#' deploy_app(
#'   app_name = "polished_example_02",
#'   app_dir = system.file("examples/polished_example_01", package = "polished"),
#'   api_key = "<your polished.tech API key>"
#' )
#' }
#'
#'
deploy_app <- function(app_name, app_dir = ".", api_key = getOption("polished")$api_key, api_url = "https://api.polished.tech") {

  app_zip_path <- bundle_app(
    app_dir = app_dir
  )

  zip_to_send <- httr::upload_file(
    path = app_zip_path,
    type = "application/x-gzip"
  )

  res <- httr::POST(
    url = paste0(api_url, "/deploy-app"),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      app_zip = zip_to_send
    ),
    query = list(
      app_name = app_name
    ),
    encode = "multipart",
    config = list(http_version = 0)
  )

  if (!identical(httr::status_code, 200L)) {
    stop("Failed to upload the Shiny app to Polished Hosting.")

  }
  message("Shiny app successfully uploaded.")

  invisible()
}


#' Create a tar archive
#'
#' This function is called by \code{deploy_app()} to compress Shiny apps before
#' deploying them to Polished Hosting.  You probably won't need to call this function
#' directly.
#'
#' @param app_dir The path to the directory containing your Shiny app.  Defaults to the
#' working directory.
#'
#' @export
#'
#' @importFrom automagic make_deps_file
#'
#' @examples
#'
#' bundle_app(
#'   system.file("examples/polished_example_01", package = "polished")
#' )
#'
bundle_app <- function (
  app_dir = "."
) {

  # create yaml file with all the dependencies
  automagic::make_deps_file(directory = app_dir)

  tar_name <- "shiny_app.tar.gz"

  bundles_dir <- tempdir()

  file <- file.path(bundles_dir, tar_name)

  current_wd <- getwd()
  setwd(app_dir)
  on.exit({setwd(current_wd)}, add = TRUE)
  result <- utils::tar(
    tarfile = file,
    compression = "gzip",
    tar = "internal"
  )

  if (result != 0) {
    stop("Failed to bundle the Shiny app.")
  }
  message("The Shiny app has been bundled at:\n- \"", file, "\"")

  file
}

