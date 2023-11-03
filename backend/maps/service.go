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
		return []db.Map{}, InternalServerError()
	}

	for _, row := range rows {
		maps = append(maps, db.Map{
			ID: row.ID,
			Name: row.Name,
			ImageUrl: row.ImageUrl,
			CreatedAt: row.CreatedAt,
		})
	}
	return maps, nil
}

func (s *Service) getZonesByMapId(ctx context.Context, id string) ([]pgtype.Polygon, error) {
	zones := make([]pgtype.Polygon, 0)
	uuid := pgtype.UUID{}
	if err := uuid.Scan(id); err != nil {
		log.Println(err)
		return []pgtype.Polygon{}, InvalidUUIDError()
	}
	rows, err := s.db.GetZonesByMapId(ctx, uuid)
	if err != nil {
		log.Println(err)
		return []pgtype.Polygon{}, NotFoundError()
	}

	for _, row := range rows {
		zones = append(zones, pgtype.Polygon{
			P: row.P,
		})
	}
	return zones, nil
}

func (s *Service) getRoutesByMapId(ctx context.Context, id string) ([]pgtype.Path, error) {
	routes := make([]pgtype.Path, 0)
	uuid := pgtype.UUID{}
	if err := uuid.Scan(id); err != nil {
		log.Println(err)
		return []pgtype.Path{}, InvalidUUIDError()
	}

	rows, err := s.db.GetRoutesByMapId(ctx, uuid)
	if err != nil {
		log.Println(err)
		return []pgtype.Path{}, NotFoundError()
	}

	for _, row := range rows {
		routes = append(routes, pgtype.Path{
			P: row.P,
		})
	}
	return routes, nil
}

func (s *Service) getMapById(ctx context.Context, id string) (db.Map, error) {
	uuid, err := uuid.Parse(id) 
	if err != nil {
		log.Println(err)
		return db.Map{}, InvalidUUIDError()
	}
	res, err := s.db.GetMapById(ctx, uuid)
	if err != nil {
		log.Println(err)
		return db.Map{}, NotFoundError()
	}
	return res, nil
}

func (s *Service) createNewZone(ctx context.Context, zone pgtype.Polygon, id uuid.UUID) (error) {
	uuid := pgtype.UUID{}
	uuid.Scan(id.String())
	newZone, err := s.db.CreateZone(ctx, db.CreateZoneParams{
		Zone: zone,
		MapID: uuid,
	})
	log.Println(newZone)
	if err != nil {
		log.Println(err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal Server Error, please try again")
	}

	return nil
}

func (s *Service) createNewMap(ctx context.Context, req MapCreationReq) (error) {
	date := time.Now().Local()
	nameString := pgtype.Text{String: req.Name, Valid: true}
	urlString := pgtype.Text{String: req.Image_url, Valid: true}
	createdMap, err := s.db.CreateMap(ctx, db.CreateMapParams{
		Name: nameString,
		ImageUrl: urlString,
		CreatedAt: date,
	}) 
	if err != nil {
		log.Println(err)
    	return MapCreationError()
  	}
	
	if (len(req.Zones) != 0) {
		for _, zone := range req.Zones {
			s.createNewZone(ctx, zone, createdMap.ID)
		}
	}
	return nil
}

func (s *Service) updateMap(ctx context.Context, req MapCreationReq, id string) (error) {
	name := pgtype.Text{String: req.Name, Valid: true}
	imgUrl := pgtype.Text{String: req.Image_url, Valid: true}
	date := time.Now().Local()
	uuid, err := uuid.Parse(id)
	if err != nil {
		log.Println(err)
		return InvalidUUIDError()
	}
	if err := s.db.UpdateMapById(ctx, db.UpdateMapByIdParams{
		Name: name,
		ImageUrl: imgUrl,
		CreatedAt: date,
		ID: uuid,
	}); err != nil {
		log.Println(err)
    	return MapUpdateError()
  	}
	
	if (len(req.Zones) != 0) {
		for _, zone := range req.Zones {
			s.updateZone(ctx, zone, id)
		}
	}

	return nil
}

func (s *Service) updateZone(ctx context.Context, zone pgtype.Polygon, id string) (error) {
	uuid := pgtype.UUID{}
	uuid.Scan(id)
	err := s.db.UpdateZoneById(ctx, db.UpdateZoneByIdParams{
		Zone: zone,
		MapID: uuid,
	})
	if err != nil {
		log.Println(err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal Server Error, please try again")
	}

	return nil
}
func (s *Service) deleteMap(ctx context.Context, id string) (error) {
	// s.deleteZone(ctx, id)
	uuid, err := uuid.Parse(id)
	if err != nil {
		log.Println(err)
		return InvalidUUIDError()
	}
	if err := s.db.DeleteMapById(ctx, uuid); err != nil {
		log.Println(err)
		return MapDeletionError()
	}

	return nil
}