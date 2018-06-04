library(shiny)
library(jsonlite)

config <- read_json("../config.json")

for (f in list.files(path = "../functions")) {
  source(file.path("../functions", f))
}

culv <- read.csv("../demo/culv.csv")

ui <- fluidPage(
  titlePanel("Critical Linkages Scenario Builder"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        inputId = "n_culv",
        label = "Number of crossings:",
        min = 1,
        max = nrow(culv),
        step = 1,
        value = nrow(culv)
      )
    ),
    mainPanel(
      verbatimTextOutput(outputId = "text")
    )
  )
)

server <- function(input, output) {
  culvSubset <- reactive({
    culv[1:input$n_culv, c("x", "y")]
  })
  output$text <- renderText({
    culv <- culvSubset()
    x <- graph.linkages(culv, source = config$tiles$dir, chatter = FALSE)
    paste0(
      "N = ", nrow(culv), "\n",
      "Delta = ", x$results$delta, "\n",
      "Effect = ", x$results$effect, "\n",
      "(Elapsed Time = ", format(x$elapsed, digits = 2), " sec)"
    )
  })
}

shinyApp(ui, server)
