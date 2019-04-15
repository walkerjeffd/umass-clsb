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
  select(id, node_id, x, y, effect, effect_ln, delta, type, lat, lon) %>%
  collect()

# graph-trim-single -------------------------------------------------------

# inputs
targets <- barriers %>% filter(id == "xy3759177679094526")
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
targets <- barriers %>% filter(id %in% c("xy4079987274217816", "xy4079526774215677", "xy4234574771734256", "xy4270499878339084"))
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


targets <- barriers %>% filter(id == "xy3817653179407171") %>%
  rename(nodeid = node_id)
r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)


list(
  targets = targets %>%
    rename(node_id = nodeid) %>%
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


# hva-scenario-2 ----------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4236183373275466", "xy4235822773270851", "xy4236154873266984", "xy4236507073262569", "xy4236508773259631"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-2.json", pretty = TRUE, auto_unbox = TRUE)


# hva-scenario-3 ----------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4236154873266984", "xy4236507073262569", "xy4236508773259631"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-3.json", pretty = TRUE, auto_unbox = TRUE)


# hva-scenario-13 ----------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4243196973275060", "xy4243010873265697", "xy4242974473260752", "xy4243072273258641", "xy4242816573249853"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-13.json", pretty = TRUE, auto_unbox = TRUE)

# hva-scenario-14 ----------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4242974473260752", "xy4243072273258641", "xy4242816573249853"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-14.json", pretty = TRUE, auto_unbox = TRUE)

# hva-scenario-15 ----------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4243196973275060", "xy4243010873265697", "xy4242974473260752", "xy4243072273258641"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-15.json", pretty = TRUE, auto_unbox = TRUE)


# hva-scenario-60 ---------------------------------------------------------

targets <- barriers %>% filter(id %in% c("xy4248734773093429", "xy4249315373076421"))

r <- graph.linkages(targets, internode = internode, tilesize = tilesize, bandwidth = bandwidth, search = search, cellsize = cellsize, fudge = fudge, source = source, chatter = FALSE, scaleby = scaleby, write = FALSE, multiplier = multiplier)
network <- get.graph.tiles(points = targets %>% mutate(upgrades = 0), bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode, cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = FALSE)

list(
  targets = targets %>%
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
  write_json("../test/data/hva-scenario-60.json", pretty = TRUE, auto_unbox = TRUE)

