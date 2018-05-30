# load crossings data and save to rds/csv

library(tidyverse)
library(jsonlite)


config <- read_json("config.json")

# read file ---------------------------------------------------------------

df <- read_tsv(
  config$crossings$file,
  col_types = cols(
    .default = col_double(),
    id = col_integer(),
    group = col_integer(),
    groupsize = col_integer(),
    anysurveyed = col_integer(),
    surveyed = col_integer(),
    record_id = col_integer(),
    crosscode = col_character(),
    no_cross = col_integer(),
    bridge_oob = col_integer(),
    moved = col_integer(),
    linkgroup = col_character(),
    database = col_character(),
    bridge = col_integer(),
    roadclass = col_integer()
  )
)


# plot --------------------------------------------------------------------

df %>%
  ggplot(aes(`x-coord`, `y-coord`)) +
  geom_point(size = 0.2, alpha = 0.5) +
  coord_equal()

# export ------------------------------------------------------------------

df %>%
  select(id, x_coord = `x-coord`, y_coord = `y-coord`) %>%
  write_csv("csv/crossings.csv", na = "")

df %>%
  saveRDS("rds/crossings.rds")
