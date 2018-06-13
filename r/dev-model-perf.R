# evaluate model performance as function of number of crossings

library(tidyverse)
library(jsonlite)

source("load-functions.R")

config <- read_json("config.json")

crossings <- read_csv(
  "csv/crossings.csv",
  col_types = cols(
    id = col_integer(),
    x_coord = col_double(),
    y_coord = col_double()
  )
) %>%
  select(id, x = x_coord, y = y_coord)

run_model <- function(n) {
  graph.linkages(sample_n(crossings, size = n), source = config$tiles$dir)
}

df <- data_frame(
  n = c(1, 5, 10, 20, 50, 100)
) %>%
  mutate(
    results = map(n, run_model),
    elapsed = map_dbl(results, "elapsed")
  )

df %>%
  ggplot(aes(n, elapsed)) +
  geom_point() +
  geom_line()

df %>%
  ggplot(aes(n, elapsed/n)) +
  geom_point() +
  geom_line()
