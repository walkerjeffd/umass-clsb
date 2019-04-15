# load all graph tiles and then export to csv for database import

library(tidyverse)

source("functions.R")

config <- load_config()

tile_list <- read.table(paste(config$tiles$dir, 'graphtiles.txt', sep = ''), sep = '\t', header = TRUE)

tiles <- tile_list %>%
  as_tibble() %>%
  mutate(
    filename = map2_chr(row, col, ~ sprintf('graph%03d%03d.RDS', .x, .y)),
    tile = map(filename, ~ readRDS(file.path(config$tiles$dir, .))),
    nodes = map(tile, ~ .[[1]]),
    edges = map(tile, ~ .[[2]])
  )

nodes <- tiles %>%
  select(nodes) %>%
  unnest(nodes) %>%
  distinct() %>%
  filter(!duplicated(nodeid)) %>%
  mutate(
    what = if_else(what == "", NA_character_, what)
  )

edges <- tiles %>%
  select(edges) %>%
  unnest(edges) %>%
  distinct() %>%
  filter(
    !is.na(length),
    node1 %in% nodes$nodeid,
    node2 %in% nodes$nodeid
  )

list(
  nodes = nodes,
  edges = edges
) %>%
  saveRDS("rds/graph.rds")

nodes %>%
  rename(id = nodeid) %>%
  mutate_at(vars(id), ~ sprintf("%.0f", .)) %>%
  write_csv("csv/graph-nodes.csv", na = "")

edges %>%
  rename(start_id = node1, end_id = node2) %>%
  mutate_at(vars(start_id, end_id), ~ sprintf("%.0f", .)) %>%
  write_csv("csv/graph-edges.csv", na = "")
