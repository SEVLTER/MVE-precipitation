#' Write a data frame to a csv file and invisibly return the file path
#'
#' @param x A data frame to write to disk.
#' @param file File to write to.
#' @param ... Potential arguments passed to `readr::write_csv()`.
#'
#' @returns Path to saved file.
write_csv_file <- function(x, file, ...) {
  write_csv(x, file, ...)
  invisible(file)
}
