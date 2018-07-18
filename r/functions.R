load_config <- function(path = "../") {
  # path: path to root of repo (where config.sh is located)
  readRenviron(file.path(path, "config.sh"))

  list(
    db = list(
      dbname = Sys.getenv("SHEDS_CLSB_DB_DBNAME"),
      host = Sys.getenv("SHEDS_CLSB_DB_HOST"),
      password = Sys.getenv("SHEDS_CLSB_DB_PASSWORD"),
      port = Sys.getenv("SHEDS_CLSB_DB_PORT"),
      user = Sys.getenv("SHEDS_CLSB_DB_USER")
    ),
    tiles = list(
      dir = Sys.getenv("SHEDS_CLSB_TILES_DIR")
    )
  )
}
