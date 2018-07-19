'graph.kernel' <- function(edge, nodes, edges, nodecost = nodes$cost, bandwidth = 5000, cellsize = 30, bench = 62620.5,
                           multiplier = 1)

# graph.kernel
# Build a resistant kernel through a graph
# Arguments:
#   edge        focal edge (row in edges)
#   kern        kernel values, corresponding to edges
#   nodes       graph nodes
#   edges       graph edges
#   nodecost    costs to use for nodes (default is nodes$cost)
#   bandwidth   bandwidth (m)
#   cellsize    cell size (m)
#   bench       benchmark, a constant (sum of E in AQCONNECT), dependent upon bandwidth = 5000 and cellsize = 30
#   multiplier  multiply scaled kernels by this to match AQCONNECT
# Results (as a list):
#   kern        scaled kernel
#   rawkern     raw kernel, for test.kernel
# B. Compton, 19 Mar 2018 (from test.kernel)
# 3 Apr 2018: add multiplier


{
    graph.kern <<- rep(0, dim(edges)[1])             # raw kernel
    graph.kern[edge] <<- account <- bandwidth * 3 / cellsize
    graph.kernel.spread(edge, 1, account, nodes = nodes, edges = edges, nodecost = nodecost)   # recursively spread in each direction
    graph.kernel.spread(edge, 2, account, nodes = nodes, edges = edges, nodecost = nodecost)

    # rescale as in AQCONNECT
    kern <- multiplier * (graph.kern > 0) * dnorm(3 - graph.kern / (bandwidth / cellsize)) / bench     # Gaussian scaling, as in AQCONNECT/CONNECT_RESCALE

    list(kern = kern, rawkern = graph.kern)
}
