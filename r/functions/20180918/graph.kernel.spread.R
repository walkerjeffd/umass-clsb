'graph.kernel.spread' <- function(edge, direction, account, nodes, edges, nodecost = nodes$cost, edgecost = edges$cost)

# graph.kernel.spread
# Recursively spread from starting edge through the graph until account runs out
# Arguments:
#   edge        row in edge table
#   direction   direction to follow edges (1 = follow node1, 2 = follow node2)
#   account     remaining bank account (bandwidth * search - costs)
#   nodes       node table
#   edges       edges table
#   nodecost    costs to use for nodes (default is nodes$cost)
#   edgecost    costs to use for edges (default is edges$cost)
# Global:
#   graph.kern  global kernel, corresponds with edges
# B. Compton, 25 Jul 2017
# 1 Nov 2017: allow passing in costs for trim.along.graph
# 12 Feb 2018: don't allow kernel to fall below zero
# 19 Mar 2018: change global to graph.kern--this has to be global or else we'll make a copy at each recursion!
# 23 Jul 2018: aargh--I forgot to pass nodecost when recursing...Jeff found this


{
    n <- match(edges[edge, direction], nodes$nodeid)# next node
    a <- account - nodecost[n]                      # subtract cost
    if (a <= 0)                                     # if account is depleted, we're done
        return(NULL)
    e <- (1:dim(edges)[1])[(edges$node1 %in% nodes$nodeid[n]) | (edges$node2 %in% nodes$nodeid[n])]    # adjacent edges
    e <- e[e != edge]                               # exclude edge we started with!

    for (i in e) {                                  # for each adjacent edge,
        graph.kern[i] <<- max(a - edgecost[i], 0)   # subtract edge cost (but don't go below zero)
        if (graph.kern[i] <= 0)                     # if account is depleted, we're done
            return(NULL)
        graph.kernel.spread(i, (edges$node1[i] == nodes$nodeid[n]) + 1, graph.kern[i], nodes = nodes, edges = edges, nodecost = nodecost)
    }
}