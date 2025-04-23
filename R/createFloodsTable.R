#' Create Floods Table by stacking FloodR Data Frames into a Single tibble
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
#' flattened_data <- createFloodsTable(NestedFrames, output_format = "tibble", level_names = c("Level1", "Level2"))
#' @export
createFloodsTable <- function(NestedFrames, output_format = "tibble", level_names = c("Level1", "Level2")) {

   if (!output_format %in% c("tibble", "dt")) {
      stop("output_format must be 'tibble' or 'dt'")
   }

   # Helper function to process each innermost data frame
   processOneFrame <- function(data, labels) {
      if (output_format == "tibble") {
         data <- tibble::as_tibble(data)
      } else {
         data <- data.table::as.data.table(data)
      }

      # Add columns for each level label
      for (i in seq_along(labels)) {
         data[[level_names[i]]] <- labels[i]
      }
      return(data)
   }

   # Flatten the frames by recursively processing the nested list
   stackedFrames <- purrr::map_df(names(NestedFrames), function(level1) {
      purrr::map_df(names(NestedFrames[[level1]]), function(level2) {
         processOneFrame(NestedFrames[[level1]][[level2]], c(level1, level2))
      }, .id = "id2")
   }, .id = "id1")

   return(stackedFrames)
}
