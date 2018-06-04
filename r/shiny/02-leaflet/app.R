library(shiny)
library(leaflet)
library(DT)
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
  sidebarLayout(
    sidebarPanel(
      verbatimTextOutput(outputId = "rowCount"),
      actionButton(inputId = "clearSelected", label = "Clear Selected"),
      actionButton(inputId = "runModel", label = "Run Model"),
      verbatimTextOutput(outputId = "modelOutput")
    ),
    mainPanel(
      leafletOutput(outputId = "map"),
      h2("Selected Crossings"),
      DTOutput(outputId = "table")
    )
  )
)

pal <- colorFactor(palette = c("blue", "red"), c(TRUE, FALSE))

server <- function(input, output) {
  # list of selected crossing ids
  selected <- reactiveValues(ids = integer())

  # crossings data frame augmented with selected column
  selectedData <- reactive({
    crossings %>%
      mutate(
        selected = id %in% selected$ids
      )
  })

  output$rowCount <- renderText({
    paste0(
      "Total # Crossings = ", nrow(selectedData()), "\n",
      "# Selected Crossings = ", sum(selectedData()$selected)
    )
  })

  output$selected <- renderText({
    paste0("Last Selected ID = ", input$map_shape_click$id)
  })

  observeEvent(input$map_shape_click, {
    id <- input$map_shape_click$id
    if (id %in% selected$ids) {
      # crossing already selected, remove it
      selected$ids <- selected$ids[-which(selected$ids == id)]
    } else {
      # add selected crossing
      selected$ids <- c(selected$ids, id)
    }
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

  output$table <- renderDT({
    selectedData() %>%
      filter(selected) %>%
      select(-selected)
  }, options = list(
    pageLength = 5
  ))

  observeEvent(selected$ids, {
    leafletProxy("map", data = selectedData()) %>%
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

  observeEvent(input$clearSelected, {
    selected$ids <- integer()
  })

  modelOutput <- eventReactive(input$runModel, {
    df <- selectedData() %>%
      filter(selected) %>%
      select(id, x = x_coord, y = y_coord)
    if (nrow(df) > 0) {
      return(graph.linkages(df, source = config$tiles$dir, chatter = FALSE)  )
    } else {
      return(NULL)
    }
  })

  output$modelOutput <- renderText({
    output <- modelOutput()
    if (is.null(output)) {
      x <- paste0("No results")
    } else {
      elapsed <- modelOutput()$elapsed
      results <- modelOutput()$results
      x <- paste0(
        "Model Results\n",
        "==============================\n",
        "Delta = ", results$delta, "\n",
        "Effect = ", results$effect, "\n",
        "Elapsed Time = ", format(elapsed, digits = 2), " sec"
      )
    }
    x

  })
}

shinyApp(ui, server)
