library(data.table)
library(ggplot2)
library(lubridate)
library(ggrepel)

source("../common/helper.R")

#### Previous years ####

datadir   <- "data/20180521/tilden_tough_ten/"
datapaths <- paste0(datadir, grep("^ttt[0-9]{4}.tsv", dir(datadir), value = T))
for (file in datapaths) {
  filename <- basename(file)
  year <- substring(filename, 4, 7)
  dtname <- paste0("ttt", year, "_dt")
  assign(dtname, fread(file))
  get(dtname)[, year := year]
}

ttt_dt <- rbindlist(sapply(ls(pattern = "^ttt"), get, simplify = F), fill = T)
rm(list = ls(pattern = "^ttt[0-9]{4}_dt$"))
ttt_dt[, `:=`(time_sec = as.numeric(ms(time)),
              division = ordered(division, levels = c("-20", "20-29", "30-39", "40-49", "50-59", "60-69", "70+")),
              gender = ordered(gender, levels = c("M", "F"), labels = c("Men", "Women")))]

#### 2018 Preliminary Results ####
ttt2018_dt <- fread("data/20180521/tilden_tough_ten/tabula-TildenToughTen2018PDF.csv")
ttt2018_dt <- ttt2018_dt[, list(
  finish = Position,
  name = Name,
  age = Age,
  home = City,
  time = Time,
  gender = ordered(Gender, levels = c("M", "F"), labels = c("Men", "Women")),
  division = ordered(ifelse(Age < 20, "-20",
                           ifelse(20 <= Age & Age <= 29, "20-29",
                                  ifelse(30 <= Age & Age <= 39, "30-39",
                                         ifelse(40 <= Age & Age <= 49, "40-49",
                                                ifelse(50 <= Age & Age <= 59, "50-59",
                                                       ifelse(60 <= Age & Age <= 69, "60-69", "70+")))))),
                    levels = c("-20", "20-29", "30-39", "40-49", "50-59", "60-69", "70+")),
  place = 0L,
  year = 2018,
  time_sec = as.numeric(hms(Time)))]
ttt2018_dt[, place := frank(time_sec, ties.method = "min"), by = list(year, gender, division)]

#### Combine & Clean ####
ttt_dt <- rbind(ttt_dt, ttt2018_dt)
ttt_dt[, name := stringi::stri_trim_both(gsub('\\*', '', name))]

#### Clean up ####
rm(datadir, datapaths, dtname, file, filename, year, ttt2018_dt)


