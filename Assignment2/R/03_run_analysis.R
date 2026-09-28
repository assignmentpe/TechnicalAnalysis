# =====================================================================
# BDA400 / Data Science Tools and Techniques
# Assignment 2 - Technical Analysis using R, Preliminary Stage
# Student : Paula Eriya
# File    : 03_run_analysis.R
# Purpose : This is the MAIN script. It puts the whole project
#           together:
#             step 4  read portfolio.txt
#             step 5  import the stock data with quantmod
#             step 6  calculate the statistics
#             step 7  display the data, statistics and charts
#
# How to run:  open this file in RStudio and click "Source" (top right).
#              Everything below happens automatically.
# =====================================================================

cat("\n\n#####################################################################\n")
cat("#   BDA400 Assignment 2 - Technical Analysis using R\n")
cat("#   Student: Paula Eriya\n")
cat("#   Script  : 03_run_analysis.R\n")
cat("#####################################################################\n\n")

# ---------------------------------------------------------------------
# 0. Load the packages and our own functions
# ---------------------------------------------------------------------
library(quantmod)
library(TTR)
library(ggplot2)

# The working folder is already the Assignment2 folder, because the
# project is opened from Assignment2.Rproj. No setwd() needed.
source("R/02_functions.R")     # bring in all the utility functions

# Make sure the output folders exist
dir.create("output",           showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures",   showWarnings = FALSE, recursive = TRUE)
dir.create("screenshots",      showWarnings = FALSE, recursive = TRUE)

# Settings for this run -----------------------------------------------
price_column <- "Adjusted"     # the price we do the statistics on
start_date   <- "2023-01-01"   # first day of data we want
end_date     <- Sys.Date()     # today

cat("Settings\n")
cat("  Price column : ", price_column, "\n", sep = "")
cat("  Date range   : ", start_date, "  to  ", end_date, "\n", sep = "")
cat("  Moving average window : 20 trading days\n\n", sep = "")


# ---------------------------------------------------------------------
# 1. STEP 4 - read the list of stock symbols from portfolio.txt
# ---------------------------------------------------------------------
cat("\n#####################################################################\n")
cat("# STEP 4 : PROJECT CONFIGURATION - READING portfolio.txt\n")
cat("#####################################################################\n\n")

symbols <- read_portfolio(file = "portfolio.txt")


# ---------------------------------------------------------------------
# 2. STEP 5 - import the stock data using the quantmod package
# ---------------------------------------------------------------------
cat("#####################################################################\n")
cat("# STEP 5 : IMPORTING STOCK DATA WITH quantmod\n")
cat("#####################################################################\n\n")

stock_data <- load_stock_data(symbols,
                              from      = start_date,
                              to        = end_date,
                              price_col = price_column)

# if the internet failed for some symbols we still want to continue
if (length(stock_data) == 0) {
  stop("No stock data could be downloaded. Check your internet connection.")
}


# ---------------------------------------------------------------------
# 3. STEP 7a - display the loaded data frames in several ways
# ---------------------------------------------------------------------
cat("\n\n#####################################################################\n")
cat("# STEP 7 : DISPLAYING THE IMPORTED DATA\n")
cat("#####################################################################\n")

display_all_stock_data(stock_data, rows = 6)


# ---------------------------------------------------------------------
# 4. STEP 6 - calculate moving average, mean, mode, median, std dev
# ---------------------------------------------------------------------
cat("\n\n#####################################################################\n")
cat("# STEP 6 : COMPUTING THE STATISTICS\n")
cat("#####################################################################\n\n")

all_stats <- calculate_all_statistics(stock_data,
                                      price_col = price_column,
                                      ma_window = 20)


# ---------------------------------------------------------------------
# 5. STEP 7b - display the calculated statistics
# ---------------------------------------------------------------------
display_statistics(all_stats)


# ---------------------------------------------------------------------
# 6. STEP 7c - draw and save the charts
# ---------------------------------------------------------------------
cat("\n\n#####################################################################\n")
cat("# STEP 7 : VISUALISATIONS\n")
cat("#####################################################################\n\n")

save_charts_to_png(stock_data, all_stats,
                   folder    = "output/figures",
                   price_col = price_column)


# ---------------------------------------------------------------------
# 7. Save the results as .csv files (easy to open in Excel)
# ---------------------------------------------------------------------
cat("\nSaving results as CSV files ...\n")

write.csv(all_stats, "output/portfolio_statistics.csv", row.names = FALSE)

for (sym in names(stock_data)) {
  write.csv(stock_data[[sym]],
            file.path("output", paste0("stock_data_", sym, ".csv")),
            row.names = FALSE)
}

cat("   saved: output/portfolio_statistics.csv\n")
cat("   saved: output/stock_data_<SYMBOL>.csv (one per stock)\n")


# ---------------------------------------------------------------------
# 8. Final message
# ---------------------------------------------------------------------
cat("\n\n#####################################################################\n")
cat("# ANALYSIS COMPLETE\n")
cat("#####################################################################\n")
cat("Files produced:\n")
cat("   output/portfolio_statistics.csv   - the statistics table\n")
cat("   output/stock_data_*.csv           - the imported stock data\n")
cat("   output/figures/*.png              - all the charts\n")
cat("#####################################################################\n")
