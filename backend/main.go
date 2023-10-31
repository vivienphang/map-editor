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
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func main() {
	e := echo.New()
	injectDependencies(e)
	log.Println("Server is running on PORT 1323")
    e.Logger.Fatal(e.Start(":1323"))
}

// use godot package to load/read the .env file and return the value of the key
func goDotEnvVariable(key string) string {
  // load .env file
  err := godotenv.Load(".env")
  if err != nil {
    log.Fatalf("Error loading .env file")
  }

  return os.Getenv(key)
}

func injectDependencies(e *echo.Echo) {
	dbConnectionString := goDotEnvVariable("LOCAL_DB")
	// Connect to database
	pool, err := pgxpool.New(context.Background(), dbConnectionString)
	if err != nil {
		panic(err)
	}
	log.Println("Connected to database")

	// Create new instance of querier, service and controller
	queries := db.New(pool)
	mapService := maps.NewService(queries)
	maps.NewController(e, mapService)

	// Database Migrations
	m, err := migrate.New(
		"file://db/migration",
		dbConnectionString)
	if err != nil {
		log.Fatal(err)
	}
	if err := m.Up(); err != nil {
		log.Println(err)
	}
}