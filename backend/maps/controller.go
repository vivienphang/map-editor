package maps

import (
	"log"
	"net/http"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/labstack/echo/v4"
)

type Controller struct {
	e *echo.Echo
	service *Service
}

type MapCreationReq struct {
	Name string `json:"name"`
	Image_url string `json:"image_url"`
	Zones []pgtype.Polygon `json:"zones"`
	Routes []pgtype.Path `json:"routes"`
}

func NewController(e *echo.Echo, service *Service) *Controller {
	c:= &Controller{e: e, service: service}
	e.POST("/map", c.createMap)
	e.GET("/maps", c.getMaps)
	e.GET("/map/:id", c.getMapById)
	e.PUT("/map/:id", c.updateMap)
	
	return c
}

func (con *Controller) getMapById(c echo.Context) error {
	ctx := c.Request().Context()
	id := c.Param("id")
	zones, err := con.service.getZones(ctx, id)
	if err != nil {
		log.Println(err)
		return c.JSON(http.StatusNotAcceptable, NewInvalidUUIDError())
	}

	routes, err := con.service.getRoutes(ctx, id)
	if err != nil {
		log.Println(err)
		return c.String(http.StatusInternalServerError, "Error fetching path")
	}

	mapInfo, err := con.service.getImgUrl(ctx, id)
	if err != nil {
		log.Println(err)
		return c.JSON(http.StatusInternalServerError, "Error fetching image url")
	}
	res := make(map[string]interface{})
	res["name"] = mapInfo.Name
	res["image_url"] = mapInfo.ImageUrl
	res["zones"] = zones
	res["routes"] = routes
	return c.JSON(http.StatusOK, res)
}

func (con *Controller) getMaps(c echo.Context) error {
	ctx := c.Request().Context()
	maps, err := con.service.getMaps(ctx)
	if err != nil {
		log.Println(err)
		return c.JSON(http.StatusInternalServerError, "Error fetching zone")
	}
	return c.JSON(http.StatusOK, maps)
}

func (con *Controller) createMap(c echo.Context) error {
	ctx := c.Request().Context()
	req := MapCreationReq{}
	
	err := c.Bind(&req); if err != nil {
    	return c.String(http.StatusBadRequest, "Bad Request Body format")
  	}

	err2 := con.service.createNewMap(ctx, req)
	if err2 != nil {
		log.Println(err)
		return c.JSON(http.StatusInternalServerError, "Error creating map")
	}
	return c.String(http.StatusOK, "Created new map successfully")
}

func (con *Controller) updateMap(c echo.Context) error {
	ctx := c.Request().Context()
	id := c.Param("id")
	req := MapCreationReq{}
	err := c.Bind(&req); if err != nil {
    	return c.String(http.StatusBadRequest, "Bad Request Body format")
  	}

	err2 := con.service.updateMap(ctx, req, id)
	if err2 != nil {
		log.Println(err)
		return c.String(http.StatusInternalServerError, "Error updating map")
	}
	return c.String(http.StatusOK, "Updated map successfully")
}