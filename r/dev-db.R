library(tidyverse)
library(DBI)
library(pool)
library(jsonlite)

config <- read_json("config.json")

pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

sql <- "SELECT * FROM crossings_huc WHERE huc8 = $1"
df <- dbGetQuery(pool, sql, param = list('01040002'))

summary(df)

