#' Check credentials
#'
#' @param db A \code{data.frame} with credentials data, a  path to SQLite database created with \code{\link{create_db}}
#' or a .yaml configuration path of SQL Database created with \code{\link{create_sql_db}}.
#'
#' @param passphrase Passphrase to decrypt the SQLite database.
#'
#' @return Return a \code{function} with two arguments: \code{user} and \code{password}
#' to be used in \code{\link{module-authentication}}. The authentication function returns
#' a \code{list} with 4 slots :
#'  \itemize{
#'   \item \strong{result} : logical, result of authentication.
#'   \item \strong{expired} : logical, is user has expired ? Always \code{FALSE} if \code{db} doesn't have a \code{expire} column.
#'   \item \strong{authorized} : logical, is user can access to his app ? Always \code{TRUE} if \code{db} doesn't have a \code{applications} column.
#'   \item \strong{user_info} : the line in \code{db} corresponding to the user.
#'  }
#'
#'
#' @details The credentials \code{data.frame} can have the following columns:
#'  \itemize{
#'   \item \strong{user (mandatory)} : the user's name.
#'   \item \strong{password (mandatory)} : the user's password.
#'   \item \strong{admin (optional)} : logical, is user have admin right ? If so,
#'    user can access the admin mode (only available using a SQLite database). Initialize to FALSE if missing.
#'   \item \strong{start (optional)} : the date from which the user will have access to the application. Initialize to NA if missing.
#'   \item \strong{expire (optional)} : the date from which the user will no longer have access to the application. Initialize to NA if missing.
#'   \item \strong{applications (optional)} : the name of the applications to which the user is authorized,
#'    separated by a semicolon. The name of the application corresponds to the name of the directory,
#'    or can be declared using : \code{options("shinymanager.application" = "my-app")}
#'   \item \strong{additional columns} : add others columns to retrieve the values server-side after authentication
#'  }
#'
#' @export
#'
#'
#'
#' @examples
#' # data.frame with credentials info
#' credentials <- data.frame(
#'   user = c("fanny", "victor"),
#'   password = c("azerty", "12345"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # check a user
#' check_credentials(credentials)("fanny", "azerty")
#' check_credentials(credentials)("fanny", "azert")
#' check_credentials(credentials)("fannyyy", "azerty")
#'
#' # data.frame with credentials info
#' # using hashed password with scrypt
#' credentials <- data.frame(
#'   user = c("fanny", "victor"),
#'   password = c(scrypt::hashPassword("azerty"), scrypt::hashPassword("12345")),
#'   is_hashed_password = TRUE,
#'   stringsAsFactors = FALSE
#' )
#'
#' # check a user
#' check_credentials(credentials)("fanny", "azerty")
#' check_credentials(credentials)("fanny", "azert")
#' check_credentials(credentials)("fannyyy", "azerty")
#'
#' \dontrun{
#'
#' ## With a SQLite database:
#' check_credentials("credentials.sqlite", passphrase = "supersecret")
#'
#'
#' ## With a SQL database:
#' check_credentials("config_db.yml")
#' }
#'
#' @importFrom scrypt verifyPassword
#'
#' @seealso \code{\link{create_db}}, \code{\link{create_sql_db}}, \code{\link{check_credentials}}
#'
check_credentials <- function(db, passphrase = NULL) {
  if (is.data.frame(db)) {
    .tok$set_sqlite_path(NULL)
    .tok$set_sql_config_db(NULL)
    function(user, password) {
      check_credentials_df(user, password, credentials_df = db)
    }
  } else if (is_sqlite(db)) {
    .tok$set_sqlite_path(db)
    .tok$set_passphrase(passphrase)
    check_credentials_sqlite(sqlite_path = db, passphrase = passphrase)
  } else if (is_yaml(db)) {
    config_db <- tryCatch(
      {
        yaml::yaml.load_file(db, eval.expr = TRUE)
      },
      error = function(e) stop("Error reading 'config_path' SQL DB configuration :", e$message)
    )
    verify_sql_config(config_db)

    .tok$set_sqlite_path(NULL)
    .tok$set_sql_config_db(config_db)
    check_credentials_sql(config_db = config_db)
  } else {
    stop("'db' must be a data.frame, a path to a SQLite database or a .yml file for other SQL Database", call. = FALSE)
  }
}


check_credentials_df <- function(user, password, credentials_df) {
  credentials_df <- as.data.frame(credentials_df)
  if (!user %in% credentials_df$user) {
    return(list(
      result = FALSE,
      expired = FALSE,
      authorized = FALSE,
      user_info = NULL
    ))
  }
  user_info <- credentials_df[credentials_df$user == user, setdiff(names(credentials_df), c("password", "is_hashed_password")), drop = FALSE]
  pwd <- credentials_df$password[credentials_df$user == user]
  if ("is_hashed_password" %in% colnames(credentials_df)) {
    is_hashed_pwd <- credentials_df$is_hashed_password[credentials_df$user == user]
  } else {
    is_hashed_pwd <- FALSE
  }

  if (is_hashed_pwd) {
    good_password <- isTRUE(scrypt::verifyPassword(pwd, password))
  } else {
    good_password <- isTRUE(pwd == password)
  }

  if (hasName(credentials_df, "expire_time") | hasName(credentials_df, "start_time")) {
    if (is.null(user_info$start_time) | (!is.null(user_info$start_time) && is.na(user_info$start_time))) {
      user_info$start_time <- Sys.Date() - 1
    }
    if (is.null(user_info$expire_time) | (!is.null(user_info$expire_time) && is.na(user_info$expire_time))) {
      user_info$expire_time <- Sys.Date() + 1
    }
    good_time <- isTRUE(user_info$start_time <= Sys.Date() & user_info$expire_time >= Sys.Date())
  } else {
    good_time <- TRUE
  }
  authorized <- TRUE
  if (hasName(credentials_df, "applications")) {
    appname <- get_appname()
    appsnames <- credentials_df$applications[credentials_df$user == user]
    appsnames <- strsplit(x = as.character(appsnames), split = ";")
    appsnames <- unlist(x = appsnames, use.names = FALSE)
    if (!isTRUE(appname %in% appsnames)) {
      good_password <- FALSE
      authorized <- FALSE
    }
  }
  if (good_password) {
    if (good_time) {
      auth <- list(
        result = TRUE,
        expired = FALSE,
        authorized = authorized,
        user_info = user_info
      )
    } else {
      auth <- list(
        result = FALSE,
        expired = TRUE,
        authorized = authorized,
        user_info = user_info
      )
    }
  } else {
    auth <- list(
      result = FALSE,
      expired = FALSE,
      authorized = authorized,
      user_info = user_info
    )
  }
  return(auth)
}

check_credentials_sqlite <- function(sqlite_path, passphrase) {
  conn <- dbConnect(SQLite(), dbname = sqlite_path)
  on.exit(dbDisconnect(conn))
  db <- read_db_decrypt(
    conn = conn,
    name = "credentials",
    passphrase = passphrase
  )
  function(user, password) {
    check_credentials_df(user, password, credentials_df = db)
  }
}


check_credentials_sql <- function(config_db) {
  function(user, password) {
    conn <- connect_sql_db(config_db)
    on.exit(disconnect_sql_db(conn, config_db))
    tablename <- SQL(config_db$tables$credentials$tablename)
    request <- glue_sql(config_db$tables$credentials$select, .con = conn)
    db <- dbGetQuery(conn, request)
    if (nrow(db) > 0) db$is_hashed_password <- T
    check_credentials_df(user, password, credentials_df = db)
  }
}
