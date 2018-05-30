# run the demo

# load functions
source("load-functions.R")

# load culvert list
culv <- data.frame(read.csv("demo/culv.csv"))

# compute linkages
graph.linkages(culv, source = "demo/tiles/")
