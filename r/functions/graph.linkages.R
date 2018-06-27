'graph.linkages' <- function(targets, internode = 200, tilesize = 400, bandwidth = 5000, search = 1.5, cellsize = 30, fudge = 75,
                             source = paste('z:/working/clsb/RDS', tilesize, '/', internode, '/', sep = ''), chatter = FALSE,
                             scaleby = 0.001, write = FALSE, multiplier = 1000 * 0.2495 * 24)

# graph.linkages
# Do graph-based Critical Linkages I for specified target nodes
# Arguments:
#   targets     data frame of x,y locations of target culverts/dams
#   internode   internode interval, which gives us maximum edge length
# 	tilesize    size of tiles used for RDS files
#   bandwidth   bandwidth (m)
#   search      search distance (multiple of bandwidth)
#   cellsize    size of cells (m)
#   fudge       how far (m) do we allow x,ys to be from actual culverts?
# 	source		path to source graphs, created by make.graph.tiles. Path should end with clsb/RDS<tilesize>/<internode>/,
# 	            unless data have been moved for production runs.
# 	chatter     if TRUE, chatter; otherwise, run silently
# 	scaleby     parameter from CAPS LINKAGES; use 0.001
# 	write       if TRUE, write result kernel for ArcMap
# 	multiplier  multiply scaled kernels by this to match AQCONNECT
# Source data:
#	linktable.txt		table with row #, col #, min.x, min.y, max.x, max.y for each result tile. Points to row and col in
# 	                    linkgraph<r><c>txt.
# 	linkgraph<rrr><ccc>.RDS nodes & edges for each tile
# Result (as a list):
#   results
#       delta       delta IEI for upgraded culverts/dams
#       effect      effect (IEI * delta IEI)
#   elapsed         total elapsed run time
# B. Compton, 19 Mar 2018
# 3 Apr 2018: add multiplier
# 27 Apr 2018: get effect right


{
    a <- proc.time()[3]
    if(bandwidth != 5000 | cellsize != 30)
        stop('Non-standard bandwidth or cellsize breaks assigned value of bench')

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

    base <- base * edges$length / cellsize      # adjust for # of cells in each kernel
    alt <- alt * edges$length / cellsize
    deltas <- (alt - base) / scaleby
    effects <- deltas * edges$value / (edges$length / cellsize)

    z <- list(
      delta = sum(deltas),
      deltas = deltas,
      effect = sum(effects),
      effects = effects,
      edges = edges,
      nodes = nodes,
      kernels = list(
        base = base,
        alt = alt
      )
    )

    elapsed <- proc.time()[3] - a
    # cat('\nTotal elapsed time = ', elapsed, ' sec\n', sep = '')
    # cat('\nTime spent reading tiles = ', round(100 * d$readtime / elapsed), '%\n', sep = '')

    if(write)
        kern2arc(nodes, cbind(edges, base, alt, deltas))

    list(results = z, elapsed = elapsed, readtime = d$readtime)
}
