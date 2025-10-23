rm(list = ls())

# Configure paths
dotenv::load_dot_env(file = ".env")
path_project <- path.expand(Sys.getenv("FLOOD_COHERENCE_ROOT", unset = NA))

startup_env <- new.env()
source(file.path(path_project, "reload.R"), local = startup_env)
startup_env$reload(function_path = file.path(path_project, "R"))

# ---- Read the peaks into memory ----
path_data <- path.expand(Sys.getenv("FLOOD_COHERENCE_DATA_DIR", unset = NA))
FloodEvents <- read_flood_events(path_data)

# ---- Compute Flood Coherence ----
FloodCoherenceScore <- compute_flood_coherence(FloodEvents)

# ---- Plot Flood Coherence ----
hist(FloodCoherenceScore$HIST.1980.2020$Outlet$FCS)

