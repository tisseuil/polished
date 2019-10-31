


const NS = (ns_id, prefix = "#") => {
  return (input_id) => prefix + ns_id + "-" + input_id
}


const auth_all = (ns_id) => {
  const ns = NS(ns_id)
  const ns2 = NS(ns_id, "")


  $(ns("email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns("submit_continue_sign_in")).is(":visible")) {

        $(ns("submit_continue_sign_in")).click()

      } else {

        $(ns("submit_sign_in")).click()

      }
    }
  })

  $(ns("password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_sign_in")).click()
    }
  })

  $(ns("register_email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns("submit_continue_register")).is(":visible")) {

        $(ns("submit_continue_register")).click()

      } else {


        $(ns("submit_register")).click()

      }
    }
  })

  $(ns("register_password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_register")).click()
    }
  })

  $(ns("register_password_verify")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_register")).click()
    }
  })


}



