# evaluate model performance as function of number of crossings

library(tidyverse)
library(jsonlite)

source("load-functions.R")

config <- load_config()

conn <- dbConnect(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

sql <- "SELECT id, type, x_coord, y_coord, lat, lon FROM barriers b"
barriers <- dbGetQuery(conn, sql) %>%
  select(id, x = x_coord, y = y_coord)

summary(barriers)

run_model <- function(n) {
  graph.linkages(sample_n(barriers, size = n), source = config$tiles$dir)
}

df <- data_frame(
  n = c(1, 5, 10, 20)
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


# profvis -----------------------------------------------------------------
library(profvis)

p <- profvis({
  run_model(n = 3)
})
p
