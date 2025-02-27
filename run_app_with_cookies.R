source("C:/Users/Farid Azouaou/Downloads/initializer.R")
library(dive2ml)
init_envs_cluster()
source("C:/TEMP/thaink2/th2shinymanager/cookies_based_auth.R")
source("C:/TEMP/thaink2/th2shinymanager/dive2ml_server_authr.R")
ml_dir <<- "cokiiies"
list()%>%
  jsonlite::write_json("data.json")
options(shiny.http.response.filter = post_handler)
ui_with_cookies <- cookies::add_cookie_handlers(dive2ml_ui_auth)
shinyApp(ui_with_cookies, protected_server, options = list("launch.browser" = T, port = 3838))
