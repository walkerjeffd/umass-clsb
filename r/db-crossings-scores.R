# compute scores for each individual crossing

library(tidyverse)
library(jsonlite)

source("load-functions.R")

config <- fromJSON("config.json")

con <- src_postgres(
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

# all crossings
df_all <- tbl(con, "crossings") %>%
  select(id, x = x_coord, y = y_coord) %>%
  collect()

# randomly select 10%
df_subset <- sample_frac(df_all, size = 0.0001)

nrow(df_subset) / nrow(df_all)

run_model <- function(crossing) {
  graph.linkages(crossing, source = config$tiles$dir)
}

df_results <- df_subset %>%
  head(2) %>%
  mutate(
    results = map2(x, y, ~ run_model(data_frame(x = .x, y = .y))),
    delta = map_dbl(results, ~ .$results$delta),
    effect = map_dbl(results, ~ .$results$effect)
  ) %>%
  select(-results)


# export ------------------------------------------------------------------

df_results %>%
  saveRDS("rds/crossings-scores.rds")

df_results %>%
  saveRDS("csv/crossings-scores.csv")
