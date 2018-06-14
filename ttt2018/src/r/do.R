

ttt2018_dt[place == 3, ][order(division)]

ttt2018_dt[, time_diff_prev_oa := c(NA, diff(time_sec))]
ttt2018_dt[, time_diff_prev_gender := c(NA, diff(time_sec)), by = Gender]

nsub2018_dt <- ttt2018_dt[, list(
  n_sub60 = paste0(sum(time_sec < 60 * 60), " "),
  n_sub70 = paste0(sum(60 * 60 <= time_sec & time_sec < 70 * 60), " "),
  n_sub80 = paste0(sum(70 * 60 <= time_sec & time_sec < 80 * 60), " "),
  n_over80 = paste0(sum(80 * 60 <= time_sec), " "),
  p_sub60 = formatPercent(sum(time_sec < 60 * 60) / .N, digits = 1),
  p_sub70 = formatPercent(sum(60 * 60 <= time_sec & time_sec < 70 * 60) / .N, digits = 1),
  p_sub80 = formatPercent(sum(70 * 60 <= time_sec & time_sec < 80 * 60) / .N, digits = 1),
  p_over80 = formatPercent(sum(80 * 60 <= time_sec) / .N, digits = 1)
),
by = Gender]
nsub2018_long_dt <- data.table::melt(nsub2018_dt,
                                     measure.vars = grep("^n_|^p_", names(nsub2018_dt), value = TRUE))
nsub2018_long_dt[, `:=`(
  xpos = ifelse(like(variable, "sub60"), 59*60,
         ifelse(like(variable, "sub70"), 69*60,
         ifelse(like(variable, "sub80"), 79*60, 89*60))),
  ypos = ifelse(like(variable, "n_"), 7.6,
         ifelse(like(variable, "p_"), 7.0, 0)))]

#### Plots ####

p <- ggplot(data = ttt2018_dt, aes(x = time_sec, fill = Gender))
p <- p + geom_histogram(
  aes(y = ..count..),
  breaks = seq(50, 160, 2) * 60,
  color = "#FFFFFF",
  show.legend = FALSE,
  boundary = 0
) # shift bins to left of x-axis tick
p <- p + geom_density(
  aes(y = ..density.. * (184 * 60)),
  alpha = 0.5,
  show.legend = FALSE)
p <- p +
  geom_vline(xintercept = 60 * 60, linetype = 2) +
  geom_vline(xintercept = 70 * 60, linetype = 2) +
  geom_vline(xintercept = 80 * 60, linetype = 1)
p <- p +
  scale_x_continuous(
    limits = c(50*60, 200*60),
    breaks = c(seq(50, 100, 2) * 60, seq(105, 200, 5) * 60),
    labels = function(labels) {
      fixedLabels <- c()
      for (l in 1:length(labels)) {
        fixedLabels <- c(fixedLabels, paste0(ifelse(l %% 2 == 0, '', '\n'), labels[l] / 60))
      }
      return(fixedLabels)
    }
  ) +
  scale_y_continuous(
    limits = c(0, 10),
    breaks = seq(0, 10, 1),
    labels = seq(0, 10, 1)
  )
p <- p + facet_grid(Gender ~ ., switch = "both") + theme(strip.background = element_blank())
p <- p + ggthemes::scale_fill_ptol() # c("#4477AA", "#CC6677")
p <- p + geom_text(data = nsub2018_long_dt,
                   aes(x = xpos, y = ypos, label = value),
                   hjust = 1, vjust = 1)
p + ggthemes::theme_hc()

#### Functions ####

formatPercent <- function(x, digits = 2, format = "f", ...) {
  paste0(formatC(100 * x, format = format, digits = digits, ...), "%")
}
