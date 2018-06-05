# load huc8 from geojson and save to rds for shiny

library(tidyverse)
library(leaflet)
library(geojsonio)

huc8 <- geojson_read("geojson/huc8.geojson", what = "sp")

leaflet(huc8) %>%
  addTiles() %>%
  addPolygons(
    color = "#444444",
    weight = 1,
    smoothFactor = 0.5,
    opacity = 1.0,
    fillOpacity = 0.5,
    fillColor = "red",
    label = ~ paste0(huc8, ": ", name),
    highlightOptions = highlightOptions(
      color = "white",
      weight = 2,
      bringToFront = TRUE
    )
  )

saveRDS(huc8, file = "rds/huc8.rds")
