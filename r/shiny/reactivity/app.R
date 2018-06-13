library(shiny)
library(shinyjs)

cat("-------------------------------------------------\n")

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Reactivity"),
  fluidRow(
    column(
      width = 12,
      textInput("a", label = "input$a", value = "A"),
      hr(),
      h4("reactive() vs. eventReactive()"),
      verbatimTextOutput("text_a"),
      verbatimTextOutput("text_a_event_a"),
      verbatimTextOutput("text_a_reactive"),
      actionButton("go1", "go1"),
      verbatimTextOutput("text_a_event_go1"),
      hr(),
      h4("reactiveValues"),
      verbatimTextOutput("text_rv_observe"),
      actionButton("go2", "go2"),
      verbatimTextOutput("text_rv_observeEvent_go2"),
      actionButton("go3", "go3 (observe=NULL)")

    )
  )
)

server <- function(input, output, session) {


  # reactive values ---------------------------------------------------------

  # values <- reactiveValues(action = NULL, reactive = NULL, observe = NULL, observeEvent = NULL, eventReactive = NULL)
  values <- reactiveValues(observe = NULL, observeEvent_go2 = NULL)

  # same as reactive({input$a})
  text_a_event_a <- eventReactive(input$a, {
    input$a
  })

  # only fires on click:go1
  text_a_event_go1 <- eventReactive(input$go1, {
    # fires only when go1 clicked
    input$a
  })

  text_a_reactive <- reactive({ input$a })

  # render ------------------------------------------------------------------

  output$text_a <- renderText({
    paste0("renderText({input$a}): ", input$a)
  })

  output$text_a_event_a <- renderText({
    paste0("eventReactive(input$a): ", text_a_event_a(), sep = "")
  })

  output$text_a_event_go1 <- renderText({
    paste0("eventReactive(input$go1): ", text_a_event_go1(), sep = "")
  })

  output$text_a_reactive <- renderText({
    paste0("reactive({input$a}): ", text_a_reactive(), sep = "")
  })

  output$text_rv_observe <- renderText({
    paste0("values$observe: ", values$observe, sep = "")
  })

  output$text_rv_observeEvent_go2 <- renderText({
    paste0("values$observeEvent_go2: ", values$observeEvent_go2, sep = "")
  })

#
#   observeEvent(input$a, {
#     values$observeEvent <- input$a
#   })
#
#   observe({
#     values$observe <- input$a
#   })
#
#   values$reactive <- reactive({
#     input$a
#   })
#   values$eventReactive <- eventReactive(input$go1, {
#     input$a
#   })


  # reactive values ---------------------------------------------------------

  observe({
    values$observe <- input$a
  })

  observeEvent(input$go2, {
    values$observeEvent_go2 <- input$a
  })

  observeEvent(input$go3, {
    values$observe <- NULL
  })

  # observers ---------------------------------------------------------------

  observe({
    cat("observe(input$a)", input$a,"\n")
  })

  observe({
    cat("observe(text_a_reactive())", text_a_reactive(), "\n")
  })

  observeEvent(input$a, {
    cat("observeEvent(input$a)", input$a, "\n")
  })

  observeEvent(text_a_event_a(), {
    cat("observeEvent(text_a_event_a())", text_a_event_a(), "\n")
  })

  observeEvent(text_a_event_go1(), {
    cat("observeEvent(text_a_event_go1())", text_a_event_go1(), "\n")
  })

  observeEvent(text_a_reactive(), {
    cat("observeEvent(text_a_reactive())", text_a_reactive(), "\n")
  })

  # need ignoreNULL = FALSE to observe a null set
  observeEvent(values$observe, {
    cat("observeEvent(values$observe)", values$observe, "\n")
  }, ignoreNULL = FALSE)

  observeEvent(values$observeEvent_go2, {
    cat("observeEvent(values$observeEvent_go2)", values$observeEvent_go2, "\n")
  })
}

shinyApp(ui, server)
