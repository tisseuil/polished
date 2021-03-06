% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/deploy_app.R
\name{deploy_app}
\alias{deploy_app}
\title{Deploy a Shiny app to Polished Hosting}
\usage{
deploy_app(
  app_name,
  app_dir = ".",
  api_key = getOption("polished")$api_key,
  api_url = "https://api.polished.tech"
)
}
\arguments{
\item{app_name}{You Shiny app's name.}

\item{app_dir}{The path to the directory containing your Shiny app.}

\item{api_key}{Your polished.tech API key.  Defaults to \code{getOption("polished")$api_key}.}

\item{api_url}{The Polished API url.  Defaults to "https://api.polished.tech".}
}
\description{
Deploy a Shiny app to Polished Hosting
}
\examples{

\dontrun{
deploy_app(
  app_name = "polished_example_02",
  app_dir = system.file("examples/polished_example_01", package = "polished"),
  api_key = "<your polished.tech API key>"
)
}


}
