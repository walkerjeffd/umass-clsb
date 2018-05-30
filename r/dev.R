# development

library(jsonlite)

config <- read_json("config.json")

# load functions
source("load-functions.R")

# load culvert list
culv <- data.frame(read.csv("demo/culv.csv"))

# compute linkages
graph.linkages(culv, source = config$tiles$dir)
