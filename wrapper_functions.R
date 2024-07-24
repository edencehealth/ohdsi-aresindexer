#!/usr/bin/Rscript

getcfg <- function(envvar_name, default_value, help) {
  # Return the environment variable if it's set, otherwise return the default value
  # currently the "help" arg is silently discarded, in the future we will use this info to build help text
  env_value <- Sys.getenv(envvar_name, unset = NA)

  result <- if (!is.na(env_value) && env_value != "") {
    env_value
  } else {
    default_value
  }

  message(sprintf("config: %s='%s'", envvar_name, result))
  return(result)
}

parseBool <- function(str_value) {
  toupper(str_value) %in% c("1", "TRUE", "YES", "Y", "ON")
}

getVersionStr <- function(wrapper_version) {
  paste(
    "edenceHealth AresIndexer Wrapper:", wrapper_version,
    "/ AresIndexer:", packageVersion("AresIndexer"),
    "/ Achilles:", packageVersion("Achilles"),
    "/ DataQualityDashboard:", packageVersion("DataQualityDashboard"),
    "\n"
  )
}


#' Parse a Delimited String into a List of Elements
#'
#' This function takes an input string and splits it into a list of elements
#' based on a specified delimiter. Optionally trims whitespace around elements.
#'
#' @param input A character string to be split.
#' @param delimiter A character string used as the delimiter. Default is ",".
#' @param trim_ws Logical. Whether to trim whitespace around elements. Default is TRUE.
#' @return A list of elements split by the delimiter.
#' @examples
#' parseListArg("apple, banana, cherry")
#' parseListArg("apple;banana;cherry", delimiter = ";")
#' parseListArg("", delimiter = ";")
parseListArg <- function(input, delimiter = ",", trim_ws = TRUE) {
  if (is.null(input) || input == "") {
    return(character(0))
  }

  elements <- unlist(strsplit(input, delimiter))

  if (trim_ws) {
    elements <- trimws(elements)
  }

  return(elements)
}

# these dbms require the database name to be appended to the hostname
name_concat_dbms <- list(
  "netezza",
  "oracle",
  "postgresql",
  "redshift"
)

no_index_dbms <- list(
  "netezza",
  "redshift"
)
