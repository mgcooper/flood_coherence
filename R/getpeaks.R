getpeaks <- function(df, identifiers, threshold, by = "scenario") {
   Flood_events <- list()

   # Determine grouping based on the 'by' parameter
   if (by == "scenario") {
      for (thisscenario in identifiers) {
         dailyQ <- df %>% dplyr::select(Time, all_of(thisscenario))

         # Call eventsep with the dailyMQ dataframe
         events <- FloodR::eventsep(dailyQ)

         # Peak less than the given threshold is removed from the flood events
         print(paste("Threshold for", thisscenario, ":", threshold))

         tmp <- events %>%
            dplyr::filter(DailyMQ >= threshold)

         # Create an event ID and Duration column
         tmp <- tmp %>%
            dplyr::mutate(
               Duration = as.numeric(End - Begin) + 1,
               Event_ID = dplyr::row_number()
            )

         # Store the events per scenario
         Flood_events[[thisscenario]] <- tmp
      }
   } else if (by == "subbasin") {

      for (thisbasin in identifiers) {
         # Loop over scenarios since 'id' will be a subbasin here
         scenario_events <- list()
         for (scenario in colnames(df)[-1]) { # Exclude 'Time' column
            dailyQ <- df %>% dplyr::select(Time, all_of(scenario))

            # Call eventsep with the dailyMQ dataframe
            events <- FloodR::eventsep(dailyQ)

            # Peak less than the given threshold is removed from the flood events
            print(paste("Threshold for", scenario, "in", thisbasin, ":", threshold[[thisbasin]]))

            tmp <- events %>%
               dplyr::filter(DailyMQ >= threshold[[thisbasin]])

            # Add the duration of each flood event
            tmp <- tmp %>%
               dplyr::mutate(
                  Duration = as.numeric(End - Begin) + 1,
                  Event_ID = dplyr::row_number()
               )

            # Store the events per scenario within the current subbasin
            scenario_events[[scenario]] <- tmp
         }
         # Aggregate scenario events into subbasin events
         Flood_events[[thisbasin]] <- scenario_events
      }
   }

   return(Flood_events)
}
