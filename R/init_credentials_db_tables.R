
#' @export
init_credentials_db_tables <- function() {
  library(DBI)
  library(RPostgres)

  # Connexion à PostgreSQL via des variables d'environnement
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("TH_HOST"),
    port = Sys.getenv("TH_PORT"),
    dbname = Sys.getenv("TH_DATABASE"),
    user = Sys.getenv("TH_DB_USERNAME"),
    password = Sys.getenv("TH_DB_PASSWORD")
  )

  # Création de la table "credentials"
  sql_create_credentials <- "
  CREATE TABLE IF NOT EXISTS credentials (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    start_time DATE,
    expire_time DATE,
    applications TEXT
  );
  "

  # Création de la table "pwd_mngt"
  sql_create_pwd_mngt <- "
  CREATE TABLE IF NOT EXISTS pwd_mngt (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    must_change BOOLEAN NOT NULL DEFAULT TRUE,
    have_changed BOOLEAN NOT NULL DEFAULT FALSE,
    date_change DATE,
    n_wrong_pwd INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_username
      FOREIGN KEY(username)
      REFERENCES credentials(username)
      ON DELETE CASCADE
  );
  "

  # --- Ajout de la création de la table "logs" ---
  sql_create_logs <- "
  CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100),
    server_connected TIMESTAMP WITH TIME ZONE,
    token VARCHAR(100),
    logout TIMESTAMP WITH TIME ZONE,
    status VARCHAR(100),
    app VARCHAR(100)
  );
  "

  # Exécution des requêtes pour créer les tables
  dbExecute(con, sql_create_credentials)
  dbExecute(con, sql_create_pwd_mngt)
  dbExecute(con, sql_create_logs) # Exécution de la nouvelle requête

  # Déconnexion
  dbDisconnect(con)
}

#' @export
drop_credentials_db_tables <- function() {
  library(DBI)
  library(RPostgres)

  # Connexion à PostgreSQL (identique à votre fonction de création)
  con <- tryCatch({
    dbConnect(
      RPostgres::Postgres(),
      host = Sys.getenv("TH_HOST"),
      port = Sys.getenv("TH_PORT"),
      dbname = Sys.getenv("TH_DATABASE"),
      user = Sys.getenv("TH_DB_USERNAME"),
      password = Sys.getenv("TH_DB_PASSWORD")
    )
  }, error = function(e) {
    stop("Failed to connect to the database: ", e$message)
  })

  # On s'assure que la connexion est bien fermée à la fin
  on.exit(dbDisconnect(con))

  # Requêtes pour supprimer les tables
  # Il faut supprimer pwd_mngt AVANT credentials à cause de la clé étrangère
  sql_drop_pwd_mngt <- "DROP TABLE IF EXISTS pwd_mngt;"
  sql_drop_credentials <- "DROP TABLE IF EXISTS credentials;"

  # Exécution des requêtes
  dbExecute(con, sql_drop_pwd_mngt)
  dbExecute(con, sql_drop_credentials)

  message("Tables 'pwd_mngt' and 'credentials' have been dropped successfully.")
}
