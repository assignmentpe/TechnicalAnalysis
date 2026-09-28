# =====================================================================
# BDA400 / Data Science Tools and Techniques
# Assignment 2 - Technical Analysis using R, Preliminary Stage
# Student : Paula Eriya
# File    : 02_functions.R
# Purpose : Steps 5, 6 and 7 of the assignment.
#           - read_portfolio()      : read the stock symbols
#           - load_stock_data()     : import the stock data (quantmod)
#           - calculate_statistics(): moving average, mean, mode,
#                                     median, standard deviation
#           - display_*()           : show data and statistics
#
# This file only DEFINES functions. Nothing runs until you call them.
# =====================================================================


# ---------------------------------------------------------------------
# STEP 5a : read_portfolio()
# ---------------------------------------------------------------------
# Reads portfolio.txt and returns the stock symbols as a simple
# character vector (a list of text values).
#
# Cleaning rules:
#   - trim spaces off both ends of every line
#   - throw away empty lines
#   - throw away '#' comment lines
#   - make everything UPPER CASE so "aapl" and "AAPL" both work
# ---------------------------------------------------------------------
read_portfolio <- function(file = "portfolio.txt") {

  if (!file.exists(file)) {
    stop("Cannot find the file: ", file,
         "\nPut portfolio.txt in the same folder as this script.")
  }

  lines <- readLines(file, warn = FALSE)

  lines <- trimws(lines)                     # remove spaces
  lines <- lines[nchar(lines) > 0]           # remove blank lines
  lines <- lines[!grepl("^#", lines)]        # remove comment lines
  symbols <- toupper(lines)                  # AAPL

  if (length(symbols) == 0) {
    stop("portfolio.txt does not contain any stock symbols.")
  }

  cat("Portfolio read from '", file, "': ", length(symbols),
      " symbols found\n", sep = "")
  cat("  ", paste(symbols, collapse = ", "), "\n\n", sep = "")

  return(symbols)
}


# ---------------------------------------------------------------------
# STEP 5b : load_stock_data()
# ---------------------------------------------------------------------
# Downloads the daily price history of every symbol using quantmod
# and stores each stock as its OWN data frame inside a named list.
#
#   stock_data[["AAPL"]]  = a data frame of AAPL prices
#   stock_data[["MSFT"]]  = a data frame of MSFT prices
#   ...
#
# Arguments:
#   symbols  - character vector of symbols, e.g. c("AAPL","MSFT")
#   from     - first date, e.g. "2023-01-01"
#   to       - last date,  e.g. Sys.Date()
#   price_col- which price column the statistics should use later
# ---------------------------------------------------------------------
load_stock_data <- function(symbols,
                            from    = "2023-01-01",
                            to      = Sys.Date(),
                            price_col = "Adjusted") {

  stock_data <- list()   # empty list, symbols get added one by one

  for (sym in symbols) {

    cat("Downloading data for ", sym, " ... ", sep = "")

    # auto.assign = FALSE returns the data instead of putting it in
    # a variable named after the symbol in the global environment.
    result <- tryCatch(
      quantmod::getSymbols(
        Symbols    = sym,
        from       = from,
        to         = to,
        auto.assign = FALSE,
        warnings   = FALSE,
        src        = "yahoo"
      ),
      error = function(e) NULL
    )

    if (is.null(result) || length(result) == 0) {
      cat("FAILED (check the symbol is correct on Yahoo Finance)\n")
      next
    }

    # quantmod returns an xts object. Convert it to a normal data frame
    # and put the dates back in as the first column.
    df <- as.data.frame(result)

    date_column <- data.frame(Date = as.Date(rownames(df)))
    df <- cbind(date_column, df)
    rownames(df) <- NULL

    # Newer versions of quantmod name the columns with the symbol in
    # front, for example "AAPL.Close" instead of "Close".
    # We remove the "SYMBOL." part so the rest of the code can just use
    # the simple names: Date, Open, High, Low, Close, Adjusted, Volume.
    names(df) <- sub(paste0("^", sym, "\\."), "", names(df))

    # Keep only the columns we actually use
    keep <- intersect(c("Date", "Open", "High", "Low",
                        "Close", "Adjusted", "Volume"),
                      names(df))
    df <- df[, keep, drop = FALSE]      # drop = FALSE keeps it a data frame

    # Make sure the price column the user asked for really exists
    if (!price_col %in% names(df)) {
      price_col <- "Close"
    }

    stock_data[[sym]] <- df

    cat("OK - ", nrow(df), " daily rows from ",
        format(min(df$Date)), " to ", format(max(df$Date)), "\n",
        sep = "")
  }

  cat("\nSuccessfully loaded ", length(stock_data),
      " stock data frame(s).\n\n", sep = "")

  return(stock_data)
}


# ---------------------------------------------------------------------
# STEP 6a : mode_value()  -- our own mode function
# ---------------------------------------------------------------------
# Base R has mean(), median() and sd(), but there is NO mode().
# So we write one ourselves. That is exactly the kind of "utility
# function" the assignment asks for.
#
# The mode is the value that appears most often.
# If there is a tie, the smallest tied value is returned.
# ---------------------------------------------------------------------
mode_value <- function(x) {

  x <- x[!is.na(x)]          # ignore missing values
  if (length(x) == 0) return(NA_real_)

  counts <- table(x)                    # count how often each value appears
  highest <- max(counts)                # the biggest count

  tied_values <- as.numeric(names(counts)[counts == highest])

  return(min(tied_values))             # smallest value if there is a tie
}


# ---------------------------------------------------------------------
# STEP 6b : calculate_statistics()
# ---------------------------------------------------------------------
# Takes ONE stock's data frame and returns ONE row of statistics:
#
#   moving average (20-day), mean, mode, median, standard deviation
#   plus a few extra useful numbers (min, max, observations)
# ---------------------------------------------------------------------
calculate_statistics <- function(stock_df,
                                 price_col    = "Adjusted",
                                 ma_window    = 20) {

  if (!price_col %in% names(stock_df)) {
    stop("Column '", price_col, "' is not in the data frame.")
  }

  prices <- stock_df[[price_col]]
  prices <- prices[!is.na(prices)]

  if (length(prices) == 0) {
    stop("There are no prices to calculate statistics from.")
  }

  # ---- 1. MOVING AVERAGE (20-day simple moving average) -------------
  # TTR::SMA() is from the "Technical Trading Rules" package.
  # The last ma_window values that are not NA are averaged together.
  sma <- TTR::SMA(prices, n = ma_window)
  latest_sma <- utils::tail(sma[!is.na(sma)], 1)

  # ---- 2. MEAN (average price) --------------------------------------
  mean_price <- mean(prices)

  # ---- 3. MODE (most frequent price) - our own function -------------
  mode_price <- mode_value(prices)

  # ---- 4. MEDIAN (middle value) -------------------------------------
  median_price <- stats::median(prices)

  # ---- 5. STANDARD DEVIATION (how spread out the prices are) --------
  std_price <- stats::sd(prices)

  # ---- extra useful information --------------------------------------
  daily_returns <- diff(prices) / utils::head(prices, -1) * 100

  stats_row <- data.frame(
    Symbol       = NA_character_,
    Observations = length(prices),
    Start_Date   = format(min(stock_df$Date)),
    End_Date     = format(max(stock_df$Date)),
    MA_20        = round(as.numeric(latest_sma), 2),
    Mean         = round(mean_price, 2),
    Mode         = round(mode_price, 2),
    Median       = round(median_price, 2),
    Std_Dev      = round(std_price, 2),
    Min          = round(min(prices), 2),
    Max          = round(max(prices), 2),
    Range        = round(max(prices) - min(prices), 2),
    Total_Return_Pct = round((utils::tail(prices, 1) / prices[1] - 1) * 100, 2),
    Avg_Daily_Return_Pct = round(mean(daily_returns, na.rm = TRUE), 3),
    check.names = FALSE
  )

  return(stats_row)
}


# ---------------------------------------------------------------------
# STEP 6c : calculate_all_statistics()
# ---------------------------------------------------------------------
# Runs calculate_statistics() on every stock and collects all the
# results into ONE data frame (one row per stock symbol).
# ---------------------------------------------------------------------
calculate_all_statistics <- function(stock_data,
                                     price_col = "Adjusted",
                                     ma_window = 20) {

  results <- list()

  for (sym in names(stock_data)) {
    cat("Calculating statistics for ", sym, " ...\n", sep = "")
    row <- calculate_statistics(stock_data[[sym]],
                                price_col = price_col,
                                ma_window = ma_window)
    row$Symbol <- sym
    results[[sym]] <- row
  }

  all_stats <- do.call(rbind, results)
  rownames(all_stats) <- NULL

  cat("Statistics calculated for ", nrow(all_stats), " stocks.\n\n",
      sep = "")

  return(all_stats)
}


# ---------------------------------------------------------------------
# STEP 7a : display_stock_data()
# ---------------------------------------------------------------------
# Show the loaded data frame for one stock in several different ways
# (the assignment asks us to try more than one way of displaying).
#
#   1. dim()        - how many rows and columns
#   2. names()      - the column names
#   3. head()/tail()- the first and last few rows
#   4. str()        - the structure of the object
#   5. summary()    - basic statistics for every column
#   6. a small formatted table
# ---------------------------------------------------------------------
display_stock_data <- function(stock_data, symbol, rows = 6) {

  if (!symbol %in% names(stock_data)) {
    stop("'", symbol, "' was not loaded. Loaded symbols are: ",
         paste(names(stock_data), collapse = ", "))
  }

  df <- stock_data[[symbol]]

  cat("\n=====================================================================\n")
  cat("STOCK DATA DISPLAY: ", symbol, "\n", sep = "")
  cat("=====================================================================\n\n")

  cat("1) Size of the data frame (rows x columns)\n")
  print(dim(df))

  cat("\n2) Column names\n")
  print(names(df))

  cat("\n3) First ", rows, " rows (head)\n", sep = "")
  print(head(df, rows))

  cat("\n4) Last ", rows, " rows (tail)\n", sep = "")
  print(tail(df, rows))

  cat("\n5) Structure of the object (str)\n")
  str(df)

  cat("\n6) Summary of every column\n")
  print(summary(df))

  cat("\n7) Formatted view of the most recent 5 days (Close & Volume)\n")
  recent <- utils::tail(df, 5)
  rownames(recent) <- NULL
  print(recent[, c("Date", "Close", "Volume")], row.names = FALSE)

  cat("\n8) One-line summary of the whole history\n")
  cat("   ", symbol, " has ", nrow(df), " trading days, from ",
      format(min(df$Date)), " to ", format(max(df$Date)), ".\n",
      sep = "")

  invisible(df)
}


# ---------------------------------------------------------------------
# STEP 7b : display_all_stock_data()
# ---------------------------------------------------------------------
# Runs display_stock_data() for every stock in the list.
# ---------------------------------------------------------------------
display_all_stock_data <- function(stock_data, rows = 6) {
  for (sym in names(stock_data)) {
    display_stock_data(stock_data, sym, rows = rows)
  }
}


# ---------------------------------------------------------------------
# STEP 7c : display_statistics()
# ---------------------------------------------------------------------
# Prints the statistics table and the overall picture across the
# whole portfolio.
# ---------------------------------------------------------------------
display_statistics <- function(all_stats) {

  cat("\n=====================================================================\n")
  cat("CALCULATED STATISTICS FOR THE WHOLE PORTFOLIO\n")
  cat("=====================================================================\n\n")

  cat("1) Full statistics table (one row per stock)\n")
  print(all_stats, row.names = FALSE)

  cat("\n2) Statistics with column headers side by side (t())\n")
  num_cols <- c("MA_20", "Mean", "Mode", "Median", "Std_Dev")
  # t() turns the columns into rows. as.matrix() makes sure R treats
  # the numbers as numbers (and not as text) so round() works.
  side_by_side <- rbind(
    "Symbol"  = all_stats$Symbol,
    round(t(as.matrix(all_stats[, num_cols])), 2)
  )
  print(side_by_side)

  cat("\n3) Which stock had the highest mean price?\n")
  highest_mean <- all_stats$Symbol[which.max(all_stats$Mean)]
  cat("   ", highest_mean, " (mean = $", max(all_stats$Mean), ")\n", sep = "")

  cat("\n4) Which stock was the most volatile (largest std dev)?\n")
  most_volatile <- all_stats$Symbol[which.max(all_stats$Std_Dev)]
  cat("   ", most_volatile, " (std dev = $", max(all_stats$Std_Dev), ")\n",
      sep = "")

  cat("\n5) Which stock gave the best total return?\n")
  best <- all_stats$Symbol[which.max(all_stats$Total_Return_Pct)]
  cat("   ", best, " (", max(all_stats$Total_Return_Pct), "%)\n", sep = "")

  cat("\n6) Quick ranking of the stocks by mean price (highest first)\n")
  print(all_stats[order(-all_stats$Mean),
                  c("Symbol", "Mean", "Median", "Std_Dev")],
        row.names = FALSE)

  invisible(all_stats)
}


# ---------------------------------------------------------------------
# STEP 7d : plot_stock()  -- chart ONE stock
# ---------------------------------------------------------------------
# Price line + 20-day moving average line, with a 52-week range box.
# ---------------------------------------------------------------------
plot_stock <- function(stock_df, symbol, price_col = "Adjusted",
                       ma_window = 20) {

  # Make a simple plotting copy with two plain columns called
  # "Price" and "MA" so the chart code is easy to read.
  plot_df <- data.frame(
    Date  = stock_df$Date,
    Price = as.numeric(stock_df[[price_col]]),
    MA    = as.numeric(TTR::SMA(stock_df[[price_col]], n = ma_window))
  )
  ribbon <- plot_df[!is.na(plot_df$MA), ]

  y <- ggplot2::ggplot(plot_df, ggplot2::aes(x = Date)) +

    ggplot2::geom_ribbon(data = ribbon,
                         ggplot2::aes(ymin = MA * 0.98, ymax = MA * 1.02),
                         fill = "steelblue", alpha = 0.15) +

    ggplot2::geom_line(ggplot2::aes(y = Price),
                       colour = "grey35", linewidth = 0.6,
                       na.rm = TRUE) +

    ggplot2::geom_line(ggplot2::aes(y = MA),
                       colour = "tomato", linewidth = 0.9,
                       na.rm = TRUE) +

    ggplot2::labs(
      title    = paste(symbol, "-", price_col, "price with",
                       ma_window, "-day moving average"),
      subtitle = paste(format(min(plot_df$Date)), "to",
                       format(max(plot_df$Date)),
                       "|", nrow(plot_df), "trading days"),
      x        = "Date",
      y        = "Price (USD)",
      caption  = "Grey = daily price   |   Red = moving average") +

    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))

  print(y)
  return(y)
}


# ---------------------------------------------------------------------
# STEP 7e : plot_all_stocks() -- chart EVERY stock on one page
# ---------------------------------------------------------------------
plot_all_stocks <- function(stock_data, price_col = "Adjusted") {

  symbols <- names(stock_data)

  # put all the prices into one long data frame so ggplot can facet.
  # Every stock's chosen price column is renamed to "Price".
  combined <- do.call(rbind, lapply(symbols, function(s) {
    d <- stock_data[[s]]
    data.frame(
      Date   = d$Date,
      Price  = as.numeric(d[[price_col]]),
      Symbol = s
    )
  }))

  p <- ggplot2::ggplot(combined, ggplot2::aes(x = Date, y = Price)) +
    ggplot2::geom_line(colour = "steelblue", linewidth = 0.6) +
    ggplot2::facet_wrap(~Symbol, scales = "free_y", ncol = 2) +
    ggplot2::labs(
      title = "Price comparison of every stock in portfolio.txt",
      x     = "Date", y = paste(price_col, "close price (USD)")) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                   strip.text     = ggplot2::element_text(face = "bold"))

  print(p)
  return(p)
}


# ---------------------------------------------------------------------
# STEP 7f : plot_statistics_comparison()
# ---------------------------------------------------------------------
# Bar charts comparing mean / median / std dev across the portfolio.
# ---------------------------------------------------------------------
plot_statistics_comparison <- function(all_stats) {

  long_stats <- data.frame(
    Symbol = rep(all_stats$Symbol, 3),
    Statistic = rep(c("Mean", "Median", "Std_Dev"), each = nrow(all_stats)),
    Value = c(all_stats$Mean, all_stats$Median, all_stats$Std_Dev)
  )

  p <- ggplot2::ggplot(long_stats,
                       ggplot2::aes(x = stats::reorder(Symbol, Value),
                                    y = Value, fill = Statistic)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8),
                      width = 0.7) +
    ggplot2::geom_text(
      ggplot2::aes(label = format(round(Value, 1), nsmall = 1)),
      position = ggplot2::position_dodge(width = 0.8),
      size = 2.6, check_overlap = TRUE) +
    ggplot2::labs(
      title    = "Calculated statistics for every stock in the portfolio",
      subtitle = "Mean, Median and Standard Deviation of the adjusted close price",
      x        = "Stock symbol", y = "Price (USD)", fill = "Statistic") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10),
      axis.text.x = ggplot2::element_text(face = "bold"),
      legend.position = "top")

  print(p)
  return(p)
}


# ---------------------------------------------------------------------
# STEP 7g : plot_returns_distribution()
# ---------------------------------------------------------------------
# Histogram of the daily % return for every stock.
# ---------------------------------------------------------------------
plot_returns_distribution <- function(stock_data, price_col = "Adjusted") {

  symbols <- names(stock_data)

  returns <- do.call(rbind, lapply(symbols, function(s) {
    p <- stock_data[[s]][[price_col]]
    r <- diff(p) / utils::head(p, -1) * 100      # daily % change
    data.frame(Symbol = s, Daily_Return_Pct = as.numeric(r))
  }))
  returns <- returns[!is.na(returns$Daily_Return_Pct), ]

  p <- ggplot2::ggplot(returns,
                       ggplot2::aes(x = Daily_Return_Pct, fill = Symbol)) +
    ggplot2::geom_histogram(bins = 40, alpha = 0.55,
                            colour = "white") +
    ggplot2::facet_wrap(~Symbol, ncol = 2) +
    ggplot2::labs(
      title = "Distribution of daily percentage returns",
      x     = "Daily return (%)", y = "Number of trading days") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.title  = ggplot2::element_text(face = "bold"),
                   legend.position = "none")

  print(p)
  return(p)
}


# ---------------------------------------------------------------------
# STEP 7h : save_charts_to_png()
# ---------------------------------------------------------------------
# Saves every chart as a PNG file in output/figures so the charts can
# be placed inside the written report.
# ---------------------------------------------------------------------
save_charts_to_png <- function(stock_data, all_stats,
                               folder = "output/figures",
                               price_col = "Adjusted") {

  dir.create(folder, showWarnings = FALSE, recursive = TRUE)

  cat("Saving charts into '", folder, "' ...\n", sep = "")

  for (sym in names(stock_data)) {
    file_name <- file.path(folder, paste0("price_chart_", sym, ".png"))
    grDevices::png(file_name, width = 1200, height = 650, res = 130)
    plot_stock(stock_data[[sym]], sym, price_col = price_col)
    grDevices::dev.off()
    cat("   saved: ", file_name, "\n", sep = "")
  }

  file_name <- file.path(folder, "all_stocks_comparison.png")
  grDevices::png(file_name, width = 1300, height = 900, res = 130)
  plot_all_stocks(stock_data, price_col = price_col)
  grDevices::dev.off()
  cat("   saved: ", file_name, "\n")

  file_name <- file.path(folder, "statistics_comparison.png")
  grDevices::png(file_name, width = 1200, height = 700, res = 130)
  plot_statistics_comparison(all_stats)
  grDevices::dev.off()
  cat("   saved: ", file_name, "\n")

  file_name <- file.path(folder, "daily_returns_distribution.png")
  grDevices::png(file_name, width = 1200, height = 850, res = 130)
  plot_returns_distribution(stock_data, price_col = price_col)
  grDevices::dev.off()
  cat("   saved: ", file_name, "\n")

  cat("All charts saved.\n")
}

cat("02_functions.R loaded - all utility functions are ready to use.\n")
