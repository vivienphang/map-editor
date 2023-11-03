package main

import (
	"context"
	"log"
	"net/http"
	"os"

	db "example.com/echo-backend/db/gen"
	"example.com/echo-backend/maps"
	"github.com/go-playground/validator/v10"
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type CustomValidator struct {
    validator *validator.Validate
}


func (cv *CustomValidator) Validate(i interface{}) error {
  if err := cv.validator.Struct(i); err != nil {
    // Optionally, you could return the error to give each route more control over the status code
    return echo.NewHTTPError(http.StatusBadRequest, err.Error())
  }
  return nil
}

func main() {
	e := echo.New()
	e.Use(middleware.CORS())
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

func validatedNumberOfPoints(fl validator.FieldLevel) bool {
    zones := fl.Field().Interface().([]pgtype.Polygon)
	// To check for at least 3 points
    for _, zone := range zones {
        if len(zone.P) < 3 {
			return false
		}
		// To check for only positive coordinate points
		for _, point := range zone.P {
			if point.X < 0 || point.Y < 0 {
				return false
			}
		}
    }
    return true
}

func injectDependencies(e *echo.Echo) {
	dbConnectionString := goDotEnvVariable("REMOTE_DB")
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
		log.Println(err)
	}
	if err := m.Force(1); err != nil {
		log.Println(err)
	}
	if err := m.Up(); err != nil {
		log.Println(err)
	}
	
	// Validations
	v := validator.New()
	v.RegisterValidation("numberOfPoints", validatedNumberOfPoints)
	e.Validator = &CustomValidator{validator: v}

}