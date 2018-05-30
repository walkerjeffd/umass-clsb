'trim.graph' <- function(nodes, edges, targets, maxdist, points = FALSE, chatter = TRUE)

# trim.graph
# Trim nodes and edges to only include those in vicinity of sample points
# Arguments:
#   nodes       table of nodes
#   edges       table of edges
#   targets     vector of one or more nodeids (if points = FALSE), or matrix of x,ys (if points = TRUE)
#   maxdist     maximum distance from points to allow nodes (usually bandwidth * search + internode)
#   points      flag for whether targets are points (TRUE) or nodeids (FALSE)
# Returns:
#   nodes, edges (as a list)
# B. Compton, 25 Sep 2017
# 26 Sep 2017: allow targets to be points as well as nodes
# 14 Mar 2018: add chatter option



{
    if (points) {
        q <- data.frame(targets)
        names(q) <- c('x', 'y')
    }
    else {
        i <- match(targets, nodes[, 1])  # row indices to target nodes
        if (any(is.na(i)))
            stop('Error: one or more targets are not present in graph.')
        q <- nodes[i, c('x', 'y')]
    }

    if(chatter)
        cat('Starting with ', paste(dim(nodes)[1], 'nodes.\n'))

    m <- rbind(q - maxdist, q + maxdist)

    # First, coarsely to combined MER
    nodes <- nodes[(nodes$x >= min(m$x)) & (nodes$x <= max(m$x)) & (nodes$y >= min(m$y)) & (nodes$y <= max(m$y)),]  # trim to MER of all targets combined

    if(chatter)
        cat('MER trimming:', paste(dim(nodes)[1], 'nodes remain.\n'))

    # Then by Euclidean distance to each target
    b <- rep(0, dim(nodes)[1])
    for(j in 1:dim(q)[1])
        b <- b | ((sqrt((q$x[j] - nodes$x) ^ 2 + (q$y[j] - nodes$y) ^ 2)) <= maxdist)
    nodes <- nodes[b == 1,]

    # and trim edges to match nodes (we always end at nodes--no hanging edges allowed)
    edges <- edges[(edges$node1 %in% nodes$nodeid) & (edges$node2 %in% nodes$nodeid),]

    if(chatter)
        cat('Euclidean trimming by target:', paste(dim(nodes)[1], 'nodes and', dim(edges)[1], 'edges remain.\n'))


    list(nodes = nodes, edges = edges)
}