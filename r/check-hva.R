# check HVA example from scott

library(tidyverse)
library(jsonlite)

rm(list = ls())

project <- read_json("~/Downloads/hva-analysis (2).json", simplifyVector = TRUE)

# load functions
source("~/Dropbox/SHEDS/clsb/transfers/20180427 - demo code/CLSB/find.nodes.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180427 - demo code/CLSB/get.graph.tiles.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180427 - demo code/CLSB/graph.kernel.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180427 - demo code/CLSB/trim.along.graph.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180427 - demo code/CLSB/trim.graph.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180723 - code updates/graph.kernel.spread.R")
source("~/Dropbox/SHEDS/clsb/transfers/20180723 - code updates/graph.linkages.R")

# does scenario 3 yield have delta/effect than scenario 2?

scenario_2_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 2)]] %>%
  rename(barrier_id = id, x = x_coord, y = y_coord)
scenario_3_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 3)]] %>%
  rename(barrier_id = id, x = x_coord, y = y_coord)
scenario_60_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 60)]] %>%
  rename(barrier_id = id, x = x_coord, y = y_coord)

# compute linkages
results_2 <- graph.linkages(scenario_2_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_3 <- graph.linkages(scenario_3_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_60 <- graph.linkages(scenario_60_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")

c(results_2$results$delta, results_2$results$effect)
c(results_3$results$delta, results_3$results$effect)
c(results_60$results$delta, results_60$results$effect)



# updated functions -------------------------------------------------------

# load functions
source("load-functions.R")

# does scenario 3 yield have delta/effect than scenario 2?

scenario_2_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 2)]] %>%
  rename(x = x_coord, y = y_coord)
scenario_3_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 3)]] %>%
  rename(x = x_coord, y = y_coord)
scenario_60_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 60)]] %>%
  rename(x = x_coord, y = y_coord)

# compute linkages
results_2 <- graph.linkages(scenario_2_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_3 <- graph.linkages(scenario_3_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_60 <- graph.linkages(scenario_60_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")

c(results_2$results$delta$total, results_2$results$effect$total)
c(results_3$results$delta$total, results_3$results$effect$total)
c(results_60$results$delta$total, results_60$results$effect$total)


scenario_60_barriers
sum(results_60$results$kernels$base)
sum(results_60$results$kernels$alt)
results_60$results$targets
results_60$results$nodes %>%
  filter(nodeid %in% results_60$results$targets$nodeid)



# graph linkages - 60 -----------------------------------------------------

# 'graph.linkages' <- function(targets, internode = 200, tilesize = 400, bandwidth = 5000, search = 1.5, cellsize = 30, fudge = 75,
#                              source = paste('z:/working/clsb/RDS', tilesize, '/', internode, '/', sep = ''), chatter = FALSE,
#                              scaleby = 0.001, write = FALSE, multiplier = 1000 * 0.2495 * 4.88)
# {

targets = scenario_60_barriers
internode = 200
tilesize = 400
bandwidth = 5000
search = 1.5
cellsize = 30
fudge = 75
source = "~/Dropbox/SHEDS/clsb/data/200/"
chatter = FALSE
scaleby = 0.001
write = FALSE
multiplier = 1000 * 0.2495 * 4.88

targets$upgrades <- 0                       # upgraded culverts/removed dams get cost of 0

# Start by reading graph(s) for target x,ys
d <- get.graph.tiles(points = targets, bandwidth = bandwidth, search = search, tilesize = tilesize, internode = internode,
                     cellsize = cellsize, fudge = fudge, source = source, upgrades = TRUE, chatter = chatter)
targets <- d$targets    # now have nodeids in targets
nodes <- d$nodes
edges <- d$edges
nodes$upgrades <- nodes$cost
nodes$upgrades[match(targets$nodeid, nodes$nodeid)] <- 0    # upgrade culverts and dams to cost = 0

# now build kernels for both base and alt scenarios
base <- alt <- rep(0, dim(edges)[1])        # kernel results
for(i in 1:dim(edges)[1]) {                 # for each edge, build base and alt kernels
  base <- base + graph.kernel(i, nodes, edges, multiplier = multiplier)$kern * edges$length[i] / cellsize      # kernel x # of focal cells
  alt <- alt + graph.kernel(i, nodes, edges, nodecost = nodes$upgrades, multiplier = multiplier)$kern * edges$length[i] / cellsize
}



# graph kernel - 60 -------------------------------------------------------

# 'graph.kernel' <- function(edge, nodes, edges, nodecost = nodes$cost, bandwidth = 5000, cellsize = 30, bench = 62620.5,
                           # multiplier = 1)

# bandwidth = 5000
# cellsize = 30
bench = 62620.5
# multiplier = 1

# base
nodecost = nodes$cost

base2 <- alt2 <- rep(0, dim(edges)[1])        # kernel results
for(i in 1:dim(edges)[1]) {                 # for each edge, build base and alt kernels

  edge <- i

  graph.kern <- rep(0, dim(edges)[1])             # raw kernel
  graph.kern[edge] <- account <- bandwidth * 3 / cellsize
  graph.kernel.spread(edge, 1, account, nodes = nodes, edges = edges, nodecost = nodecost)   # recursively spread in each direction
  graph.kernel.spread(edge, 2, account, nodes = nodes, edges = edges, nodecost = nodecost)

  # rescale as in AQCONNECT
  kern <- multiplier * (graph.kern > 0) * dnorm(3 - graph.kern / (bandwidth / cellsize)) / bench     # Gaussian scaling, as in AQCONNECT/CONNECT_RESCALE

  base2 <- base + kern * edges$length[i] / cellsize
  # base <- base + graph.kernel(i, nodes, edges, multiplier = multiplier)$kern * edges$length[i] / cellsize      # kernel x # of focal cells
  # alt <- alt + graph.kernel(i, nodes, edges, nodecost = nodes$upgrades, multiplier = multiplier)$kern * edges$length[i] / cellsize
}


# fixed functions ---------------------------------------------------------


source("~/Dropbox/SHEDS/clsb/transfers/20181120 - code updates/trim.along.graph.R")

results_2 <- graph.linkages(scenario_2_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_3 <- graph.linkages(scenario_3_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_60 <- graph.linkages(scenario_60_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")

c(results_2$results$delta, results_2$results$effect)
c(results_3$results$delta, results_3$results$effect)
c(results_60$results$delta, results_60$results$effect)














# post-update -------------------------------------------------------------

# 13-15 still a problem?

source("load-functions.R")

project <- read_json("~/Downloads/hva-analysis.json", simplifyVector = TRUE)

scenario_13_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 13)]] %>%
  rename(barrier_id = id, x = x_coord, y = y_coord)
scenario_14_barriers <- project$scenarios$barriers[[which(project$scenarios$id == 14)]] %>%
  rename(barrier_id = id, x = x_coord, y = y_coord)

results_13 <- graph.linkages(scenario_13_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")
results_14 <- graph.linkages(scenario_14_barriers, source = "~/Dropbox/SHEDS/clsb/data/200/")

c(results_13$results$delta$total, results_13$results$effect$total)
c(results_14$results$delta$total, results_14$results$effect$total)

