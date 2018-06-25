library(data.table)
library(lubridate)

#### Data ####

wm18_hc_dt <- fread("data/20180624/woodmonster-2018-handicap.tsv")
setnames(wm18_hc_dt, c("place_oa", "full_name", "city", "bib", "age",
                       "gender", "time_actual", "handicap", "time_net"))

#### Helper functions ####

fixSubHour <- function(vec) {
  return(ifelse(nchar(vec) == 7, paste0("0:", vec), vec))
}

removeRight <- function(vec, nchar) {
  return(substr(vec, 1, nchar(vec) - nchar))
}

mapToHandicapGroup <- function(x) {
  if (x == 0) return("A")
  else if (x == 5) return("B")
  else if (x == 10) return("C")
  else if (x == 15) return("D")
  else if (x == 20) return("E")
  else if (x == 24) return("F")
  else if (x == 28) return("G")
  else if (x == 32) return("H")
  else if (x == 34) return("I")
  else return("J")
}

countPassed <- function(df, h, t) {
  return(nrow(df[handicap < h][time_net_s > t]))
}
countPassedBy <- function(df, h, t) {
  return(nrow(df[handicap > h][time_net_s < t]))
}

#### Determine age place ####

wm18_hc_dt[, `:=`(
  handicap = minute(ms(removeRight(wm18_hc_dt$handicap, 2))),
  time_actual_s = as.numeric(hms(fixSubHour(time_actual))),
  time_net_s = as.numeric(hms(fixSubHour(time_net))))]
wm18_hc_dt[, handicap_grp := sapply(handicap, mapToHandicapGroup)]
wm18_hc_dt[, place_net := frank(time_actual_s)]
wm18_hc_dt[, place_grp := frank(time_actual_s), by = handicap]
wm18_hc_dt[, `:=`(
  passed = countPassed(wm18_hc_dt, handicap, time_net_s),
  passed_by = countPassedBy(wm18_hc_dt, handicap, time_net_s)),
  by = 1:nrow(wm18_hc_dt)]

#### View & Write Out ####
wm18_out_dt <- wm18_hc_dt[, list(
  bib, full_name, city, gender, age,
  handicap_grp, handicap_min = handicap,
  time_actual, time_net, place_oa, place_net, place_grp,
  passed, passed_by)]

write.csv(wm18_out_dt, "out/woodmonster_2018.csv", row.names = F)



