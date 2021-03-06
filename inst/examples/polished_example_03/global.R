library(shiny)
library(polished)
library(config)
library(shinyjs)

app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_03",
  api_key = app_config$api_key,
  is_auth_required = FALSE
)
