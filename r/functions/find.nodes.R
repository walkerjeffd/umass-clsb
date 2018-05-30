'find.nodes' <- function(xy, nodes, fudge = 75)

# find.nodes
# return vector of nodeids closest to one or more x,y coordinates
# Arguments:
#   xy      vector, matrix, or data frame of one or more pairs of x,y (if data frame, must have columns named x and y)
#   nodes   universe of graph nodes
#   fudge   maximum distance to node - gives error if nothing available
# Result:
#   vector of nodeids
# B. Compton, 23 Feb 2018


{
    if(is.vector(xy))
        xy <- matrix(xy, length(xy) / 2, 2)
    if(!is.data.frame(xy)) {
        xy <- data.frame(xy)
        names(xy) <- c('x', 'y')
    }

    z <- rep(0, dim(xy)[1])
    for(i in 1:dim(xy)[1]) {                # For each coordinate,
        n <- nodes[(nodes$x >= xy$x[i] - fudge) & (nodes$y >= xy$y[i] - fudge) & (nodes$x <= xy$x[i] + fudge) & (nodes$y <= xy$y[i] + fudge),]
        q <- sqrt((n$x - xy$x[i]) ^ 2 + (n$y - xy$y[i]) ^2)
        z[i] <- n$nodeid[q == min(q)][1]    #   take closest one (1st in unlikely case of ties)
    }
    if(any(is.na(z)))
        stop('No nearby nodes for ',sum(is.na(z)),' points in find.nodes')
    z
}