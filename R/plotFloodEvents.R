plotFloodEvents <- function(events_df, flow_df, scenario_names = NULL,
                            palette = NULL, plot_type = NULL,
                            num_events = NULL, legend = FALSE) {
   ############################################################################
   # Input parsing

   # Set default scenario names and color palette if not provided
   if (is.null(scenario_names)) {
      scenario_names <- names(events_df)
   }
   if (is.null(palette)) {
      palette <- viridis::viridis(length(scenario_names), option = "D")
   }
   if (is.null(plot_type)) {
      plot_type <- "ggplot"
   }

   ############################################################################
   # Local functions

   # Function to create the ggplot
   makeggplot <- function(event_flow, scenario_names, palette, event_text) {
      # print(head(event_flow))
      # print(scenario_names)

      # Create the plot
      p <- ggplot(data = event_flow, aes(x = Time))

      # Add a line for each scenario
      for (scenario in scenario_names) {
         p <- p + geom_line(
            aes_string(
               y = scenario,
               color = sprintf("'%s'", scenario)
            ),
            linewidth = 1
         )
      }
      # Format the aesthetics
      p <- p +
         scale_color_manual(
            values = setNames(palette, scenario_names),
            name = "Scenario"
         ) +
         labs(
            title = event_text,
            x = "Date",
            y = "Discharge"
         ) +
         theme_minimal() +
         theme(plot.title = element_text(size = 10),
               plot.title.position = "plot")

      if (legend) {
         p <- p +
            theme(
               legend.position = c(1, 1), # Place legend inside
               legend.justification = c(1, 1), # Anchor to the top right
               legend.title = element_text(size = 8), # Smaller legend title
               legend.text = element_text(size = 8), # Smaller legend items
               legend.background = element_rect(fill = "white", colour = "black"),
            )
      } else {
         p <- p + theme(legend.position = "none")
      }
      return(p)
   }

   # Function to create the plot using base r
   makebaseplot <- function(event_flow, scenario_names, palette, event_text) {
      # Open a new plot window
      plot(event_flow$Time,
           event_flow[[scenario_names[1]]],
           type = "l",
           col = palette[1],
           lwd = 3,
           ylim = range(sapply(
              scenario_names, function(x) event_flow[[x]],
              simplify = TRUE
           )),
           xlab = "Date",
           ylab = "Discharge",
           main = event_text
      )

      # Add additional lines for each scenario
      for (j in 2:length(scenario_names)) {
         lines(event_flow$Time,
               event_flow[[scenario_names[j]]],
               col = palette[j],
               lwd = 3
         )
      }
      # Add a legend
      legend("topright",
             legend = scenario_names,
             col = palette,
             lty = 1,
             cex = 0.8
      )
   }

   ############################################################################
   # MAIN FUNCTION

   # Initialize a list to hold the plots
   plot_list <- list()

   # Use the historical events and plot the scenario events on top
   events_hist <- events_df[[scenario_names[1]]]

   if (is.null(num_events)) {
      num_events <- nrow(events_hist)
   }

   for (i in seq_len(num_events)) {
      start_date <- events_hist$Begin[i]
      final_date <- events_hist$End[i]
      event_text <- paste("Event", i, ": Daily from", start_date, "to", final_date)

      # Extract the flow data during the event
      event_flow <- flow_df %>%
         dplyr::filter(Time >= start_date & Time <= final_date)

      # Make the figure
      if (plot_type == "ggplot") {
         p <- makeggplot(event_flow, scenario_names, palette, event_text)
      } else if (plot_type == "base") {
         p <- makebaseplot(event_flow, scenario_names, palette, event_text)
      } else {
         errorCondition("Unrecognized plot type. Options are ggplot or base")
      }

      # Append the plot
      plot_list[[i]] <- p
   }

   return(plot_list)
}
