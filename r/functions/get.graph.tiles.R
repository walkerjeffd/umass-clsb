'get.graph.tiles' <- function(points, bandwidth = 5000, search = 1.5, tilesize = 400, internode = 300, cellsize = 30, fudge = 75,
                              source = paste('z:/working/clsb/RDS', tilesize, '/', internode, '/',
                              sep = ''), chatter = TRUE, nodecosts = NULL, upgrades = FALSE)

# get.graph.tiles
# Read RDS graphs for supplied points for Critical Linkages Scenario Builder (CLSB) & trim them
# Parameters:
#   points              data frame of x,y locations of target culverts/dams
#   bandwidth           bandwidth (m)
# 	internode           internode
# 	tilesize            size of tiles used for RDS files
#   search              search distance (multiple of bandwidth)
#   cellsize            size of cells (m)
#   fudge               how far (m) do we allow x,ys to be from actual culverts?
# 	source		        path to source graphs, created by make.graph.tiles. Path should end with clsb/RDS<tilesize>/<internode>/,
# 	                    unless data have been moved for production runs.
# 	chatter             if TRUE, chatter; otherwise, run silently
# 	upgrades            if TRUE, use points$upgrades for nodecosts in trim.along.graph
# Source data:
# 	linktable.txt		table with row #, col #, min.x, min.y, max.x, max.y for each result tile. Points to row and col in
# 	                    linkgraph<r><c>txt.
# 	linkgraph<rrr><ccc>.RDS nodes & edges for each tile
# Results, as a list:
#   nodes               nodes of graph in neighborhood of points
#   edges               edges of graph
#   targets             data frame of x, y, and nodeids
#   time                global runtime (s)
#   readtime            time spend reading tiles (s)
# RDS files are created by make.graph.tiles from LINK2GRAPH/LINK2GRAPHB results
# B. Compton, 19-20 Feb 2018
# 23 Feb 2018: find nodes and trim along graph
# 13-14 Mar 2018: a couple of minor changes; add chatter option
# 19 Mar 2018: change returns: now a list of nodes, edges, target points, and time; if upgrades, pass nodecosts to trim.along.graph
# 6 Apr 2018: add readtime


{
    a <- proc.time()[3]
    readtime <- 0
    maxdist <- bandwidth * search + internode + fudge   # buffer around points--farthest that kernels can be affected by culvert
    points <- data.frame(points)                        # make sure we have a data frame
    xys <- points[, c('x', 'y')]
    xys <- cbind(xys, xys - maxdist, xys + maxdist)
    colnames(xys) <- c('x', 'y', 'xmin', 'ymin', 'xmax', 'ymax')
    tiles <- read.table(paste(source, 'graphtiles.txt', sep = ''), sep = '\t', header = TRUE)

    # find tiles with our xys + buffer
    q <- outer(tiles$xmin, xys$xmax, '<=') & outer(tiles$ymin, xys$ymax, '<=') & outer(tiles$xmax, xys$xmin, '>=') & outer(tiles$ymax, xys$ymin, '>=')
    b <- apply(q, 1, 'any')
    tiles <- tiles[b,]                                  # these are our tiles

    f <- paste(source, sprintf('graph%03d%03d.RDS', tiles$row, tiles$col), sep = '')
    nodes <- edges <- matrix(0, 0, 0)

    if(chatter)
        cat('Reading ',dim(tiles)[1],' tiles...\n', sep = '')
    for(i in 1:dim(tiles)[1]) {                         # for each tile,
        if(chatter)
            cat(i,' ')

        a2 <- proc.time()[3]
        q <- readRDS(f[i])
        readtime <- readtime + proc.time()[3] - a2
        nodes <- rbind(nodes, q[[1]])
        edges <- rbind(edges, q[[2]])
    }

    edges <- unique(edges)      # will have duplicate dangling edges from adjacent tiles
    if(chatter)
        cat('\n', format(dim(nodes)[1], big.mark = ','), ' nodes read. Elapsed time to read tiles = ',proc.time()[3] - a, ' sec\n', sep = '')

    n <- trim.graph(nodes, edges, xys, maxdist, points = TRUE, chatter = chatter)   # trim to circles
    p <- find.nodes(xys, n$nodes, fudge)
    points <- cbind(points, p)
    names(points)[dim(points)[2]] <- 'nodeid'

        if(upgrades) {              # if using upgraded costs, assign them to the proper culverts
        nodecosts <- n$nodes$cost
        nodecosts[match(points$nodeid, n$nodes$nodeid)] <- points$upgrades
    }
    else
        nodecosts <- NULL

    n <- trim.along.graph(n$nodes, n$edges, p, bandwidth = bandwidth, cellsize = cellsize, nodecosts = nodecosts, chatter = chatter)

    elapsed <- proc.time()[3] - a
    names(readtime) <- 'readtime'
    if(chatter)
        cat('\n', format(dim(n[[1]])[1], big.mark = ','), ' nodes returned. Total elapsed time to collect graph = ', elapsed, ' sec\n', sep = '')
        z <- list(nodes = n$nodes, edges = n$edges, targets = points, time = elapsed, readtime = readtime)
    invisible(z)
}