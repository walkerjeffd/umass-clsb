'trim.along.graph' <- function(nodes, edges, focalnodes = NULL, bandwidth, cellsize = 30, chatter = TRUE, nodecosts = NULL)

# trim.along.graph
# Follow graph and trim nodes and edges to only include those that are actually reachable within bandwidth along graph
# Uses immmutable edge resistances, but treats node resistances as 0, allowing them to be monkeyed with...unless nodecosts
# is passed, with costs to use (allows graph.linkages to use upgraded culverts)
# Arguments:
#   nodes       table of nodes
#   edges       table of edges
#   focalnodes  nodeid(s) of node(s) to start with
#   bandwidth   kernel bandwidth (m)
#   cellsize    size of cells (m)
#   chatter     if TRUE, chatter along the way
#   nodecosts   if NULL, uses 0s, otherwise, can pass in costs to use
# Returns:
#   nodes, edges (as a list)
# B. Compton, 30 Oct-1 Nov 2017
# 20-22 Feb 2018: add focalnodes--now can trim from either focal edge or node
# 23 Feb 2018: drop focaledge--I'm not going to use it
# 14 Mar 2018: add chatter option
# 19 Mar 2018: add nodecosts option for graph.linkages



{
    account <- bandwidth * 3 / cellsize
    graph.kern <<- rep(0, dim(edges)[1])      # global kernel result
    if(is.null(nodecosts))
        nodecosts <- rep(0, dim(nodes)[1])

    i <- (1:dim(edges)[1])[!is.na(match(edges$node1, focalnodes))]       #    find row(s) in edges, 1st direction
    if(length(i) > 0) {
        graph.kern[i] <<- 1
        for(j in 1:length(i))                 #   for each edge,
            graph.kernel.spread(i[j], 2, account, nodes = nodes, edges = edges, nodecost = nodecosts)     #    recursively spread in each direction
    }
    i <- (1:dim(edges)[1])[!is.na(match(edges$node2, focalnodes))]       #    find row(s) in edges, 2nd direction
    if(length(i) > 0) {
        graph.kern[i] <<- 1
        for(j in 1:length(i))                 #   for each edge,
            graph.kernel.spread(i[j], 1, account, nodes = nodes, edges = edges, nodecost = nodecosts)     #    recursively spread in each direction
    }

    edges <- edges[graph.kern != 0,]          # keep only edges we reached
    nodes <- nodes[nodes$nodeid %in% c(edges$node1, edges$node2),]     # keep only nodes used by these edges

    if(chatter)
        cat('Along-stream trimming by target:', paste(dim(nodes)[1], 'nodes and', dim(edges)[1], 'edges remain.\n'))

    list(nodes = nodes, edges = edges)
}