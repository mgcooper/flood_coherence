#' Flatten Nested List of Data Frames to a Single data.table or tibble
#'
#' This function takes a deeply nested list of data frames and flattens it into a single data frame or data.table,
#' adding identifying columns for each level of the hierarchy.
#'
#' @param NestedFrames A nested list where each lowest level contains a data frame.
#' @param output_format The format of the output: either "tibble" or "dt" for data.table.
#' @param level_names Names to assign to columns that will identify the levels of the nested list.
#' @return A single data frame or data.table that combines all the data frames in the nested list,
#'         including level identifiers as additional columns.
#' @examples
#' # Assume 'NestedFrames' is a list where each element is a list of data frames categorized by another criterion
#' # The following call will flatten the list into a data frame with levels named 'Level1', 'Level2', etc.
#' flattened_data <- stackDataFrames(NestedFrames, output_format = "tibble", level_names = c("Level1", "Level2"))
#' @export
stackDataFrames <- function(NestedFrames, output_format = "tibble", level_names = NULL) {

   if (!output_format %in% c("tibble", "dt")) {
      stop("output_format must be 'tibble' or 'dt'")
   }

   # Define a recursive function to process each level
   flatten <- function(frames, path = NULL) {
      if (is.data.frame(frames)) {
         data <- if (output_format == "tibble") {
            tibble::as_tibble(frames)
         } else {
            data.table::as.data.table(frames)
         }

         if (!is.null(path) && length(level_names) >= length(path)) {
            for (i in seq_along(path)) {
               data[[level_names[i]]] <- path[i]
            }
         }
         return(data)
      } else if (is.list(frames)) {
         # Recursive case: dive deeper into the list
         results <- purrr::map_df(names(frames), function(name) {
            flatten(frames[[name]], c(path, name))
         }, .id = NULL)
         return(results)
      } else {
         stop("Each item in the list must be a data frame or another list.")
      }
   }

   # Validate level names
   if (is.null(level_names)) {
      level_names <- purrr::map_chr(seq_along(NestedFrames), ~ paste0("Level", .x))
   }

   # Start the flattening process
   stackedFrames <- flatten(NestedFrames)

   return(stackedFrames)
}
