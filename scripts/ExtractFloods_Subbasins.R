# ---- Setup ----

rm(list = ls())

# Configure paths
dotenv::load_dot_env(file = ".env")
path_project <- path.expand(Sys.getenv("FLOOD_COHERENCE_ROOT", unset = NA))
path_data <- path.expand(Sys.getenv("FLOOD_COHERENCE_DATA_DIR", unset = NA))
path_figs <- path.expand(Sys.getenv("FLOOD_COHERENCE_FIGS_DIR", unset = NA))

if (is.na(path_data)) stop("FLOOD_COHERENCE_DATA_DIR not set. Please define it in your .env file.")
if (is.na(path_figs)) stop("FLOOD_COHERENCE_FIGS_DIR not set. Please define it in your .env file.")

startup_env <- new.env()
source(file.path(path_project, "reload.R"), local = startup_env)
startup_env$reload(function_path = file.path(path_project, "R"))

# ---- Define script options ----

save_subbasin_figures_flag <- FALSE # save a panel of figures showing all flood events identified for each subbasin?
save_event_figures_flag <- FALSE # save a plot of every flood event?
save_data_flag <- FALSE # save the subbasin flood peak files? Set TRUE for first time usage, or if needed to resave the files.
debug_flag <- FALSE # set TRUE as needed.

# ---- Read data ----

# The first part of this script reads the outflow data, which is organized by
# scenario with one file per scenario containing outflow for all subbasins (and
# the outlet), and reorganizes it by subbasin, with one dataframe per subbasin
# containing all scenarios.

scenarios <- c(
   "HIST-1980-2020",
   "SSP545-COOL-FAR", "SSP545-HOT-FAR",
   "SSP585-COOL-FAR", "SSP585-HOT-FAR"
)

# Initialize an empty list for storing the reorganized subbasin data
subbasin_data <- base::list()

# Loop through scenarios, read and store the data
for (ssp in scenarios) {
   # Construct the full file path and read the Excel file
   file_path <- file.path(path_data, paste0(ssp, ".xlsx"))
   df <- readxl::read_excel(file_path, col_names = TRUE)

   # Convert Time column to Date type
   df[[1]] <- as.Date(df[[1]], format = "%d/%m/%Y")

   # Extract subbasin names (excluding Time column)
   subbasins <- colnames(df)[-1]

   # Organize data by subbasin for each scenario
   for (basin in subbasins) {
      if (!is.list(subbasin_data[[basin]])) {
         subbasin_data[[basin]] <- list(Time = df$Time)
      }
      subbasin_data[[basin]][[ssp]] <- df[[basin]]
   }
}

# Assign the calendar to a variable
Time <- subbasin_data$Outlet$Time

# Option to plot the data
if (debug_flag) {
   flow <- subbasin_data$Outlet$`HIST-1980-2020`
   plot(Time[1:100], flow[1:100])
}

# Convert lists to data frames
for (basin in names(subbasin_data)) {
   subbasin_data[[basin]] <- data.frame(subbasin_data[[basin]])
}

# Update the scenario names (dashes are replaced by dots on conversion to df)
scenarios <- base::setdiff(names(subbasin_data$Outlet), "Time")

# Option to plot the data
if (debug_flag) {
   flow <- subbasin_data$Outlet$HIST.1980.2020
   plot(Time[1:100], flow[1:100])
}

# ---- Get peaks ----

# This section loops over each subbasin, finds the historical minimum-annual-maximum flood peak, and uses it as a threshold to identify floods in historical and future scenarios, calling Floodr::eventsep to find independent flood events. Floods which exceed the historical threshold are retained for analysis.

FloodEvents <- list()

# For debugging, use the Outlet column to work inside the for loop
if (debug_flag) {
   basinnames <- names(subbasin_data)
   basin <- basinnames[length(basinnames)]
}

# Analyze each subbasin over all scenarios
for (basin in names(subbasin_data)) {
   # Compute annual minimum thresholds using historical data
   annual_max <- subbasin_data[[basin]] %>%
      dplyr::group_by(Year = year(Time)) %>%
      dplyr::summarize(across(-1, \(x) max(x, na.rm = TRUE)))

   # Get the minimum of the annual maximum peaks
   min_ann_max <- annual_max %>%
      dplyr::summarize(across(everything(), \(x) min(x)))

   # Identify floods for each subbasin main reach
   print(basin)
   FloodEvents[[basin]] <- getpeaks(
      df = subbasin_data[[basin]],
      identifiers = scenarios,
      threshold = min_ann_max$HIST.1980.2020,
      by = "scenario"
   )
}

# ---- Save the peaks ----
save_flood_events(FloodEvents, path_data, save_flag = save_data_flag)

# ---- Plot the peaks ----

# For testing/debugging, use the events for the outlet
if (debug_flag) {
   events_df <- FloodEvents$Outlet # send in all scenarios
   flow_df <- subbasin_data$Outlet
   plot_list <- plotFloodEvents(events_df, flow_df, num_events = 1)
   plot_list[1]
}

# To see one scenario:
# test <- FloodEvents$CrosswicksNeshaminy$HIST.1980.2020

# Create all plots
hist_label <- names(FloodEvents$Outlet)[1]
plot_list <- list()
for (basin in names(subbasin_data)) {
   if (debug_flag) {
      num_events <- 12
   } else {
      num_events <- length(FloodEvents[[basin]][[hist_label]]$Begin)
      num_events <- length(FloodEvents[[basin]][[hist_label]]$Begin)
   }
   plot_list[[basin]] <- plotFloodEvents(
      FloodEvents[[basin]], subbasin_data[[basin]],
      legend = FALSE, num_events = num_events,
   )
}
plot_list$UpperDelaware[1]

# ---- Save the plots ----

for (basin in names(subbasin_data)) {
   # Use the historical period events as a reference
   BasinEvents <- FloodEvents[[basin]][[hist_label]]

   # Define groups and conditions
   groups <- list(
      G1 = 1,
      G2 = 2,
      G3 = 3
   )

   # Iterate over each group for plotting
   for (group_name in names(groups)) {
      # Select events with 1 peak, 2 peaks, and >2 peaks
      if (groups[[group_name]] == 3) {
         EventGroup <- dplyr::filter(BasinEvents, No_Peaks >= groups[[group_name]])
      } else {
         EventGroup <- dplyr::filter(BasinEvents, No_Peaks == groups[[group_name]])
      }

      # To select all events:
      # plot_index <- FloodEvents[[basin]][[hist_label]]$Event_ID

      if (debug_flag) {
         # Select the first N events
         selected_plots <- plot_list[[basin]][1:num_events]
      } else {
         selected_plots <- plot_list[[basin]][EventGroup$Event_ID]
      }

      # Determine the number of columns for layout based on group
      ncol_layout <- if (group_name == "G3") 5 else 3

      combined_plot <- wrap_plots(selected_plots, ncol = ncol_layout)

      filename <- paste(basin, hist_label, substr(group_name, 2, 2), sep = "_")
      filename <- file.path(path_figs, paste0(filename, ".png"))

      if (save_subbasin_figures_flag) {
         ggsave(filename, combined_plot, width = 24, height = 30)
      }
   }
}

# Export plots for a single event
if (save_event_figures_flag) {
   for (basin in names(subbasin_data)) {
      this_list <- plot_list[[basin]]

      for (i in seq_along(this_list)) {
         print(this_list[[i]])

         filename <- paste0(basin, "_flood_event_", i, ".png")
         filename <- file.path(path_figs, "events", filename)
         ggsave(filename, plot = this_list[[i]], width = 6, height = 4, dpi = 300, bg = "white")
      }
   }
}

