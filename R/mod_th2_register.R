#' @export
signup_ui <- function(id, status = "primary", tags_top = NULL, tags_bottom = NULL, lan = NULL, ...) {
  ns <- NS(id)
  if (is.null(lan)) {
    lan <- th2shinymanager::use_language()
  }
  tagList(
    singleton(tags$head(
      tags$link(href = "shinymanager/styles-auth.css", rel = "stylesheet"),
      tags$script(src = "shinymanager/bindEnter.js")
    )),
    tags$div(
      id = ns("signup-mod"),
      class = "panel-auth",
      tags$br(),
      tags$div(style = "height: 70px;"),
      tags$br(),
      fluidRow(
        column(
          width = 4,
          offset = 4,
          tags$div(
            class = paste0("panel panel-", status),
            tags$div(
              class = "panel-body",
              tags$div(
                style = "text-align: center;",
                if (!is.null(tags_top)) tags_top,
                tags$h3(lan$get("Create your account"), id = ns("shinymanager-signup-head"))
              ),
              tags$br(),
              textInput(
                inputId = ns("new_user_id"),
                label = lan$get("Email:"),
                width = "100%"
              ),
              passwordInput(
                inputId = ns("new_user_pwd"),
                label = lan$get("Password:"),
                width = "100%"
              ),
              passwordInput(
                inputId = ns("confirm_user_pwd"),
                label = lan$get("Confirm Password:"),
                width = "100%"
              ),
              tags$br(),
              tags$div(
                id = ns("container-btn-signup"),
                uiOutput(ns("create_user_btn")),
                tags$br(),
                tags$br()
              ),
              tags$br(),
              tags$script(sprintf("bindEnter('%s');", ns(""))),
              tags$div(id = ns("result_signup")),
              if (!is.null(tags_bottom)) tags_bottom
            )
          )
        )
      )
    )
  )
}

#' @export
signup_server <- function(id, parent_session, lan = NULL, project_configs = "th2coldorg") {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    if (is.null(lan)) {
      lan <- reactiveVal(th2shinymanager::use_language())
    } else {
      lan <- reactiveVal(lan)
    }

    output$create_user_btn <- renderUI({
      req(input$new_user_id)
      if (th2utils::is_valid_email(input$new_user_id)) {
        actionButton(
          inputId = ns("go_signup"),
          label = "s'inscrire",
          width = "100%",
          class = "btn-primary"
        )
      }
    })

    observeEvent(input$go_signup, {
      removeUI(selector = paste0("#", ns("msg_signup")))
      insertUI(
        selector = paste0("#", ns("container-btn-signup")),
        ui = tags$div(
          id = ns("spinner_msg_signup"),
          img(src = "shinymanager/1497.gif", style = "height:30px;"),
          align = "center"
        ),
        immediate = TRUE
      )

      if (is.null(input$new_user_id) || input$new_user_id == "" ||
        is.null(input$new_user_pwd) || input$new_user_pwd == "" ||
        is.null(input$confirm_user_pwd) || input$confirm_user_pwd == "") {
        insertUI(
          selector = paste0("#", ns("result_signup")),
          ui = tags$div(
            id = ns("msg_signup"),
            class = "alert alert-danger",
            icon("triangle-exclamation"),
            lan()$get("All fields are required")
          )
        )
      } else if (input$new_user_pwd != input$confirm_user_pwd) {
        insertUI(
          selector = paste0("#", ns("result_signup")),
          ui = tags$div(
            id = ns("msg_signup"),
            class = "alert alert-danger",
            icon("triangle-exclamation"),
            lan()$get("Passwords do not match")
          )
        )
      } else {
        current_data <- th2product::fetch_data_from_db(table = "credentials")
        current_data <- current_data %>%
          dplyr::select(
            username
          )
        if (input$new_user_id %in% current_data$username) {
          print("Condition Same Username trigg")
          res_signup <- list(result = FALSE, message = "Username already exists")
        } else {
          new_data <-
            data.frame(
              username = input$new_user_id,
              password = input$new_user_pwd,
              start_time = as.Date(Sys.Date()),
              expire_time = as.Date(Sys.Date() + 365),
              applications = get_appname(),
              is_admin = FALSE
            )
          config_path <- system.file("sql_config/pg_template.yml", package = project_configs)
          config_db <- tryCatch(
            {
              yaml::yaml.load_file(config_path, eval.expr = TRUE)
            },
            error = function(e) stop("Error reading 'config_path' SQL DB configuration :", e$message)
          )
          verify_sql_config(config_db)

          write_sql_pg_db(
            config_db = config_db,
            value = new_data,
            name = config_db$tables$credentials$tablename
          )

          write_sql_pg_db(
            config_db = config_db,
            value = data.frame(
              username = new_data$username,
              must_change = FALSE,
              have_changed = FALSE,
              date_change = Sys.Date(),
              n_wrong_pwd = 0,
              stringsAsFactors = FALSE
            ),
            name = config_db$tables$pwd_mngt$tablename
          )

          print("res_signup result = TRUE trigg")
          res_signup <- list(result = TRUE, message = "Account created successfully")
        }

        if (isTRUE(res_signup$result)) {
          th2product::th_shinyalert(
            title = lan()$get("Success"),
            text = lan()$get(res_signup$message),
            type = "success"
          )

          removeUI(selector = paste0("#", ns("signup-mod")))
        } else {
          insertUI(
            selector = paste0("#", ns("result_signup")),
            ui = tags$div(
              id = ns("msg_signup"),
              class = "alert alert-danger",
              icon("triangle-exclamation"),
              lan()$get(res_signup$message)
            )
          )
        }
      }
      removeUI(selector = paste0("#", ns("spinner_msg_signup")))
    })
  })
}
