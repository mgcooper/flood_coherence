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
stackDataFrames2 <- function(NestedFrames, output_format = "tibble", level_names = NULL) {
   if (!output_format %in% c("tibble", "dt")) {
      stop("output_format must be 'tibble' or 'dt'")
   }

   # Recursive function to flatten the nested list
   flatten <- function(data, path = vector()) {
      if (is.data.frame(data)) {
         # If a data frame is encountered, add it with its path as additional columns
         df <- if (output_format == "tibble") {
            tibble::as_tibble(data)
         } else {
            data.table::as.data.table(data)
         }

         # Add path identifiers
         for (i in seq_along(path)) {
            df[[level_names[i]]] <- path[i]
         }

         return(list(df))
      } else if (is.list(data)) {
         # Recursively process deeper levels
         return(purrr::map_df(names(data), function(key) {
            flatten(data[[key]], c(path, key))
         }, .id = NULL))
      } else {
         stop("Each item in the list must be a data frame or another list.")
      }
   }

   # Initialize level names if not provided
   if (is.null(level_names)) {
      # Use a recursive function to estimate depth
      depth_estimate <- function(x, depth = 0) {
         if (is.list(x)) max(unlist(lapply(x, depth_estimate, depth = depth + 1)), na.rm = TRUE) else depth
      }

      max_depth <- depth_estimate(NestedFrames)
      level_names <- paste0("Level", seq_len(max_depth))
   }

   # Flatten the entire structure
   result <- flatten(NestedFrames)

   return(result)
}
