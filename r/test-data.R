# export datasets for testing

library(tidyverse)
library(RPostgreSQL)
library(jsonlite)

source("load-functions.R")
source("functions.R")

config <- load_config()

con <- dbConnect(
  RPostgreSQL::PostgreSQL(),
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

source = config$tiles$dir         # folder containing tiles
internode = 200                   # internode interval (gives maximum edge length)
tilesize = 400                    # size of tiles
bandwidth = 5000                  # bandwidth (m)
search = 1.5                      # search distance (multiple of bandwidth)
cellsize = 30                     # size of cells (m)
fudge = 75                        # how far (m) do we allow x,ys to be from actual culverts?
scaleby = 0.001                   # parameter from CAPS LINKAGES; use 0.001
multiplier = 1000 * 0.2495 * 4.88 # multiply scaled kernels to match AQCONNECT

barriers <- tbl(con, "barriers") %>%
  select(id, x = x_coord, y = y_coord, effect, effect_ln, delta, type, lat, lon) %>%
  left_join(
    tbl(con, "barrier_node") %>%
      select(barrier_id, node_id),
    by = c("id" = "barrier_id")
  ) %>%
  collect()

# graph-trim-single -------------------------------------------------------

# inputs
targets <- barriers %>% filter(id == "c-293762")
targets$upgrades <- 0

# get.graph.tiles() arguments
points = as.data.frame(targets) # df of x,y locations of target culverts/dams
nodecosts = NULL                # ??
upgrades = TRUE                 # if TRUE, use points$upgrades for nodecosts in trim.along.graph

maxdist <- bandwidth * search + internode + fudge
xys <- points[, c('x', 'y')]
xys <- cbind(xys, xys - maxdist, xys + maxdist)
colnames(xys) <- c('x', 'y', 'xmin', 'ymin', 'xmax', 'ymax')

tiles <- read.table(paste(source, 'graphtiles.txt', sep = ''), sep = '\t', header = TRUE)
q <- outer(tiles$xmin, xys$xmax, '<=') & outer(tiles$ymin, xys$ymax, '<=') & outer(tiles$xmax, xys$xmin, '>=') & outer(tiles$ymax, xys$ymin, '>=')
b <- apply(q, 1, 'any')
tiles <- tiles[b,]
f <- paste(source, sprintf('graph%03d%03d.RDS', tiles$row, tiles$col), sep = '')

nodes <- edges <- matrix(0, 0, 0)

for(i in 1:dim(tiles)[1]) {
  q <- readRDS(f[i])
  nodes <- rbind(nodes, q[[1]])
  edges <- rbind(edges, q[[2]])
}
edges <- unique(edges)

tiled <- trim.graph(nodes, edges, xys, maxdist, points = TRUE, chatter = FALSE)
p <- find.nodes(xys, tiled$nodes, fudge)

points <- cbind(points, p)
names(points)[dim(points)[2]] <- 'nodeid'

nodecosts <- tiled$nodes$cost
nodecosts[match(points$nodeid, tiled$nodes$nodeid)] <- points$upgrades

# JS: graph.trim()
trimmed <- trim.along.graph(tiled$nodes, tiled$edges, p, bandwidth = bandwidth, cellsize = cellsize, nodecosts = nodecosts, chatter = FALSE)

# export with matchin javascript types
list(
  targets = points %>%
    rename(x_coord = x, y_coord = y) %>%
    mutate(node_id = sprintf("%.0f", node_id)) %>%
    select(-upgrades, -nodeid),
  input = list(
    nodes = tiled$nodes %>%
      rename(node_id = nodeid) %>%
      mutate(node_id = sprintf("%.0f", node_id)),
    edges = tiled$edges %>%
      rename(start_id = node1, end_id = node2) %>%
      mutate(
        start_id = sprintf("%.0f", start_id),
        end_id = sprintf("%.0f", end_id)
      )
  ),
  output = list(
    nodes = trimmed$nodes %>%
      rename(node_id = nodeid) %>%
      mutate(node_id = sprintf("%.0f", node_id)),
    edges = trimmed$edges %>%
      rename(start_id = node1, end_id = node2) %>%
      mutate(
        start_id = sprintf("%.0f", start_id),
        end_id = sprintf("%.0f", end_id)
      )
  )
) %>%
  write_json("../test/data/graph-trim-single.json", pretty = TRUE, auto_unbox = TRUE)


# graph-trim-multiple -----------------------------------------------------

# inputs
targets <- barriers %>% filter(id %in% c("c-244844", "c-244895", "c-282781", "c-361794"))
targets$upgrades <- 0

# get.graph.tiles() arguments
points = as.data.frame(targets) # df of x,y locations of target culverts/dams
nodecosts = NULL                # ??
upgrades = TRUE                 # if TRUE, use points$upgrades for nodecosts in trim.along.graph

maxdist <- bandwidth * search + internode + fudge
xys <- points[, c('x', 'y')]
xys <- cbind(xys, xys - maxdist, xys + maxdist)
colnames(xys) <- c('x', 'y', 'xmin', 'ymin', 'xmax', 'ymax')

tiles <- read.table(paste(source, 'graphtiles.txt', sep = ''), sep = '\t', header = TRUE)
q <- outer(tiles$xmin, xys$xmax, '<=') & outer(tiles$ymin, xys$ymax, '<=') & outer(tiles$xmax, xys$xmin, '>=') & outer(tiles$ymax, xys$ymin, '>=')
b <- apply(q, 1, 'any')
tiles <- tiles[b,]
f <- paste(source, sprintf('graph%03d%03d.RDS', tiles$row, tiles$col), sep = '')

nodes <- edges <- matrix(0, 0, 0)

for(i in 1:dim(tiles)[1]) {
  q <- readRDS(f[i])
  nodes <- rbind(nodes, q[[1]])
  edges <- rbind(edges, q[[2]])
}
edges <- unique(edges)

tiled <- trim.graph(nodes, edges, xys, maxdist, points = TRUE, chatter = FALSE)
p <- find.nodes(xys, tiled$nodes, fudge)

points <- cbind(points, p)
names(points)[dim(points)[2]] <- 'nodeid'

nodecosts <- tiled$nodes$cost
nodecosts[match(points$nodeid, tiled$nodes$nodeid)] <- points$upgrades

# JS: graph.trim()
trimmed <- trim.along.graph(tiled$nodes, tiled$edges, p, bandwidth = bandwidth, cellsize = cellsize, nodecosts = nodecosts, chatter = FALSE)

# export with matchin javascript types
list(
  targets = points %>%
    rename(x_coord = x, y_coord = y) %>%
    mutate(node_id = sprintf("%.0f", node_id)) %>%
    select(-upgrades, -nodeid),
  input = list(
    nodes = tiled$nodes %>%
      rename(node_id = nodeid) %>%
      mutate(node_id = sprintf("%.0f", node_id)),
    edges = tiled$edges %>%
      rename(start_id = node1, end_id = node2) %>%
      mutate(
        start_id = sprintf("%.0f", start_id),
        end_id = sprintf("%.0f", end_id)
      )
  ),
  output = list(
    nodes = trimmed$nodes %>%
      rename(node_id = nodeid) %>%
      mutate(node_id = sprintf("%.0f", node_id)),
    edges = trimmed$edges %>%
      rename(start_id = node1, end_id = node2) %>%
      mutate(
        start_id = sprintf("%.0f", start_id),
        end_id = sprintf("%.0f", end_id)
      )
  )
) %>%
  write_json("../test/data/graph-trim-multiple.json", pretty = TRUE, auto_unbox = TRUE)



# graph-single-effects ----------------------------------------------------


targets <- barriers %>% filter(id == "c-177097") %>%
  rename(nodeid = node_id)
r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)


list(
  targets = targets %>%
    rename(x_coord = x, y_coord = y, node_id = nodeid) %>%
    mutate(node_id = sprintf("%.0f", node_id)),
  network = list(
    nodes = network$nodes %>%
      rename(node_id = nodeid) %>%
      mutate(node_id = sprintf("%.0f", node_id)),
    edges = network$edges %>%
      rename(start_id = node1, end_id = node2) %>%
      mutate(
        start_id = sprintf("%.0f", start_id),
        end_id = sprintf("%.0f", end_id)
      )
  ),
  output = r$results
) %>%
  write_json("../test/data/graph-effects-single.json", pretty = TRUE, auto_unbox = TRUE)
