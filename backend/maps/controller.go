package maps

import (
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
	e.DELETE("/map/:id", c.deleteMap)
	return c
}

func (con *Controller) getMapById(c echo.Context) error {
	ctx := c.Request().Context()
	id := c.Param("id")
	zones, err := con.service.getZonesByMapId(ctx, id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, err)
	}
	routes, err := con.service.getRoutesByMapId(ctx, id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, err)
	}
	mapInfo, err := con.service.getMapById(ctx, id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, err)
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
		return c.JSON(http.StatusInternalServerError, err)
	}
	return c.JSON(http.StatusOK, maps)
}

func (con *Controller) createMap(c echo.Context) error {
	ctx := c.Request().Context()
	req := MapCreationReq{}
	
	if err := c.Bind(&req); err != nil {
    	return c.JSON(http.StatusBadRequest, BadRequestError())
  	}

	if err := con.service.createNewMap(ctx, req); err != nil {
		return c.JSON(http.StatusInternalServerError, err)
	}
	return c.String(http.StatusOK, "Created new map successfully")
}

func (con *Controller) updateMap(c echo.Context) error {
	ctx := c.Request().Context()
	id := c.Param("id")
	req := MapCreationReq{}
	if err := c.Bind(&req); err != nil {
    	return c.JSON(http.StatusBadRequest, BadRequestError())
  	}

	if err := con.service.updateMap(ctx, req, id); err != nil {
		return c.JSON(http.StatusInternalServerError, err)
	}
	return c.String(http.StatusOK, "Updated map successfully")
}

func (con *Controller) deleteMap(c echo.Context) error {
	ctx := c.Request().Context()
	id := c.Param("id")

	if err := con.service.deleteMap(ctx, id); err != nil {
		return c.JSON(http.StatusInternalServerError, err)
	}
	return c.String(http.StatusOK, "Deleted map successfully")
}