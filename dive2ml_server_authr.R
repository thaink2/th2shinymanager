dive2ml_ui_auth <- function(request){
  tagList(
    # add logout button UI
    # div(class = "pull-right", shinyauthr::logoutUI(id = "logout")),
    # add login panel UI function
    shinyauthr::loginUI(id = "login", cookie_expiry = cookie_expiry),
    # Add table output to show user info after login
    bs4Dash::dashboardPage(
      scrollToTop = TRUE,
      header = bs4Dash::dashboardHeader(),
      sidebar = bs4Dash::dashboardSidebar(minified = TRUE, collapsed = TRUE),
      body = bs4Dash::dashboardBody(
        shinyauthr::loginUI(id = "login", cookie_expiry = cookie_expiry),
        # Add table output to show user info after login
        uiOutput("th2platform")
      ),
      controlbar = bs4Dash::dashboardControlbar(),
      title = "Scroll to top"
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
  output$th2platform <- renderUI({
    # req(credentials()$info$user)
    req(names_list())
    names_list2 <<- names_list()
    if(is.null(names_list()$shiny_authr))return(NULL)
    print(names_list()$shiny_authr)
    cookies::set_cookie(cookie_name = "shinyauthr",names_list()$shiny_authr)
    print("I am here")
    req(credentials()$user_auth)
    dive2ml::th2_landing_page_ui("th2analytics")
  })
  
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
}
