library(shiny)

post_handler <- function(req, response) {
  # we'll catch everything that's POST for this demo but you'll want to make
  # sure you don't step on shiny's built-in POST handlers
  if (identical(req$REQUEST_METHOD, "POST")) {
    # you probably want to limit the upload file size w/ the first arg of $read()
    req2 <<- req
    data2 <<- req$rook.input$read()
    data <- jsonlite::fromJSON(rawToChar(data2))
    message(str(data))
    if (is.null(data$token) || is.null(data$name)) {
      # expect a token and a name for this demo but you'd want to do auth/routing here... 
      # if the request is bad return the base response of 404 not found
      return(response)
    } else {
      # update our local data store (or write to db etc)
      y <- list()
      y[[data$token]] <- data$name
      x <- utils::modifyList(read_json("data.json"), y, keep.null = TRUE)
      write_json(x, "data.json")
      # return all okay response!
      cookies::set_cookie_response("shinyauthr","test", redirect = "/")
      return(shiny:::httpResponse(200, "text/plain", "OK\n"))
    }
  }
  # return regular shiny response
  response
}

options(shiny.http.response.filter = post_handler)

ui <- add_cookie_handlers(fluidPage(
  h2("Hello", uiOutput("name", inline = TRUE, container = span))
))

server <- function(input, output, session) {
  # poll our data store (local json) for updates, using token as ID
  names_list <- reactiveFileReader(1000, session, "data.json", function(x) {
    read_json(x)
  })
  
  output$name <- renderUI({
    query <<- getQueryString()
    names_list2 <<-names_list()
    # if (!is.null(query$token) && query$token %in% names(names_list())) {
    #   paste0(names_list()[[query$token]],"!")
    # } else {
    #   "..." 
    # }
    cookies::set_cookie(cookie_name = "shinyauthr",names_list2$test[[1]])
    names_list2$test[[1]]
  })
}

shinyApp(ui, server, options = list("launch.browser" = T, port = 3838))
