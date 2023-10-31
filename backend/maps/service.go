package maps

import (
	"context"
	"log"
	"net/http"
	"time"

	db "example.com/echo-backend/db/gen"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/labstack/echo/v4"
)



type Service struct {
	db db.Querier
}

func NewService(db db.Querier) *Service {
	service := Service{
		db: db,
	}
	return &service
}

func (s *Service) getMaps(ctx context.Context) ([]db.Map, error) {
	maps := make([]db.Map, 0)
	rows, err := s.db.GetMaps(ctx)
	if err != nil {
		log.Println(err)
		return nil, echo.NewHTTPError(http.StatusInternalServerError, "Internal Server Error, please try again")
	}

	for _, row := range rows {
		maps = append(maps, db.Map{
			ID: row.ID,
			ImageUrl: row.ImageUrl,
			CreatedAt: row.CreatedAt,
		})
	}
	return maps, nil
}

func (s *Service) getZones(ctx context.Context, id string) ([]pgtype.Polygon, error) {
	zones := make([]pgtype.Polygon, 0)
	// uuid := &pgtype.UUID{}
	// err := uuid.Scan(id)
	// if err != nil {
	// 	log.Println(err)
	// 	return nil, echo.NewHTTPError(http.StatusNotAcceptable, "Invalid UUID value")
	// }
	rows, err := s.db.GetZonesByMapId(ctx, uuid.MustParse(id))
	if err != nil {
		log.Println(err)
		return nil, echo.NewHTTPError(http.StatusNotFound, "UUID not found")
	}

	for _, row := range rows {
		zones = append(zones, pgtype.Polygon{
			P: row.P,
		})
	}
	log.Println(zones)
	return zones, nil
}

func (s *Service) getPaths(ctx context.Context, id string) ([]pgtype.Path, error) {
	paths := make([]pgtype.Path, 0)
	rows, err := s.db.GetRoutesByMapId(ctx, uuid.MustParse(id))
	if err != nil {
		log.Println(err)
		return nil, echo.NewHTTPError(http.StatusNotFound, "UUID not found")
	}

	for _, row := range rows {
		paths = append(paths, pgtype.Path{
			P: row.P,
		})
	}
	return paths, nil
}

func (s *Service) getImgUrl(ctx context.Context, id string) (pgtype.Text, error) {
	var res pgtype.Text
	uuid := uuid.MustParse(id)
	row, err := s.db.GetMapById(ctx, uuid)
	if err != nil {
		log.Println(err)
		return res, echo.NewHTTPError(http.StatusInternalServerError, "Internal Server Error, please try again")
	}

	res = row.ImageUrl
	return res, nil
}

func (s *Service) createNewZone(ctx context.Context, zone pgtype.Polygon, id uuid.UUID) (error) {
	date := time.Now()
	newZone, err := s.db.CreateZone(ctx, db.CreateZoneParams{
		Zone: zone,
		MapID: id,
		CreatedAt: date,
	})
	log.Println(newZone)
	if err != nil {
		log.Println(err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal Server Error, please try again")
	}

	return nil
}

func (s *Service) createNewMap(ctx context.Context, req MapCreationReq) (error) {
	date := time.Now()
	nameString := pgtype.Text{String: req.Name, Valid: true}
	urlString := pgtype.Text{String: req.Image_url, Valid: true}
	createdMap, err := s.db.CreateMap(ctx, db.CreateMapParams{
		Name: nameString,
		ImageUrl: urlString,
		CreatedAt: date,
	}) 
	if err != nil {
		log.Println(err)
    	return echo.NewHTTPError(http.StatusInternalServerError, "Error creating new map")
  	}
	
	if (len(req.Zones) != 0) {
		for _, zone := range req.Zones {
			s.createNewZone(ctx, zone, createdMap.ID)
		}
	}
	return nil
}