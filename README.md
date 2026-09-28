# ===== Technical Analysis (BDA400 / Data Science Tools and Techniques) =====

Repository for the three-stage **Technical Analysis using R** project.

**Student:** Paula Eriya
**GitHub:** https://github.com/assignmentpe

---

## What is in this repository

| Folder | Assignment | Contents |
|---|---|---|
| `Assignment2/` | BDA400 Assignment 2 (5%) – Technical Analysis using R, Preliminary Stage | R scripts, `portfolio.txt`, output data, charts, screenshots and the report |

Each assignment has its own subdirectory, as required by the brief.

---

## Assignment 2 folder layout

```
Assignment2/
├── portfolio.txt                  <- list of stock symbols (one per line)
├── R/
│   ├── 01_install_packages.R      <- installs the R packages from CRAN
│   ├── 02_functions.R             <- all the utility functions
│   └── 03_run_analysis.R          <- the main script that runs everything
├── output/
│   ├── portfolio_statistics.csv   <- calculated statistics table
│   ├── stock_data_<SYMBOL>.csv    <- the imported stock data
│   ├── figures/                   <- all the charts (PNG)
│   ├── sessionInfo.txt            <- proof of the R version + packages
│   └── ..._log.txt                <- the console output
├── screenshots/                   <- step-by-step screenshots for the report
└── PAULAERIYA_BDA400_A02.docx     <- the written report
```

---

## How to run the project

1. Open **RStudio**.
2. `File > Open Project…` and choose `Assignment2/Assignment2.Rproj`.
   (Opening the *project* sets the working folder to `Assignment2/`, which is
   what makes all the relative paths in the scripts work.)
3. Open `R/01_install_packages.R` and click **Source** once, to install the packages.
4. Open `R/03_run_analysis.R` and click **Source** to run the whole analysis.

The script does everything by itself: it reads `portfolio.txt`, downloads
the data, calculates the statistics, prints the output and saves the charts.

---

## The functions that were written

| Function | What it does |
|---|---|
| `read_portfolio()` | Reads the stock symbols from `portfolio.txt` |
| `load_stock_data()` | Downloads daily price history for every symbol with `quantmod` and returns one data frame per stock |
| `mode_value()` | Our own mode function (base R has no `mode()`) |
| `calculate_statistics()` | Moving average (20-day), mean, mode, median, standard deviation + extras for one stock |
| `calculate_all_statistics()` | Runs the above for every stock and combines into one data frame |
| `display_stock_data()` | Shows a stock's data frame 8 different ways |
| `display_all_stock_data()` | Runs the above for every stock |
| `display_statistics()` | Prints the statistics table and the portfolio summary |
| `plot_stock()` | Price + moving average chart for one stock |
| `plot_all_stocks()` | All stocks compared on one page |
| `plot_statistics_comparison()` | Bar chart comparing mean / median / std dev |
| `plot_returns_distribution()` | Histogram of daily returns |
| `save_charts_to_png()` | Saves every chart as a PNG |

---

## Packages used

`quantmod`, `TTR`, `tseries`, `xts`, `zoo`, `ggplot2`, `dplyr`, `knitr`
