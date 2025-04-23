save_flood_events <- function(FloodEvents, path_data, save_flag = TRUE) {
   if (save_flag) {
      # Iterate over each basin in the FloodEvents list
      for (basin in names(FloodEvents)) {
         # Check if the folder exists for the basin, and create it if it does not
         if (!dir.exists(file.path(path_data, basin))) {
            dir.create(file.path(path_data, basin), recursive = TRUE)
         }

         # Save the data for each scenario in the basin
         for (scenario in names(FloodEvents[[basin]])) {
            filename <- gsub("\\.", "-", paste0("Flood_events_", scenario))
            filename <- file.path(path_data, basin, paste0(filename, ".csv"))
            write.csv(FloodEvents[[basin]][[scenario]], filename, row.names = FALSE)
         }
      }
   }
}
