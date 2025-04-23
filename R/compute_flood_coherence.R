# Function to filter out duplicate peaks
filterUniquePeaks <- function(floodr_df, peakDateColumn) {
   # Sort by peak date before filtering to ensure the first occurrence is kept
   floodr_df <- floodr_df[order(floodr_df[[peakDateColumn]]), ]
   unique_df <- floodr_df %>%
      dplyr::distinct(!!rlang::sym(peakDateColumn), .keep_all = TRUE)

   return(unique_df)
}

# Function to reorganize FloodEvents by scenarios instead of subbasins
organizeDataByScenario <- function(FloodEvents, scenario, peakDateColumn = "Peak_date") {
   # Extract unique floods for each subbasin and for the specified scenario
   scenarioData <- list()
   for (basin in names(FloodEvents)) {
      if (scenario %in% names(FloodEvents[[basin]])) {
         basinData <- FloodEvents[[basin]][[scenario]]
         # scenarioData[[basin]] <- basinData
         scenarioData[[basin]] <- filterUniquePeaks(basinData, peakDateColumn)
      }
   }
   return(scenarioData)
}

# Function to compute flood coherence score
compute_flood_coherence <- function(FloodEvents, peakDateColumn = "Peak_date") {

   basins = names(FloodEvents)
   scenarios = names(FloodEvents[[basins[1]]])

   # Loop over each scenario and compute FCS
   for (scenario in scenarios) {
      # Organize data for the scenario ensuring unique peak dates
      scenarioData <- organizeDataByScenario(FloodEvents, scenario)

      # Compute FCS using the first version of the function
      result <- calculateFCS(scenarioData, groupA = "Outlet")
      floodCoherenceScore[[scenario]] <- result

      # hist(result$Outlet$FCS, breaks = 0:8)
      # hist(result$Outlet$FCS)
      #
      # hist(result$Outlet$FCS, breaks = 0:16)
      #
      # # Compute FCS using the second version of the function
      # result2 <- calculateFCS2(scenarioData, groupA = "Outlet")
      # floodCoherenceScore2[[scenario]] <- result2
      #
      # identical(result$Outlet$Total_FCS, result2$Outlet$Total_FCS)
      #
      # hist(result2$Outlet$Total_FCS, breaks = 0:8)
      #
      # result3 <- calculateFCS3(scenarioData, groupA = "Outlet")
      # identical(result$Outlet$Total_FCS, result3$Outlet$Total_FCS)
      # hist(result3$Outlet$FCS, breaks = 0:16)
   }
   return(floodCoherenceScore)
}
