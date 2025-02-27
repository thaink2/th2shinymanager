dive2ml_ui_auth <- function(request){
  tagList(
    # add logout button UI
    # div(class = "pull-right", shinyauthr::logoutUI(id = "logout")),
    # add login panel UI function
    shinyauthr::loginUI(id = "login", cookie_expiry = cookie_expiry),
    # Add table output to show user info after login
    bs4Dash::bs4DashPage(
      options = list(sidebarExpandOnHover = TRUE),
      fullscreen = FALSE,
      scrollToTop  = TRUE,
      dark = NULL,
      help = NULL,
      freshTheme = readRDS(system.file("app/www/fairml_theme.rds", package = "dive2ml")),
      header = th2utils::prepare_app_header(header_title = "Dive2ML"),
      # preloader = ifelse(with_spinner,list(html = tagList(waiter::spin_clock(), "Loading ..."), color = "#013DFF"),FALSE),
      title = "Dive2ML",
      sidebar = bs4Dash::bs4DashSidebar(
        id = "sidebarID",
        minified = TRUE, collapsed = TRUE,
        bs4Dash::bs4SidebarMenu(
          id = "sidebarMenuID",
          bs4Dash::menuItem("Platform", tabName = "platform_board", icon = th2utils::icon("tower-observation", fill = "#013DFF")),
          bs4Dash::menuItem("Data Preparation",
                            bs4Dash::menuSubItem("Data Blender", icon = shiny::icon("blender"), tabName = "data_blender"),
                            # bs4Dash::menuSubItem("Data Quality", icon = shiny::icon("list-check"), tabName = "th2_data_quality"),
                            startExpanded = TRUE, tabName = "data_preparation", icon = th2utils::icon("database", fill = "#013DFF")
          ),
          bs4Dash::menuItem("Insights & BI",
                            bs4Dash::menuSubItem("Insights", icon = th2utils::icon(name = "chart-area", fill = NULL),
                                                 tabName = "data_insights"),
                            bs4Dash::menuSubItem("BI & Reporting", icon = icon("file-lines"), tabName = "bi_and_reporting"),
                            startExpanded = TRUE, tabName = "insights_and_bi", icon = th2utils::icon("lightbulb", fill = "#013DFF")
          ),
          bs4Dash::menuItem("ML Engine",
                            bs4Dash::menuSubItem("AutoML", icon = shiny::icon("screwdriver-wrench"), tabName = "auto_ml"),
                            bs4Dash::menuSubItem(subitem_with_badge("Forecasting","new","success"), icon = shiny::icon("arrow-trend-up"), tabName = "portfolio_forecast"),
                            bs4Dash::menuSubItem(subitem_with_badge("LLM","beta","warning"), icon = shiny::icon("text-width"), tabName = "portfolio_llms"),
                            startExpanded = TRUE, tabName = "ML_model_build", icon = th2utils::icon("brain", fill = "#013DFF")
          ),
          bs4Dash::menuItem("ML Ops",
                            bs4Dash::menuSubItem("ML APPs & APIs", icon = shiny::icon("mobile-screen"), tabName = "ml_deployer_app"),
                            startExpanded = FALSE, tabName = "ML_deployment", icon = th2utils::icon("industry", fill = "#013DFF")
          ),
          bs4Dash::menuItem("Pipelines",
                            bs4Dash::menuSubItem("Overview", icon = shiny::icon("eye"), tabName = "ml_workflow_orch_overview"),
                            bs4Dash::menuSubItem("Data", icon = shiny::icon("table"), tabName = "ml_workflow_orch_data"),
                            bs4Dash::menuSubItem("Machine Learning", icon = shiny::icon("brain"), tabName = "ml_workflow_orch_ml"),
                            bs4Dash::menuSubItem("Forecast", icon = shiny::icon("arrow-trend-up"), tabName = "ml_workflow_orch_forecast"),
                            startExpanded = FALSE, tabName = "all_pipelines", icon = th2utils::icon("timeline", fill = "#013DFF")
          ),
          bs4Dash::menuItem("Admin",
                            bs4Dash::menuSubItem("Users", icon = shiny::icon("users"), tabName = "th2users"),
                            startExpanded = FALSE, tabName = "dev_lab", icon = th2utils::icon("gears", fill = "#013DFF")
          )
        )
      ),
      controlbar = bs4Dash::dashboardControlbar(
        collapsed = TRUE,
        bs4Dash::controlbarMenu(
          bs4Dash::controlbarItem(title = "",th2ml::mod_manage_ml_projects_ui("manage_ml_projects_1"),icon = icon("folder"))        )
      ),
      
      body = bs4Dash::dashboardBody(
        includeCSS(system.file("custom_icon.css", package = "th2blender")),
        # info about the app
        shiny.info::info_panel(
          shiny.info::powered_by("thaink²", link = "https://www.thaink2.com/"),
          position = "bottom right"
        ),
        shinybusy::add_busy_spinner(spin = "cube-grid", position = "bottom-left", color = "#013DFF"),
        # router UI 
        bs4Dash::tabItems(
          bs4Dash::tabItem(
            tabName = "platform_board",
            dive2ml::th2_landing_page_ui("th2analytics")
          ),
          bs4Dash::tabItem("data_blender",
                           bs4Dash::tabBox(width = 12, title = "Data Import", id  = "data_preprocessing", selected = "Data Pool",
                                           tabPanel(
                                             title = "Data Upload", icon = icon("upload"),
                                             th2blender::tk2_dataconnector_ui("dataconnector")
                                           ),
                                           tabPanel(
                                             title = "Data Pool", icon = icon("database"),                      
                                             th2blender::mod_data_cards_ui("data_cards_1")
                                           ))
          ),
          # bs4Dash::tabItem(tabName = "th2_data_quality", 
          #                  th2blender::mod_data_quality_check_ui(id = "th2data_quality")
          # ),
          bs4Dash::tabItem("data_insights",
                           bs4Dash::tabBox(width = 12,
                                           tabPanel(
                                             title = "Import & View",
                                             icon = icon("eye"),
                                             th2blender::mod_th2_load_data_ui(id = "raw_data")
                                           ),
                                           tabPanel(
                                             title = "Explore",
                                             icon = icon("magnifying-glass-chart"),
                                             th2reporting::SA_tisefka_UI("multiple_view")
                                           ),
                                           tabPanel(
                                             title = "Aggregate",
                                             icon = icon("superscript"),
                                             th2reporting::SA_tisefka_aggregator_UI("time_aggregator")
                                           ),
                                           tabPanel(
                                             title = "Data Explorer",    
                                             icon = icon("binoculars"),
                                             th2reporting::th2_data_aggregator_ui("data_explorer")
                                           ))
          ),
          bs4Dash::tabItem("bi_and_reporting",
                           bs4Dash::tabBox(width = 12,
                                           tabPanel(
                                             title = "my Reports",
                                             icon = icon("display"),
                                             th2reporting::mod_S3_reports_ui(id = "s3_report")
                                           ),
                                           tabPanel(
                                             title = "Report Settings",
                                             icon = icon("bolt"),
                                             th2reporting::dnd_report_add_section_ui(id = "thaink2_reporting")
                                           ),
                                           tabPanel(
                                             title = "Custom Reports",
                                             icon = icon("fan"),
                                             th2reporting::generate_report_from_rmd_ui("th2")
                                           ),
                                           tabPanel(
                                             title = "Web Apps",
                                             icon = icon("flask"),
                                             th2appstudio::mod_th2webapp_server_ui("th2webapp_server_1")
                                           )
                           )
          ),
          bs4Dash::tabItem("auto_ml",
                           bs4Dash::tabBox(id = "fe_tabbox",width = 12,
                                           tabPanel(
                                             title = shiny::tags$div(shiny::icon("microchip"),"Features Engineering",
                                                                     `data-bs-toggle` = "tooltip", 
                                                                     `data-bs-placement` = "top", 
                                                                     title = "Generate features"),
                                             th2ml::SA_ML_features_UI("SA_ML_features")
                                           ),
                                           tabPanel(
                                             title = shiny::tags$div(shiny::icon("wrench"),"Processing",
                                                                     `data-bs-toggle` = "tooltip", 
                                                                     `data-bs-placement` = "top", 
                                                                     title = "Train and save ML Model"),
                                             th2ml::SA_ML_preprocessing_UI("SA_ML_engine")
                                           ),
                                           tabPanel(
                                             title = shiny::tags$div(shiny::icon("list"),"ML models", 
                                                                     `data-bs-toggle` = "tooltip", 
                                                                     `data-bs-placement` = "top", 
                                                                     title = "Manage saved models"),
                                             th2ml::mod_ml_model_card_ui("model_cards_2")
                                           ),
                                           tabPanel(
                                             title = "explAInables"
                                           )
                                           
                           )
                           
          ),
          bs4Dash::tabItem("portfolio_forecast",
                           bs4Dash::tabBox(width = 12, 
                                           tabPanel(
                                             title = "Click & Forecast", icon = icon("ellipsis"),
                                             th2forecast::forecast_train_mod_ui2("fcast_by_kpis")
                                           ))
          ),
          bs4Dash::tabItem(tabName = "portfolio_llms",
                           th2ml::mod_th2llm_ui("th2llm")
          ),
          
          bs4Dash::tabItem("ml_deployer_app",
                           bs4Dash::tabBox(width = 12, title = "Build ML App",
                                           tabPanel(
                                             title = "ML Apps", icon = icon("mobile"),
                                             th2ml::mod_ml_app_card_ui("th2_ml_apps")
                                           ),
                                           tabPanel(
                                             title = "ML APIs", icon = icon("paper-plane"),
                                             th2ml::mod_ml_api_endpoint_card_ui("th2endpoints")
                                           )
                           )
                           
          ),
          bs4Dash::tabItem("ml_workflow_orch_overview",
                           th2mageai::mod_th2mage_pipeline_generator_ui("th2mage_overview")
          ),
          bs4Dash::tabItem("ml_workflow_orch_data",
                           th2mageai::mod_th2mage_ui("th2mage_data")
          ),
          bs4Dash::tabItem("ml_workflow_orch_forecast", 
                           th2mageai::mod_th2mage_ui("th2mage_fc"),
                           th2forecast::mod_forecasting_viewer_ui("th2forecast")
          ),
          bs4Dash::tabItem("ml_workflow_orch_ml",
                           th2mageai::mod_th2mage_ui("th2mage_ml")
                           
          ),
          bs4Dash::tabItem("th2users",
                           th2utils::user_acces_manager_ui(id = "manager_users")
          )
        )
      )
    )
  )
}

#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @noRd

dive2ml_server_auth <- function(input, output,session) {
  options(shiny.maxRequestSize=1000000*1024^2) 
  #initialization
  initialize_helper()
  th2utils::get_httr_headers(session = session)
  # th2ml::app_translator_server("fairml_lang")
  names_list <- reactiveFileReader(1000, session, "data.json", function(x) {
    jsonlite::read_json(x)
  })
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
  # output$th2platform <- renderUI({
  #   # req(credentials()$info$user)
  #   req(names_list())
  #   names_list2 <<- names_list()
  #   if(is.null(names_list()$shinyauthr))return(NULL)
  #   print(names_list()$shinyauthr)
  #   cookies::set_cookie(cookie_name = "shinyauthr",names_list()$shinyauthr)
  #   print("I am here")
  #   req(credentials()$user_auth)
  #   # dive2ml::th2_landing_page_ui("th2analytics")
  # })
  observeEvent(names_list(),{
    names_list2 <<- names_list()
    if(is.null(names_list()$shinyauthr)){
      return(NULL)
    }
    print(names_list()$shinyauthr)
    cookies::set_cookie(cookie_name = "shinyauthr",names_list()$shinyauthr)
    print("I am here")
    req(credentials()$user_auth)
    #================= Board
    dive2ml::th2_landing_page_server("th2analytics", parent_session = session)
    
    #================== Admin =========================
    th2ml::mod_manage_ml_projects_server(id = "manage_ml_projects_1")
    th2utils::user_acces_manager_server(id = "manager_users")
    mod_user_profile_server("th2profile")
    #================== Data Blender ==================
    th2reporting::th2_data_aggregator_server("data_explorer")
    
    # th2utils::mod_thaink2_chat_server("th2chat_1")
    
    # Data Connector
    th2blender::tk2_dataconnector_server("dataconnector")
    # data quality
    # Machine Learning
    tisefka_inu <- callModule(module = th2ml::SA_ML_features_server, id = "SA_ML_features")
    # th2ml::mod_th2features_khiops_server("th2features_khiops_1")
    ML_trained_results <- callModule(module = th2ml::SA_ML_preprocessing_server, id = "SA_ML_engine", tisefka = tisefka_inu)
    # ========= insights and BI ====
    fv_tisefka <- th2blender::mod_th2_load_data_server(id = "raw_data")
    callModule(
      module = th2reporting::SA_tisefka_mod, id = "multiple_view",
      i18n = i18n, tisefka = fv_tisefka)
    
    callModule(
      module = th2reporting::SA_tisefka_aggregator_mod, id = "time_aggregator",
      i18n = NULL, tisefka = fv_tisefka)
    #------ Reporting Pool
    refresh_report <- reactiveVal(0)
    refresh_contents <- reactiveVal(0)
    th2reporting::dnd_report_add_section_server(id = "thaink2_reporting")
    th2reporting::generate_report_from_rmd_server("th2", refresh_report = refresh_report, parent_session = session)
    th2reporting::mod_S3_reports_server("s3_report", refresh_report = refresh_report)
    # ========== Machine Learning and AI ====
    
    # load model and data meta data and permissions at start
    th2blender::mod_data_cards_server("data_cards_1", user_init = user_init())
    th2ml::mod_ml_model_card_server("model_cards_2")
    th2ml::mod_ml_api_endpoint_card_server("th2endpoints")
    
    # ===== time series forecasting ======
    th2forecast::mod_forecasting_viewer_server("th2forecast")
    th2forecast::forecast_train_mod_server2("fcast_by_kpis")
    # Workflows/Orchestrator
    th2mageai::mod_th2mage_pipeline_generator_server("th2mage_overview")
    th2mageai::mod_th2mage_server("th2mage_data", target_wf = "data")
    th2mageai::mod_th2mage_server("th2mage_ml", target_wf = "ml")
    th2mageai::mod_th2mage_server("th2mage_fc", target_wf = "fc")
    
    # explainables
    # ML Apps modules
    th2ml::mod_ml_app_card_server("th2_ml_apps")
    # web Apps (shiny,flask,streamlit :  dev & deployer)
    th2appstudio::mod_th2webapp_server_server("th2webapp_server_1")
    # LLMs
    th2ml::mod_th2llm_server("th2llm")
  })
  
  
 
}
