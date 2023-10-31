package main

import (
	"context"
	"log"
	"os"

	db "example.com/echo-backend/db/gen"
	"example.com/echo-backend/maps"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
)

func main() {
	
	e := echo.New()
	injectDependencies(e)
	log.Println("Server is running on PORT 1323")
    e.Logger.Fatal(e.Start(":1323"))
}

// use godot package to load/read the .env file and
// return the value of the key
func goDotEnvVariable(key string) string {

  // load .env file
  err := godotenv.Load(".env")
  if err != nil {
    log.Fatalf("Error loading .env file")
  }

  return os.Getenv(key)
}

func injectDependencies(e *echo.Echo) {
	remoteDbConnection := goDotEnvVariable("REMOTE_DB")
	pool, err := pgxpool.New(context.Background(), remoteDbConnection)
	if err != nil {
		panic(err)
	}
	log.Println("Connected to database")
	queries := db.New(pool)
	mapService := maps.NewService(queries)
	maps.NewController(e, mapService)
}