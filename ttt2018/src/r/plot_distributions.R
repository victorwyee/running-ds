library(gtable)
library(grid)
library(hrbrthemes)

#### Aggregate to time groups ####
nsub_dt <- ttt_dt[, list(
  n_sub60 = paste0(sum(time_sec < 60 * 60), " "),
  n_sub70 = paste0(sum(60 * 60 <= time_sec & time_sec < 70 * 60), " "),
  n_sub80 = paste0(sum(70 * 60 <= time_sec & time_sec < 80 * 60), " "),
  n_sub80_total = paste0(sum(time_sec < 80 * 60), " "),
  n_over80 = paste0(sum(80 * 60 <= time_sec), " "),
  p_sub60 = formatPercent(sum(time_sec < 60 * 60) / .N, digits = 1),
  p_sub70 = formatPercent(sum(60 * 60 <= time_sec & time_sec < 70 * 60) / .N, digits = 1),
  p_sub80 = formatPercent(sum(70 * 60 <= time_sec & time_sec < 80 * 60) / .N, digits = 1),
  p_over80 = formatPercent(sum(80 * 60 <= time_sec) / .N, digits = 1)
),
by = list(year, gender)]

nsub_numeric_dt <- ttt_dt[, list(
  p_sub60 = sum(time_sec < 60 * 60) / .N,
  p_sub70 = sum(60 * 60 <= time_sec & time_sec < 70 * 60) / .N,
  p_sub80 = sum(70 * 60 <= time_sec & time_sec < 80 * 60) / .N,
  p_over80 = sum(80 * 60 <= time_sec) / .N
),
by = list(year, gender)]

#### Data exploration ####

rbind(
  ttt_dt[, list(sub60 = median(sum(time_sec < 60 * 60) / .N),
                sub70 = median(sum(60 * 60 <= time_sec & time_sec < 70 * 60) / .N),
                sub80 = median(sum(70 * 60 <= time_sec & time_sec < 80 * 60) / .N),
                plus80 = median(sum(80 * 60 <= time_sec) / .N)),
         by = list(gender)],
  ttt_dt[, list(gender = "All",
                sub60 = median(sum(time_sec < 60 * 60) / .N),
                sub70 = median(sum(60 * 60 <= time_sec & time_sec < 70 * 60) / .N),
                sub80 = median(sum(70 * 60 <= time_sec & time_sec < 80 * 60) / .N),
                plus80 = median(sum(80 * 60 <= time_sec) / .N))]
)
rbind(
  nsub_numeric_dt[, list(sub60 = mean(p_sub60),
                         sub70 = mean(p_sub70),
                         sub80 = mean(p_sub80),
                         sub80_cum = mean(1 - p_over80)),
                  by = gender],
  nsub_numeric_dt[, list(gender = "All",
                         sub60 = mean(p_sub60),
                         sub70 = mean(p_sub70),
                         sub80 = mean(p_sub80),
                         sub80_cum = mean(1 - p_over80))]
)
ttt_dt[place == 1, ][order(name)][, list(.N), by = name][order(-N)]
ttt_dt[finish == 1, ][order(name)][, list(.N), by = name][order(-N)]

#### Reshape for plotting ####

nsub_long_dt <- data.table::melt(
  nsub_dt, measure.vars = grep("^n_|^p_", names(nsub_dt), value = TRUE))
nsub_long_dt[, `:=`(
  xpos = ifelse(like(variable, "sub60"), 59*60,
                ifelse(like(variable, "sub70"), 69*60,
                       ifelse(like(variable, "sub80"), 79*60, 140*60))),
  ypos = ifelse(like(variable, "n_"), 9.5,
                ifelse(like(variable, "p_"), 6.9, 0)))]

#### Order by p_over80 ####

year_ordered <- nsub_long_dt[gender == "Men" & variable == "p_over80", year, by = frank(value)][order(frank)][["year"]]
ttt_dt[, year_ordered := factor(year, levels = year_ordered)]
nsub_long_dt[, year_ordered := factor(year, levels = year_ordered)]

#### Plots ####

p <- ggplot(data = ttt_dt, aes(x = time_sec, fill = gender))
p <- p + geom_histogram(
  aes(y = ..count.., group = year),
  breaks = seq(50, 140, 2) * 60,
  color = "#FFFFFF",
  show.legend = FALSE,
  boundary = 0
) # shift bins to left of x-axis tick
p <- p + geom_density(
  aes(N = 180, y = ..density.. * (N * 60), group = year),
  alpha = 0.5,
  show.legend = FALSE)
p <- p +
  geom_vline(xintercept = 60 * 60, linetype = 2) +
  geom_vline(xintercept = 70 * 60, linetype = 2) +
  geom_vline(xintercept = 80 * 60, linetype = 1)
p <- p +
  scale_x_continuous(
    limits = c(50*60, 140*60),
    breaks = seq(50, 140, 5) * 60,
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
    breaks = c(0, 10),
    labels = c("", "10"),
    position = "right"
  )
p <- p + facet_grid(year_ordered ~ gender + ., switch = "both") +
  theme(strip.background = element_blank())
p <- p + ggthemes::scale_fill_ptol() # c("#4477AA", "#CC6677")
p <- p + geom_text(data = nsub_long_dt[variable != "n_sub80_total", ],
                   aes(x = xpos, y = ypos, label = value),
                   size = 2.5,
                   hjust = 1, vjust = 1)

p1 <- p + labs(
  x = "Finish Time (minutes)",
  y = "") +
  # caption = expression(atop(" ", " ", " ", " "))) +
  # caption = expression(paste(bold("Fig 1. Tilden Tough Ten Finish Time Distributions by Year & Gender. \n"),
  #                            "49 (1%) finish times above 140 minutes are omitted. \n@victorwyee | Source: Lake Merritt Joggers & Striders"))) +
  # caption = expression(atop(" ", " "))) +
  theme( axis.text.x = element_text(size = 9),
        axis.text.y = element_text(size = 9),
        axis.ticks.y = element_blank(),
        axis.line.y = element_blank()) +
  ggthemes::theme_hc(base_size = 10, base_family = "Roboto Condensed")
  # hrbrthemes::theme_ipsum_rc(base_family = "Roboto Condensed", base_size = 10)

#### Add Annotation ####

g1 <- ggplotGrob(p1)

foot_line1 <- textGrob(
  # expression(paste(bold("Fig 1. "), "Tilden Tough Ten Finish Time Distributions by Year & Gender.")),
  expression(bold("Fig 1. Tilden Tough Ten: Finish Times by Year & Gender.")),
  x = unit(1, "npc"), # left just: x = 0, 
  y = unit(1, "npc") - unit(1, "line"),
  just = c("right", "top"),
  gp = gpar(fontsize = 10,  fontfamily = "Roboto Condensed")
)
foot_line2 <- textGrob(
  "49 (~1%) finish times above 140 minutes are omitted. Preliminary 2018 results. Results before 1998 unavailable.",
  x = unit(1, "npc"), # left just: x = 0, 
  y = unit(1, "npc") - unit(2, "line"),
  just = c("right", "top"),
  gp = gpar(fontsize = 10, col = "#383838", fontfamily = "Roboto Condensed")
)
foot_line3 <- textGrob(
  "@victorwyee | Source: Lake Merritt Joggers & Striders",
  x = unit(1, "npc"), # left just: x = 0, 
  y = unit(1, "npc") - unit(3, "line"),
  just = c("right", "top"),
  gp = gpar(fontsize = 10, col = "#383838", fontfamily = "Roboto Condensed")
)
labs.foot = gTree("LabsFoot", children = gList(foot_line1, foot_line2, foot_line3))
g1 <- gtable_add_rows(g1, heights =  unit(3, "line"), pos = -1)
g1 <- gtable_add_grob(g1, labs.foot, t = 50, b = 52, l = 5, r = 7)

grid.newpage()
grid.draw(g1)

#### Clean up ####
rm(foot_line1, foot_line2, foot_line3, g1, labs.foot, nsub_dt, nsub_long_dt, nsub_numeric_dt, p, p1, year_ordered)
