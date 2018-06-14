
# one person missing age (and therefore division); not a top-3 contender though
top3_dt <- ttt_dt[place %in% 1:3 & !is.na(division), ][order(year, gender, division, place)]
place3_dt <- top3_dt[, list(placing_time = max(time_sec)), by = list(year, gender, division)]
winner_dt <- ttt_dt[, .SD[which.min(time_sec)], by = list(year, gender)]

names3_dt <- top3_dt[, list(
  names = 
    paste0(
      paste(
        paste0(name, " (", sprintf('%02d:%02d', floor(time_sec/60), time_sec %% 60), ")"),
        collapse = "\n"),
      ifelse(.N == 2, "\n", ifelse(.N == 1, "\n\n", "")))),
  by = list(year, gender, division)]

merged3_dt <- merge(place3_dt, names3_dt, by = c("year", "gender", "division"))
rm(top3_dt, place3_dt, names3_dt)

#### Plot: Men -------------------------------------------------------------------------------------

p_men <- ggplot(merged3_dt[gender == "Men", ],
                aes(x = division, y = year, label = names)) +
  geom_tile(aes(fill = -1/(placing_time^2)),
            color = "white",
            show.legend = F) +
  scale_fill_gradientn(colors = c("#D62728",
                                  "#BCBD22",
                                  "#2CA02C")) + 
  geom_text(lineheight = 2.4 * 0.4,
            # family = "Roboto Mono",
            size = 2.4, hjust = 0.5, vjust = 0.5) +
  geom_text(data = winner_dt[gender == "Men",
                             list(winner_name_time = paste0(name, " (", sprintf('%02d:%02d', floor(time_sec/60), time_sec %% 60), ")\n\n"),
                                  underline = paste0(paste0(rep("_", nchar(name) + 6), collapse = ""), "\n\n")),
                             by = list(division, year)],
            aes(x = division, y = year, label = underline),
            # family = "Roboto Mono",
            lineheight = 2.4 * 0.4,
            size = 2.4, hjust = 0.5, vjust = 0.5) +
  labs(x = "Age Group", y = "") +
  theme( axis.text.x = element_text(size = 9),
         axis.text.y = element_text(size = 9),
         axis.ticks.y = element_blank(),
         axis.line.y = element_blank(),
         plot.background = element_blank(),
         panel.grid.major = element_blank(),
         panel.grid.minor = element_blank(),
         panel.border = element_blank(),
         panel.background = element_blank()) +
  ggthemes::theme_hc(base_size = 10, base_family = "Roboto Condensed")

#### Add Annotation ####

g_men <- ggplotGrob(p_men)
foot_line1 <- textGrob(
  # expression(paste(bold("Fig 1. "), "Tilden Tough Ten Finish Time Distributions by Year & Gender.")),
  expression(bold("Fig 2a. Tilden Tough Ten: Top 3 Age Group Finishers, Male.")),
  x = unit(1, "npc"), # left just: x = 0, 
  y = unit(1, "npc") - unit(1, "line"),
  just = c("right", "top"),
  gp = gpar(fontsize = 10,  fontfamily = "Roboto Condensed")
)
foot_line2 <- textGrob(
  "Overall winner underlined. Color coding based on 3rd place time. Preliminary 2018 results. Results before 1998 unavailable.",
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
g_men <- gtable_add_rows(g_men, heights = unit(3, "line"), pos = -1)
g_men <- gtable_add_grob(g_men, labs.foot, t = 9, b = 11, l = 4, r = 4)
grid.newpage()
grid.draw(g_men) # don't use plot(); 'plot' adds an undesirable grid background.

#### Plot: Women -----------------------------------------------------------------------------------
p_women <- ggplot(merged3_dt[gender == "Women", ],
                aes(x = division, y = year, label = names)) +
  geom_tile(aes(fill = -1/(placing_time^2)),
            color = "white",
            show.legend = F) +
  scale_fill_gradientn(colors = c("#D62728",
                                  "#BCBD22",
                                  "#2CA02C")) + 
  geom_text(lineheight = 2.4 * 0.4,
            # family = "Roboto Mono",
            size = 2.4, hjust = 0.5, vjust = 0.5) +
  geom_text(data = winner_dt[gender == "Women",
                             list(winner_name_time = paste0(name, " (", sprintf('%02d:%02d', floor(time_sec/60), time_sec %% 60), ")\n\n"),
                                  underline = paste0(paste0(rep("_", nchar(name) + 6), collapse = ""), "\n\n")),
                             by = list(division, year)],
            aes(x = division, y = year, label = underline),
            # family = "Roboto Mono",
            lineheight = 2.4 * 0.4,
            size = 2.4, hjust = 0.5, vjust = 0.5) +
  labs(x = "Age Group", y = "") +
  theme( axis.text.x = element_text(size = 9),
         axis.text.y = element_text(size = 9),
         axis.ticks.y = element_blank(),
         axis.line.y = element_blank(),
         plot.background = element_blank(),
         panel.grid.major = element_blank(),
         panel.grid.minor = element_blank(),
         panel.border = element_blank(),
         panel.background = element_blank()) +
  ggthemes::theme_hc(base_size = 10, base_family = "Roboto Condensed")

#### Add Annotation ####

g_women <- ggplotGrob(p_women)
foot_line1 <- textGrob(
  # expression(paste(bold("Fig 1. "), "Tilden Tough Ten Finish Time Distributions by Year & Gender.")),
  expression(bold("Fig 2b. Tilden Tough Ten: Top 3 Age Group Finishers, Female.")),
  x = unit(1, "npc"), # left just: x = 0, 
  y = unit(1, "npc") - unit(1, "line"),
  just = c("right", "top"),
  gp = gpar(fontsize = 10,  fontfamily = "Roboto Condensed")
)
foot_line2 <- textGrob(
  "Overall winner underlined. Color coding based on 3rd place time. Preliminary 2018 results. Results before 1998 unavailable.",
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
g_women <- gtable_add_rows(g_women, heights = unit(3, "line"), pos = -1)
g_women <- gtable_add_grob(g_women, labs.foot, t = 9, b = 11, l = 4, r = 4)
grid.newpage()
grid.draw(g_women) # don't use plot(); 'plot' adds an undesirable grid background.

#### Clean up ####
rm(merged3_dt, winner_dt, place3_dt)
rm(foot_line1, foot_line2, foot_line3, labs.foot)
rm(p, p_men, p_women, g_men, g_women)


# References
# 1. https://yutannihilation.github.io/allYourFigureAreBelongToUs/ggthemes/tableau_color_pal/
#    show_col(ggthemes::tableau_color_pal("tableau20")(20))
