library(tidyverse)
library(shiny)
library(shinyjs)
library(leaflet)
library(DT)
library(jsonlite)
library(pool)
library(DBI)

config <- read_json("../config.json")
huc8 <- readRDS("../rds/huc8.rds")
singleScores <- readRDS("../rds/crossings-scores.rds")

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

loadCrossings <- function(huc8) {
  cat("loadCrossings(", huc8, ")\n", sep = "")

  if (is.null(huc8) || length(huc8) == 0) {
    stop(paste0("Failed to load crossings for huc8: ", huc8))
  }

  sql <- "select c.id, c.x_coord, c.y_coord, c.lon, c.lat from crossings_huc ch left join crossings c on ch.crossing_id=c.id where ch.huc8=$1";
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
        p("The Critical Linkages Scenario Builder is a dynamic web application for evaluating the impact of stream crossing restoration across the Northeast US"),
        h3("Instructions"),
        tags$ol(
          tags$li("Select Watershed: select your target watershed (HUC8)"),
          tags$li("Select Crossings: select one or more stream crossings within the target watershed"),
          tags$li("Run Model: run the model to calculate the overall connectivity impacts due to restoration/removal of the selected crossings")
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
            actionButton(inputId = "watershedNextBtn", label = "Next: Load Crossings >>", class = "btn-success")
          )
        ),

        hr(),
        h4("Debug"),
        verbatimTextOutput("watershedDebug")
      )
    ),
    tabPanel(
      title = "Step 2: Select Crossings",
      value = "tab-crossings",
      class = "disabled",
      column(
        width = 6,
        h2("Select Stream Crossings"),
        p("Select one or more stream crossings to evaluate for restoration/removal. Then click the \"Run Model\" button to calculate the overall change in aquatic connectivity."),
        leafletOutput(outputId = "crossingsMap"),
        hidden(
          div(
            id = "crossingsTableDiv",
            hr(),
            actionButton(inputId = "crossingsNextBtn", label = "Next: Run Model >>", class = "pull-right btn-success"),
            DTOutput(outputId = "crossingsTable"),
            strong(textOutput("crossingsRowStatus")),
            hidden(
              div(
                id = "crossingsRowButtons",
                actionButton(inputId = "crossingsRemoveRow", label = "Remove"),
                actionButton(inputId = "crossingsZoomToRow", label = "Zoom To")
              )
            )
          )
        ),

        hr(),
        h4("Debug"),
        verbatimTextOutput(outputId = "crossingsDebug"),
        verbatimTextOutput(outputId = "crossingsDebugRow")
      )
    ),
    tabPanel(
      title = "Step 3: Model Results",
      value = "tab-model",
      column(
        width = 6,
        h2("Model Results"),
        verbatimTextOutput(outputId = "modelResults"),
        plotOutput(outputId = "modelHistDelta"),
        plotOutput(outputId = "modelHistEffect"),
        actionButton(inputId = "modelPrevBtn", label = "<< Prev: Select Crossings", class = "btn-success")
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
    selectedCrossingIds = integer(),   # crossing ids as integer vector
    selectedHuc8Id = character(),      # selected huc8 id as character
    crossings = NULL,                  # crossings data frame
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
    values$crossings <- NULL
    values$selectedCrossingIds <- integer()
    values$modelResults <- NULL
  })

  # next button -> tab-crossings
  observeEvent(input$watershedNextBtn, {
    values$crossings <- loadCrossings(values$selectedHuc8Id)
    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-crossings"
    )
  })


  # crossings tab----------------------------------------------------------

  # enable/disable Step 2 tab
  observe({
    if (length(values$selectedHuc8Id) > 0) {
      shinyjs::enable(selector = "#nav > li:nth-child(3)")
    } else {
      shinyjs::disable(selector = "#nav > li:nth-child(3)")
    }
  })

  # selected crossings data frame (from map)
  selectedCrossings <- reactive({
    if (length(values$selectedCrossingIds) == 0) {
      shinyjs::hide(id = "crossingsTableDiv")
      return(NULL)
    }

    shinyjs::show(id = "crossingsTableDiv")
    values$crossings %>%
      filter(id %in% values$selectedCrossingIds)
  })

  # selected crossing row (from table)
  selectedCrossingsRow <- reactive({
    sel <- input$crossingsTable_rows_selected

    if (length(sel) == 0) {
      return(NULL)
    }

    selectedCrossings()[sel, ]
  })

  # render initial map
  output$crossingsMap <- renderLeaflet({
    if (is.null(values$crossings)) return()

    leaflet(values$crossings) %>%
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
        group = "crossings",
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
  output$crossingsTable <- renderDT({
    selectedCrossings() %>%
      datatable(selection = "single", options = list(searching = FALSE))
  })

  # render status bar
  output$crossingsRowStatus <- renderText({
    row <- selectedCrossingsRow()

    if (is.null(row)) {
      shinyjs::hide(id = "crossingsRowButtons")
      return("Select a row to remove it or zoom in")
    }
    shinyjs::show(id = "crossingsRowButtons")
    paste0("Selected crossing id: ", row$id[[1]])
  })

  # handle Zoom To button click
  observeEvent(input$crossingsZoomToRow, {
    row <- selectedCrossingsRow()
    map <- leafletProxy("crossingsMap")

    flyTo(map, lng = row$lon[[1]], lat = row$lat[[1]], zoom = 16)
  })

  # handle Remove button click
  observeEvent(input$crossingsRemoveRow, {
    row <- selectedCrossingsRow()
    id <- row$id[[1]]

    values$selectedCrossingIds <- values$selectedCrossingIds[-which(values$selectedCrossingIds == id)]
  })

  # handle map click (select/unselect crossings)
  observeEvent(input$crossingsMap_shape_click, {
    id <- input$crossingsMap_shape_click$id

    if (id %in% values$selectedCrossingIds) {
      values$selectedCrossingIds <- values$selectedCrossingIds[-which(values$selectedCrossingIds == id)]
    } else {
      values$selectedCrossingIds <- c(values$selectedCrossingIds, id)
    }
  })

  # update map with selected crossings
  observeEvent(values$selectedCrossingIds, {
    cat("observeEvent(values$selectedCrossingIds)\n")
    x <- selectedCrossings()

    m <- leafletProxy("crossingsMap")

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
  output$crossingsDebug <- renderText({
    if (is.null(values$crossings)) {
      return("Crossings have not been loaded")
    }
    paste0(
      "# Crossings: ", nrow(values$crossings), "\n",
      "# Selected: ", length(values$selectedCrossingIds), "\n",
      "Model Results Exist? ", !is.null(values$modelResults)
    )
  })

  # next button -> tab-model
  observeEvent(input$crossingsNextBtn, {
    cat("Run model\n")

    df <- selectedCrossings() %>%
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
      "# Crossings = ", nrow(output$data), "\n",
      "Delta = ", results$delta, "\n",
      "Effect = ", results$effect, "\n",
      "Elapsed Time = ", format(elapsed, digits = 2), " sec"
    )
  })

  # render model delta histogram
  output$modelHistDelta <- renderPlot({
    output <- values$modelResults
    if (is.null(output)) return()

    singleScores %>%
      ggplot(aes(delta)) +
      geom_histogram(bins = 30) +
      geom_vline(
        aes(
          xintercept = output$results$delta,
          color = "Current\nScenario"
        )
      ) +
      scale_color_manual("", values = "red") +
      labs(
        x = "Delta",
        y = "# Crossings",
        title = "Histogram of Delta for All Crossings Targeted Individually",
        subtitle = "Vertical red line shows value of current scenario"
      )
  })

  # render model effect histogram
  output$modelHistEffect <- renderPlot({
    output <- values$modelResults
    if (is.null(output)) return()

    singleScores %>%
      ggplot(aes(effect)) +
      geom_histogram(bins = 30) +
      geom_vline(
        aes(
          xintercept = output$results$effect,
          color = "Current\nScenario"
        )
      ) +
      scale_color_manual("", values = "red") +
      labs(
        x = "Effect",
        y = "# Crossings",
        title = "Histogram of Effect for All Crossings Targeted Individually",
        subtitle = "Vertical red line shows value of current scenario"
      )
  })

  # prev button -> tab-crossings
  observeEvent(input$modelPrevBtn, {
    updateTabsetPanel(
      session = session,
      inputId = "nav",
      selected = "tab-crossings"
    )
  })
}

shinyApp(ui, server)
