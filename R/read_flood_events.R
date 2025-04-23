read_flood_events <- function(path_data) {
   # Initialize an empty list to store subbasin data
   FloodEvents <- list()

   # List all subbasin directories in the main data path
   subbasins <- list.dirs(path_data, full.names = TRUE, recursive = FALSE)

   # Iterate over each subbasin directory
   for (basin_path in subbasins) {
      basin_name <- basename(basin_path)
      FloodEvents[[basin_name]] <- list()  # Initialize a list for this basin

      # List all CSV files for this subbasin
      files <- list.files(basin_path, pattern = "\\.csv$", full.names = TRUE)

      # Read each file and assign to the appropriate scenario in the list
      for (file in files) {
         scenario_name <- gsub("Flood_events_|\\.csv", "", basename(file))
         scenario_name <- gsub("-", "\\.", scenario_name)  # Replace hyphens back to dots if needed
         data <- read.csv(file)

         # Convert columns to Date if they exist
         date_cols <- c("Begin", "End", "Peak_date")
         for (col in date_cols) {
            if (col %in% names(data)) {
               data[[col]] <- as.Date(data[[col]])
            }
         }

         FloodEvents[[basin_name]][[scenario_name]] <- data
      }
   }

   return(FloodEvents)
}
