library(tidyverse)
library(shiny)
library(shinyjs)
library(leaflet)
library(DT)
library(jsonlite)
library(pool)
library(DBI)

source("../functions.R")

config <- load_config("../../")
huc8 <- readRDS("../rds/huc8.rds")

pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

for (f in list.files(path = "../functions")) {
  source(file.path("../functions", f))
}

loadBarriers <- function(huc8) {
  # cat("loadBarriers(", huc8, ")\n", sep = "")

  if (is.null(huc8) || length(huc8) == 0) {
    stop(paste0("Failed to load barriers for huc8: ", huc8))
  }

  sql <- "select c.id, c.x_coord, c.y_coord, c.lon, c.lat from barriers_huc ch left join barriers c on ch.barrier_id=c.id where ch.huc8=$1";
  dbGetQuery(pool, sql, param = list(huc8))
}

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Critical Linkages Scenario Builder"),
  navlistPanel(
    widths = c(2, 10),
    id = "nav",
    tabPanel(
      title = "Welcome",
      value = "welcome",
      column(
        width = 6,
        h2("Welcome!"),
        p("The Critical Linkages Scenario Builder is a dynamic web application for evaluating the impact of stream barrier restoration across the Northeast US"),
        h3("Instructions"),
        tags$ol(
          tags$li("Select Watershed: select your target watershed (HUC8)"),
          tags$li("Select Barriers: select one or more stream barriers within the target watershed"),
          tags$li("Run Model: run the model to calculate the overall connectivity impacts due to restoration/removal of the selected barriers")
        ),
        actionButton(inputId = "welcomeNextBtn", label = "Get Started >>", class = "btn-success pull-right")
      )
    ),
    tabPanel(
      title = "Step 1: Select Watershed",
      value = "tab-watershed",
      column(
        width = 6,
        h2("Select Watershed (HUC8)"),
        leafletOutput(outputId = "watershedMap", height = 400),
        hr(),
        strong(textOutput("watershedStatus")),
        hidden(
          div(
            id = "watershed-next",
            class = "text-right",
            actionButton(inputId = "watershedNextBtn", label = "Next: Load Barriers >>", class = "btn-success")
          )
        ),

        hr(),
        h4("Debug"),
        verbatimTextOutput("watershedDebug")
      )
    ),
    tabPanel(
      title = "Step 2: Select Barriers",
      value = "tab-barriers",
      class = "disabled",
      column(
        width = 6,
        h2("Select Stream Barriers"),
        p("Select one or more stream barriers to evaluate for restoration/removal. Then click the \"Run Model\" button to calculate the overall change in aquatic connectivity."),
        leafletOutput(outputId = "barriersMap"),
        hidden(
          div(
            id = "barriersTableDiv",
            hr(),
            actionButton(inputId = "barriersNextBtn", label = "Next: Run Model >>", class = "pull-right btn-success"),
            DTOutput(outputId = "barriersTable"),
            strong(textOutput("barriersRowStatus")),
            hidden(
              div(
                id = "barriersRowButtons",
                actionButton(inputId = "barriersRemoveRow", label = "Remove"),
                actionButton(inputId = "barriersZoomToRow", label = "Zoom To")
              )
            )
          )
        ),

        hr(),
        h4("Debug"),
        verbatimTextOutput(outputId = "barriersDebug"),
        verbatimTextOutput(outputId = "barriersDebugRow")
      )
    ),
    tabPanel(
      title = "Step 3: Model Results",
      value = "tab-model",
      column(
        width = 6,
        h2("Model Results"),
        h4("Raw Results"),
        verbatimTextOutput(outputId = "modelResults"),
        hr(),
        actionButton(inputId = "modelPrevBtn", label = "<< Prev: Select Barriers", class = "btn-success")
      )

    )
  )
)

pal <- colorFactor(palette = c("blue", "red"), c(TRUE, FALSE))

server <- function(input, output, session) {
  observe({
    # disable steps 2 and 3 at start
    shinyjs::disable(selector = "#nav > li:nth-child(3)")
    shinyjs::disable(selector = "#nav > li:nth-child(4)")
  })

  # globals -----------------------------------------------------------------

  values <- reactiveValues(
    selectedBarrierIds = integer(),   # barrier ids as integer vector
    selectedHuc8Id = character(),      # selected huc8 id as character
    barriers = NULL,                  # barriers data frame
    modelResults = NULL                # model results
  )


  # welcome tab -------------------------------------------------------------

  # next button -> tab-watershed
  observeEvent(input$welcomeNextBtn, {
    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-watershed"
    )
  })


  # watershed tab -----------------------------------------------------------

  # selected HUC8 geojson object
  selectedHUC8 <- reactive({
    if (length(values$selectedHuc8Id) == 0) {
      return(NULL)
    }
    huc8[which(huc8$huc8 == values$selectedHuc8Id), ]
  })

  # handle map click
  observeEvent(input$watershedMap_shape_click, {
    id <- input$watershedMap_shape_click$id

    if (id == "selected-huc8") {
      # unselect current selection
      values$selectedHuc8Id <- character()
      shinyjs::hide(id = "watershed-next")
    } else {
      # select id
      values$selectedHuc8Id <- id
      shinyjs::show(id = "watershed-next")
    }
  })

  # render map
  output$watershedMap <- renderLeaflet({
    leaflet(huc8) %>%
      addTiles() %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Esri.WorldTopoMap") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Esri.WorldImagery") %>%
      addProviderTiles(providers$OpenTopoMap, group = "OpenTopoMap") %>%
      addProviderTiles(providers$Stamen.Terrain, group = "Stamen.Terrain") %>%
      addProviderTiles(providers$Hydda.Full, group = "Hydda.Full") %>%
      addPolygons(
        layerId = ~ huc8,
        color = "#444444",
        weight = 1,
        smoothFactor = 0.5,
        opacity = 1.0,
        fillOpacity = 0.1,
        fillColor = "gray50",
        label = ~ paste0(huc8, ": ", name),
        highlightOptions = highlightOptions(
          color = "white",
          weight = 2,
          bringToFront = TRUE
        )
      ) %>%
      addLayersControl(
        baseGroups = c("OSM (default)", "Esri.WorldTopoMap", "Esri.WorldImagery", "OpenTopoMap", "Stamen.Terrain", "Hydda.Full"),
        position = "topleft"
      )
  })

  # highlight selected HUC8 on map
  observe({
    x <- selectedHUC8()

    leafletProxy("watershedMap") %>%
      removeShape("selected-huc8")

    if (!is.null(x)) {
      leafletProxy("watershedMap") %>%
        addPolygons(
          data = x,
          layerId = "selected-huc8",
          color = "red",
          weight = 1,
          smoothFactor = 0.5,
          opacity = 1.0,
          fillOpacity = 0.1,
          fillColor = "gray50",
          label = ~ paste0(huc8, ": ", name),
          highlightOptions = highlightOptions(
            color = "red",
            weight = 2,
            bringToFront = TRUE
          )
        )
    }
  })

  # status bar text
  output$watershedStatus <- renderText({
    x <- selectedHUC8()

    if (is.null(x)) {
      return("Select your target watershed from the map.")
    } else {
      return(paste0("Selected watershed: ", x$name, " (", x$huc8, ")"))
    }
  })

  # debug
  output$watershedDebug <- renderPrint({
    x <- selectedHUC8()
    if (is.null(x)) {
      return(NULL)
    } else {
      return(str(x))
    }
  })

  # reset reactive values on new HUC8 selection
  observeEvent(values$selectedHuc8Id, {
    values$barriers <- NULL
    values$selectedBarrierIds <- integer()
    values$modelResults <- NULL
  })

  # next button -> tab-barriers
  observeEvent(input$watershedNextBtn, {
    values$barriers <- loadBarriers(values$selectedHuc8Id)
    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-barriers"
    )
  })


  # barriers tab----------------------------------------------------------

  # enable/disable Step 2 tab
  observe({
    if (length(values$selectedHuc8Id) > 0) {
      shinyjs::enable(selector = "#nav > li:nth-child(3)")
    } else {
      shinyjs::disable(selector = "#nav > li:nth-child(3)")
    }
  })

  # selected barriers data frame (from map)
  selectedBarriers <- reactive({
    if (length(values$selectedBarrierIds) == 0) {
      shinyjs::hide(id = "barriersTableDiv")
      return(NULL)
    }

    shinyjs::show(id = "barriersTableDiv")
    values$barriers %>%
      filter(id %in% values$selectedBarrierIds)
  })

  # selected barrier row (from table)
  selectedBarriersRow <- reactive({
    sel <- input$barriersTable_rows_selected

    if (length(sel) == 0) {
      return(NULL)
    }

    selectedBarriers()[sel, ]
  })

  # render initial map
  output$barriersMap <- renderLeaflet({
    if (is.null(values$barriers)) return()

    leaflet(values$barriers) %>%
      addTiles() %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Esri.WorldTopoMap") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Esri.WorldImagery") %>%
      addProviderTiles(providers$OpenTopoMap, group = "OpenTopoMap") %>%
      addProviderTiles(providers$Stamen.Terrain, group = "Stamen.Terrain") %>%
      addProviderTiles(providers$Hydda.Full, group = "Hydda.Full") %>%
      addPolygons(
        data = selectedHUC8(),
        layerId = "selected-huc8",
        options = pathOptions(interactive = FALSE),
        color = "red",
        weight = 1,
        smoothFactor = 0.5,
        opacity = 1.0,
        fillOpacity = 0,
        fillColor = "white"
      ) %>%
      addCircles(
        layerId = ~ id,
        group = "barriers",
        lng = ~ lon,
        lat = ~ lat,
        highlightOptions = highlightOptions(
          color = "red",
          weight = 6,
          bringToFront = TRUE
        )
      ) %>%
      addLayersControl(
        baseGroups = c("OSM (default)", "Esri.WorldTopoMap", "Esri.WorldImagery", "OpenTopoMap", "Stamen.Terrain", "Hydda.Full"),
        position = "topleft"
      )
  })

  # render data table
  output$barriersTable <- renderDT({
    selectedBarriers() %>%
      datatable(selection = "single", options = list(searching = FALSE))
  })

  # render status bar
  output$barriersRowStatus <- renderText({
    row <- selectedBarriersRow()

    if (is.null(row)) {
      shinyjs::hide(id = "barriersRowButtons")
      return("Select a row to remove it or zoom in")
    }
    shinyjs::show(id = "barriersRowButtons")
    paste0("Selected barrier id: ", row$id[[1]])
  })

  # handle Zoom To button click
  observeEvent(input$barriersZoomToRow, {
    row <- selectedBarriersRow()
    map <- leafletProxy("barriersMap")

    flyTo(map, lng = row$lon[[1]], lat = row$lat[[1]], zoom = 16)
  })

  # handle Remove button click
  observeEvent(input$barriersRemoveRow, {
    row <- selectedBarriersRow()
    id <- row$id[[1]]

    values$selectedBarrierIds <- values$selectedBarrierIds[-which(values$selectedBarrierIds == id)]
  })

  # handle map click (select/unselect barriers)
  observeEvent(input$barriersMap_shape_click, {
    id <- input$barriersMap_shape_click$id

    if (id %in% values$selectedBarrierIds) {
      values$selectedBarrierIds <- values$selectedBarrierIds[-which(values$selectedBarrierIds == id)]
    } else {
      values$selectedBarrierIds <- c(values$selectedBarrierIds, id)
    }
  })

  # update map with selected barriers
  observeEvent(values$selectedBarrierIds, {
    x <- selectedBarriers()

    m <- leafletProxy("barriersMap")

    m %>% clearGroup(group = "selected")

    # clear model results
    values$modelResults <- NULL

    if (is.null(x)) return()

    m %>%
      addCircles(
        data = x,
        group = "selected",
        layerId = ~ id,
        lng = ~ lon,
        lat = ~ lat,
        color = "red",
        fillOpacity = 1,
        highlightOptions = highlightOptions(
          color = "red",
          weight = 6,
          bringToFront = TRUE
        )
      )
  })

  # debug
  output$barriersDebug <- renderText({
    if (is.null(values$barriers)) {
      return("Barriers have not been loaded")
    }
    paste0(
      "# Barriers: ", nrow(values$barriers), "\n",
      "# Selected: ", length(values$selectedBarrierIds), "\n",
      "Model Results Exist? ", !is.null(values$modelResults)
    )
  })

  # next button -> tab-model
  observeEvent(input$barriersNextBtn, {
    df <- selectedBarriers() %>%
      select(id, x = x_coord, y = y_coord)

    if (nrow(df) > 0) {
      values$modelResults <- graph.linkages(df, source = config$tiles$dir, chatter = FALSE)
      values$modelResults$data <- df
    } else {
      values$modelResults <- NULL
    }

    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-model"
    )
  })


  # model tab ---------------------------------------------------------------

  # enable/disable Step 3 tab
  observe({
    if (!is.null(values$modelResults)) {
      shinyjs::enable(selector = "#nav > li:nth-child(4)")
    } else {
      shinyjs::disable(selector = "#nav > li:nth-child(4)")
    }
  })

  # render model results text
  output$modelResults <- renderText({
    output <- values$modelResults
    if (is.null(output)) {
      return("No results")
    }
    elapsed <- output$elapsed
    results <- output$results
    paste0(
      "# Barriers = ", nrow(output$data), "\n",
      "Delta = ", results$delta, "\n",
      "Effect = ", results$effect, "\n",
      "Elapsed Time = ", format(elapsed, digits = 2), " sec"
    )
  })


  # prev button -> tab-barriers
  observeEvent(input$modelPrevBtn, {
    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-barriers"
    )
  })
}

shinyApp(ui, server)
