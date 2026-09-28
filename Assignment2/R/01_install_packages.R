# =====================================================================
# BDA400 / Data Science Tools and Techniques
# Assignment 2 - Technical Analysis using R, Preliminary Stage
# Student : Paula Eriya
# File    : 01_install_packages.R
# Purpose : Step 3 of the assignment - download and install the R
#           packages needed for technical analysis.
#
# How to run this file:
#   Option A (RStudio):  Open the file, then click the green "Run" arrow.
#   Option B (Console) :  source("R/01_install_packages.R")
# =====================================================================

# ---------------------------------------------------------------------
# 1. List of packages we need for this project
# ---------------------------------------------------------------------
# quantmod  -> downloads stock data from Yahoo Finance
# TTR       -> Technical Trading Rules (moving averages, RSI, etc.)
# tseries   -> extra statistics / time-series helpers
# xts       -> stores the time-series data (dependency of quantmod)
# zoo       -> time-series backbone (dependency of xts)
# ggplot2   -> draws the charts
# dplyr     -> makes working with data frames easy
# knitr     -> helps build the R Markdown report

required_packages <- c(
  "quantmod",
  "TTR",
  "tseries",
  "xts",
  "zoo",
  "ggplot2",
  "dplyr",
  "knitr"
)

cat("=====================================================================\n")
cat("STEP 3: INSTALLING R PACKAGES\n")
cat("=====================================================================\n\n")

cat("Packages to install:\n")
print(required_packages)

# ---------------------------------------------------------------------
# 2. Work out which packages are still missing
#    installed.packages() lists everything already on the computer
# ---------------------------------------------------------------------
installed_packages <- rownames(installed.packages())

packages_to_install <- required_packages[
  !(required_packages %in% installed_packages)
]

if (length(packages_to_install) == 0) {
  cat("\nAll required packages are already installed. Nothing to do.\n")
} else {
  cat("\nPackages that still need installing:\n")
  print(packages_to_install)

  # -------------------------------------------------------------------
  # 3. Download and install them from CRAN
  #    install.packages() is the official CRAN installer function.
  #    "repos" tells R where to download the files from.
  # -------------------------------------------------------------------
  install.packages(
    packages_to_install,
    repos = "https://cloud.r-project.org",   # the public CRAN mirror
    dependencies = TRUE                      # also install what they need
  )
}

# ---------------------------------------------------------------------
# 4. Load the packages into the current R session
#    (installing a package puts it on the computer, library() opens it)
# ---------------------------------------------------------------------
cat("\nLoading packages into the R session ...\n")

for (pkg in required_packages) {
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE, quietly = TRUE)
  )
}

# ---------------------------------------------------------------------
# 5. Check that every package loaded correctly
# ---------------------------------------------------------------------
cat("\nPackage check:\n")
for (pkg in required_packages) {
  is_ready <- requireNamespace(pkg, quietly = TRUE)
  cat(sprintf("  %-10s -> %s\n", pkg, ifelse(is_ready, "OK", "FAILED")))
}

# ---------------------------------------------------------------------
# 6. Save the session information for the report (proves R is set up)
# ---------------------------------------------------------------------
# The scripts are run from inside the Assignment2 folder, so the
# results folder is simply called "output".
dir.create("output", showWarnings = FALSE, recursive = TRUE)

capture.output(sessionInfo(), file = "output/sessionInfo.txt")

cat("\n=====================================================================\n")
cat("STEP 3 COMPLETE\n")
cat("Session details saved to: output/sessionInfo.txt\n")
cat("=====================================================================\n")
