# startup.R

# Only install FloodR if not already installed
if (!requireNamespace("FloodR", quietly = TRUE)) {
   if (requireNamespace("renv", quietly = TRUE)) {
      renv::install("PhilippBuehler/FloodR")
   } else {
      install.packages("renv")
      renv::install("PhilippBuehler/FloodR")
   }
}

library("FloodR")
library("extRemes")
library(rlang)
library(dplyr)
library(purrr)
library(lobstr)
library(ggplot2)
library(lubridate)
library(plotly)
library(RColorBrewer)
library(viridis)
library(patchwork)
library(readxl)
library(data.table)
library(styler)

# Source all .R files in the R/ directory
source("reload.R")
reload()
