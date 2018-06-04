library(shiny)
library(leaflet)
library(jsonlite)

config <- read_json("../../config.json")

for (f in list.files(path = "../../functions")) {
  source(file.path("../../functions", f))
}

crossings <- read_csv(
  "../../csv/crossings-01040002.csv",
  col_types = cols(
    id = col_integer(),
    x_coord = col_double(),
    y_coord = col_double(),
    lon = col_double(),
    lat = col_double()
  )
)

ui <- fluidPage(
  titlePanel("Critical Linkages Scenario Builder"),
  verticalLayout(
    leafletOutput(outputId = "map"),
    verbatimTextOutput(outputId = "rowCount"),
    verbatimTextOutput(outputId = "selected")
  )
)

pal <- colorFactor(palette = c("blue", "red"), c(TRUE, FALSE))

server <- function(input, output) {
  values <- reactiveValues(selected = integer())

  selectedData <- reactive({
    crossings %>%
      mutate(selected = id %in% values$selected)
  })

  output$rowCount <- renderText({
    paste0(
      "N = ", nrow(crossings), "\n",
      "n = ", length(values$selected)
    )
  })

  output$selected <- renderText({
    # List of 4
    # $ id    : int 338134
    # $ .nonce: num 0.154
    # $ lat   : num 44
    # $ lng   : num -70.1
    cat(str(input$map_shape_click))
    paste0("Selected ID = ", input$map_shape_click$id)
  })

  observeEvent(input$map_shape_click, {
    values$selected <- c(values$selected, input$map_shape_click$id)

    proxy <- leafletProxy("map", data = selectedData()) %>%
      clearShapes() %>%
      addCircles(
        layerId = ~ id,
        lng = ~ lon,
        lat = ~ lat,
        color = ~ pal(selected),
        highlightOptions = highlightOptions(
          color = "red",
          weight = 6,
          bringToFront = TRUE
        )
      )
  })

  output$map <- renderLeaflet({
    leaflet(crossings) %>%
      addTiles() %>%
      addCircles(
        layerId = ~ id,
        lng = ~ lon,
        lat = ~ lat,
        highlightOptions = highlightOptions(
          color = "red",
          weight = 6,
          bringToFront = TRUE
        )
      )
  })
}

shinyApp(ui, server)
