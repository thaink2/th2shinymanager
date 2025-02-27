library(cookies)
library(shiny)

# Wrap your ui with add_cookie_handlers() to enable cookies.
ui <- add_cookie_handlers(
  fluidPage(
    titlePanel("A Simple App"),
    fluidRow(
      sliderInput(
        "number_selector",
        label = paste(
          "Select a number.",
          "This selector sets the cookie value.",
          "It also initializes with the cookie value.",
          "Refresh to see it remembered.",
          sep = "\n"
        ),
        min = 1,
        max = 10,
        value = 1
      ),
      sliderInput(
        "number_selector_no_cookie",
        label = paste(
          "Select a number.",
          "This one is not connected to the cookie.",
          "When you refresh, it will always initialize to 1.",
          sep = "\n"
        ),
        min = 1,
        max = 10,
        value = 1
      )
    )
  )
)

server <- function(input, output, session) {
  # When the value changes, set a cookie.
  observeEvent(
    input$number_selector,
    {
      set_cookie(
        cookie_name = "selected_number",
        cookie_value = input$number_selector
      )
    }
  )
  
  # Initialize the top slider from any cookies that come in at the start.
  observeEvent(
    get_cookie("selected_number"),
    updateSliderInput(
      inputId = "number_selector",
      value = get_cookie("selected_number")
    ),
    once = TRUE
  )
}

shinyApp(
  ui,
  server,
  # Cookies only work in an actual browser.
  options = list(
    launch.browser = TRUE
  )
)