# figure out how to extract barriers from nodes, compare to shapefiles
# assumes dams and crossings tables in db populated from shapefiles

library(tidyverse)
library(RPostgreSQL)
library(jsonlite)

source("load-functions.R")
source("functions.R")

config <- load_config()

db <- src_postgres(
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

shp_dams <- tbl(db, "dams") %>%
  select(-geom) %>%
  collect()
shp_crossings <- tbl(db, "crossings") %>%
  select(-geom) %>%
  collect()

nodes <- tbl(db, "nodes") %>%
  select(-geom) %>%
  collect()

nodes_dams <- nodes %>%
  filter(what == "dam")
nodes_crossings <- nodes %>%
  filter(what == "crossing")

nrow(nodes_dams)
nrow(shp_dams)

nrow(nodes_crossings)
nrow(shp_crossings)

# duplicated nodes
nodes %>%
  select(id, x, y) %>%
  group_by(x, y) %>%
  count() %>%
  filter(n > 1) %>%
  arrange(desc(n))

