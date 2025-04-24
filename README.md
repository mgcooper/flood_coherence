# Flood Coherence

`flood_coherence` is an R-based project to analyze the spatial coherence of flood events and their synchronization in time. Currently, this project complements the analysis reported in the paper referenced below, specifically the flood event identification and flood coherence score calculations:

Cooper et al. (2025): "Enhanced flood synchrony and downstream severity in the Delaware River under rising temperatures" Communications Earth & Environment 6(296) doi.org/10.1038/s43247-025-02243-y

## Getting Started

Thanks for your interest. To get started, here's what we recommend:

1. Follow the directions in [Project Setup](#project-setup).
2. Copy `.env.example` to `.env` and define the paths to the project root folder, and the folder where project data and figures are saved.
3. Ensure the DHSVM-modeled hydrograph for the Delaware River at the estuary inlet (`daily_mean_flow.csv`) is saved in the `./data/` directory (or as defined in `.env`). In addition, five .xlsx files representing three-hourly modeled hydrographs at each upstream subbasin (one file for each scenario: historical and four RCP scenarios) are saved in the `./data` directory. These files ship with this repo, and represent DHSVM modeled hydrographs for the Delaware River Basin and eight constituent upstream HUC-8 subbasins. The `Flood_events_*.csv` files are flood peaks identified with the `FloodR` package, and can be recreated by running the analysis described below.

### Analysis

1. Run `scripts/ExtractFloods_Inlet.R`. This script runs the FloodR flood identification algorithm to identify flood peaks at the Delaware Estuary inlet, using the DHSVM-modeled hydrograph of daily flows in the `data/daily_mean_flow.csv` file. Optionally, users can save figures showing all identified flood events, printed to .png files. See the example at the end of the script to save (or view) the figures.
2. Run `scripts/ExtractFloods_Subbasins.R`. This script reads the modeled flood peaks and groups them by subbasin, creates a folder in the `data/` dir for each subbasin, and saves a new file of flood peaks for each subbasin in those folders. Optionally, figures are created to visualize the identified flood peaks. See the options in the script.
3. Run `scripts/compute_FCS.R` to calculate the "flood coherence score" (number of synchronized subbasin floods) for each basin-scale flood at the estuary inlet. The script should produce a histogram showing the frequency distribution of FCS for floods identified at the inlet.

Note: while `scripts/compute_FCS.R` demonstrates how to compute the FCS using flood events identified by the `FloodR` package, it is not designed to fully reproduce the analysis reported in Cooper et al. 2025. To reproduce that analysis, see [this Zenodo repository](https://zenodo.org/records/15021578).

## Project Setup

This project uses [renv](https://rstudio.github.io/renv/) for dependency management and assumes you're working within RStudio.

### ✅ First-time Setup

Clone the repository:

```bash
git clone https://github.com/mgcooper/flood_coherence.git
cd flood_coherence
```

Then, in R or RStudio:

```r
install.packages("renv")      # if not already installed
renv::restore()               # installs all required packages from renv.lock
source("startup.R")           # optional: loads packages and sources scripts
```

This will recreate the exact package environment used by the project, including CRAN and GitHub dependencies.

Note: This project requires the `FloodR` package. If you receive warning messages on startup, you may need to run this at your R(Studio) command line:

```r
devtools::install_github(repo = "PhilippBuehler/FloodR")
```

`FloodR` requires `Rcpp`. If you receive compiler warnings during install, ensure `~/.R.Makevars` exists and correctly defines `CXXFLAGS`. On a Mac, type `xcrun --show-sdk-path` into your terminal and copy the path returned into your Makevars file. For example, if `xcrun --show-sdk-path` returns `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`, then your `~/.R/Makevars` file should contain the line:

```sh
CXXFLAGS = -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
```

### 🔄 Updating Dependencies

If you add or update packages during development, remember to run:

```r
renv::snapshot()
```

This updates `renv.lock` so others get the correct versions on `renv::restore()`.

## 📁 Project Structure

```
.
├── data/             # Raw or processed datasets
├── R/                # R scripts used in the project
├── r.Rproj           # RStudio project file
├── reload.R          # Convenience function to source all project functions
├── .Rprofile         # Sources `startup.R` automatically on project load
├── renv/             # renv metadata (do not edit manually)
├── renv.lock         # Exact package versions and sources
├── scripts           # Folder containing scripts to run analysis
└── startup.R         # Loads packages and sources scripts
```

## 🧪 Development

Work in a separate branch (`dev`, `feature/*`, etc.) and open pull requests against `main`:

```sh
git checkout -b dev
# ...make changes...
git commit -m "message"
git push -u origin dev
```
