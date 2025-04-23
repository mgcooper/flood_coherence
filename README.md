# Flood Coherence

<!-- TODO: Brief project description -->

## 📦 Project Setup

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

### 🔄 Updating Dependencies

If you add or update packages during development, remember to run:

```r
renv::snapshot()
```

This updates `renv.lock` so others get the correct versions on `renv::restore()`.

## 📁 Project Structure

```
.
├── data/             # Raw or processed datasets (gitignored by default)
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

```bash
git checkout -b dev
# ...make changes...
git commit -m "message"
git push -u origin dev
```
