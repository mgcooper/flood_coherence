rm(list = ls())

# This script runs the FloodR flood identification algorithm to identify flood peaks at the Delaware Estuary inlet, using the DHSVM-modeled hydrograph of daily flows saved in the data/daily_mean_flow.csv file. At the end of the script, there are examples of how to save figures showing all identified flood events, printed to .png files.

save_data_flag <- FALSE # Set this true to save the identified flood peaks for each scenario (historical and each RCP scenario)
save_figures_flag <- FALSE # Set this true to save a panel of figures showing the identified flood peaks.

dotenv::load_dot_env(file = ".env")
pathname_data <- path.expand(Sys.getenv("FLOOD_COHERENCE_DATA_DIR", unset = NA))
pathname_figs <- path.expand(Sys.getenv("FLOOD_COHERENCE_FIGS_DIR", unset = NA))

# read data  ---------------------------------------------------------
file_path <- file.path(pathname_data, "daily_mean_flow.csv")
df <- read.csv(file_path, stringsAsFactors = FALSE, header = FALSE)

# Convert the first column to a Date type
df[, 1] <- as.Date(df[, 1], format = "%d/%m/%Y")

# Ensure the other columns are treated as floats
for (i in 2:ncol(df)) {
   df[, i] <- as.numeric(df[, i])
}

# get the annual maximum for each data column
annual_max <- df %>%
   dplyr::group_by(Year = year(V1)) %>%
   dplyr::summarise(across(starts_with("V"), max, na.rm = TRUE))
annual_max <- annual_max %>%
   dplyr::filter(!if_any(V2:V6, ~ .x == -Inf))

# get the minimum of annual maximum for each data column
ann_min <- annual_max %>%
   dplyr::summarize(across(V2:V6, min))

# identify floods for each main reach  ----------------------------------------
# Loop through columns from V2 to V10
selected_columns <- c("V2", "V3", "V4", "V5", "V6")
legend <- c(
   V2 = "1980-2020-WRF-DIST", V3 = "SSP545-COOL-FAR",
   V4 = "SSP545-HOT-FAR", V5 = "SSP585-COOL-FAR", V6 = "SSP585-HOT-FAR"
)
Flood_events <- list()
dailyQ <- list()
for (col_name in selected_columns) {
   dailyQ[[col_name]] <- df %>% dplyr::select(V1, all_of(col_name))

   # Clean data by removing NA
   dailyQ_cleaned <- dailyQ[[col_name]] %>%
      dplyr::filter(!is.na(.data[[col_name]]))

   events <- FloodR::eventsep(dailyQ_cleaned)

   # peak < the given threshold is removed from the flood events
   # threshold <- ann_min[[col_name]][1]
   threshold <- ann_min[["V2"]][1]
   # threshold <- unname(return_levels[[col_name]][1])
   print(threshold)
   tmp <- events %>%
      dplyr::filter(DailyMQ >= threshold)

   # add the duration of each flood event
   Flood_events[[col_name]] <- tmp %>%
      dplyr::mutate(Duration = as.numeric(End - Begin) + 1)
}

# save the flood events to csv
if (save_data_flag) {
   write.csv(Flood_events["V2"], file.path(pathname_data, "Flood_events_HIST.csv"), row.names = FALSE)
   write.csv(Flood_events["V3"], file.path(pathname_data, "Flood_events_SSP545-COOL-FAR.csv"), row.names = FALSE)
   write.csv(Flood_events["V4"], file.path(pathname_data, "Flood_events_SSP545-HOT-FAR.csv"), row.names = FALSE)
   write.csv(Flood_events["V5"], file.path(pathname_data, "Flood_events_SSP585-COOL-FAR.csv"), row.names = FALSE)
   write.csv(Flood_events["V6"], file.path(pathname_data, "Flood_events_SSP585-HOT-FAR.csv"), row.names = FALSE)
}

# group the data based on criteria ----------------------------

# G1: 1 peak and duration < 10 days
col_name <- "V2"
df_V2 <- as.data.frame(Flood_events[[col_name]])

# Add the Original_ID column
df_V2 <- df_V2 %>%
   dplyr::mutate(Original_ID = dplyr::row_number())

# Filter the data frame
G1 <- df_V2 %>%
   dplyr::filter(No_Peaks == 1)

# G3: 2 peaks
G3 <- df_V2 %>%
   dplyr::filter(No_Peaks == 2)

# G4: >2 peaks
G4 <- df_V2 %>%
   dplyr::filter(No_Peaks > 2)

# Plot---------------------------------------------------------

# Extract and plot data for each flood event
plot_list <- list()
color_palette <- viridis(3)
for (i in 1:nrow(Flood_events[[col_name]])) {
   # V2 is the historical column. Use it to get the start/end date.
   start_date <- Flood_events$V2$Begin[i]
   end_date <- Flood_events$V2$End[i]

   # Get the daily flows during this event.
   col_name <- "V2"
   dQ <- dplyr::rename(dailyQ[[col_name]], Date = V1, Discharge = all_of(col_name))
   subset_data_V2 <- dQ %>%
      dplyr::filter(Date >= start_date & Date <= end_date)

   # Create the plot
   p <- ggplot(
      subset_data_V2,
      aes(x = Date, y = Discharge, color = "HIST")
   ) +
      geom_line(linewidth = 1)

   # add next scenario to the same plot
   col_name <- "V3"
   dQ2 <- dplyr::rename(dailyQ[[col_name]], Date = V1, Discharge = all_of(col_name))
   subset_data_V3 <- dQ2 %>%
      dplyr::filter(Date >= start_date & Date <= end_date)

   p <- p +
      geom_line(
         data = subset_data_V3,
         aes(y = Discharge, color = "SSP545-COOL-FAR"), linewidth = 1
      )

   # add next scenario to the same plot
   col_name <- "V4"
   dQ3 <- dplyr::rename(dailyQ[[col_name]], Date = V1, Discharge = all_of(col_name))
   subset_data_V4 <- dQ3 %>%
      dplyr::filter(Date >= start_date & Date <= end_date)

   p <- p +
      geom_line(
         data = subset_data_V4,
         aes(y = Discharge, color = "SSP545-HOT-FAR"), linewidth = 1
      ) +
      scale_color_manual(
         values = c(
            "HIST" = color_palette[1],
            "SSP545-COOL-FAR" = color_palette[2],
            "SSP545-HOT-FAR" = color_palette[3]
         ),
         name = "Scenario"
      ) +
      labs(
         title = paste("Event", i, ": Daily from", start_date, "to", end_date),
         x = "Date",
         y = "Discharge"
      ) +
      theme_minimal() +
      theme(legend.position = "none") # Suppressing the legend

   plot_list[[i]] <- p
}


# Print a set of events based on the indices in G2$Original_ID ------------
# selected_indices <- c(1, 3, 9, 10, 12, 16)
# selected_plots <- plot_list[selected_indices]
selected_plots <- plot_list[G4$Original_ID]
combined_plot <- wrap_plots(selected_plots, ncol = 5) # 2 columns or change as per your preference

if (save_figures_flag) {
   file_name <- file.path(pathname_figs, "Inlet.png")
   ggsave(file_name, combined_plot, width = 24, height = 30)
}


# Example of exporting plots for a single event --------------------------------------------------------------
print(plot_list[[1]])
file_name <- file.path(pathname_figs, paste0("Inlet_flood_", i, ".png"))
ggsave(file_name, plot = p, width = 6, height = 4, dpi = 300)

