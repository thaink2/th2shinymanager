library(shiny)
library(dplyr)
library(lubridate)
library(DBI)
library(RSQLite)

# connect to, or setup and connect to local SQLite db
if (file.exists("my_db_file")) {
  db <- dbConnect(SQLite(), "my_db_file")
} else {
  db <- dbConnect(SQLite(), "my_db_file")
  dbCreateTable(db, "sessionids", c(user = "TEXT", sessionid = "TEXT", login_time = "TEXT"))
}

# a user who has not visited the app for this many days
# will be asked to login with user name and password again
cookie_expiry <- 7 # Days until session expires

# This function must accept two parameters: user and sessionid. It will be called whenever the user
# successfully logs in with a password.  This function saves to your database.

add_sessionid_to_db <- function(user, sessionid, conn = db) {
  tibble(user = user, sessionid = sessionid, login_time = as.character(now())) %>%
    dbWriteTable(conn, "sessionids", ., append = TRUE)
}

# This function must return a data.frame with columns user and sessionid  Other columns are also okay
# and will be made available to the app after log in as columns in credentials()$user_auth

get_sessionids_from_db <- function(conn = db, expiry = cookie_expiry) {
  dbReadTable(conn, "sessionids") %>%
    mutate(login_time = ymd_hms(login_time)) %>%
    as_tibble() %>%
    filter(login_time > now() - days(expiry))
}

# dataframe that holds usernames, passwords and other user data
user_base <- tibble::tibble(
  user = c("user1", "user2"),
  password = c("pass1", "pass2"),
  permissions = c("admin", "standard"),
  name = c("User One", "User Two")
)
post_handler <- function(req, response,session) {
  # we'll catch everything that's POST for this demo but you'll want to make
  # sure you don't step on shiny's built-in POST handlers
  if (identical(req$REQUEST_METHOD, "POST")) {
    # you probably want to limit the upload file size w/ the first arg of $read()
    data <- req$rook.input$read()
    data <- jsonlite::fromJSON(rawToChar(data))
    message(str(data))
    if (is.null(data$email)) {
      # expect a token and a name for this demo but you'd want to do auth/routing here... 
      # if the request is bad return the base response of 404 not found
      return(response)
    } else {
      # update our local data store (or write to db etc)
      y <- list()
      x <- utils::modifyList(jsonlite::read_json("data.json"), y, keep.null = TRUE)
      x$shinyauthr <- get_sessionids_from_db()%>%
        dplyr::filter(user == !!data$email)%>%
        dplyr::pull(sessionid)%>%tail(1)
      x$user_mail <- data$email
      x$creation_time <- Sys.time()
      jsonlite::write_json(x, "data.json")
      # return all okay response!
      # cookies::set_cookie("shinyauthr","tes",session)
      return(shiny:::httpResponse(200, "text/plain", "OK\n"))
    }
  }
  # return regular shiny response
  response
}

protected_ui <- function(request){
  tagList(
    # add logout button UI
    div(class = "pull-right", shinyauthr::logoutUI(id = "logout")),
    # add login panel UI function
    shinyauthr::loginUI(id = "login", cookie_expiry = cookie_expiry),
    # Add table output to show user info after login
    uiOutput("th2platform")
  )
}

protected_server <- function(input, output, session) {
  names_list <- reactiveFileReader(1000, session, "data.json", function(x) {
    jsonlite::read_json(x)
  })
  
  output$th2platform <- renderUI({
    req(names_list())
    names_list2 <<- names_list()
    if(is.null(names_list()$shinyauthr))return(NULL)
    cookies::set_cookie(cookie_name = "shinyauthr",names_list()$shinyauthr)
    req(credentials()$user_auth)
    print("aqli dagiii")
    dive2ml::th2_landing_page_ui("th2analytics")
  })
  
  dive2ml::th2_landing_page_server("th2analytics", parent_session = session)
  
  logout_init <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
  
  # call login module supplying data frame, user and password cols
  # and reactive trigger
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    cookie_logins = TRUE,
    sessionid_col = sessionid,
    cookie_getter = get_sessionids_from_db,
    cookie_setter = add_sessionid_to_db,
    log_out = reactive(logout_init())
  )
  
  # pulls out the user information returned from login module
  user_data <- reactive({
    credentials()$info
  })
  
  output$user_table <- renderTable({
    # use req to only render results when credentials()$user_auth is TRUE
    req(credentials()$user_auth)
    user_data() %>%
      mutate(across(starts_with("login_time"), as.character))
  })
}

#==============
