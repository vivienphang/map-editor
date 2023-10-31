-- name: GetZoneById :one
SELECT
    zone
FROM
    map_annotations_zones
WHERE
    id = $1;

-- name: GetRouteById :one
SELECT
    route
FROM
    map_annotations_routes
WHERE
    id = $1;

-- name: GetRoutesByMapId :many
SELECT
    route
FROM
    map_annotations_routes
WHERE
    map_id = $1;

-- name: GetZonesByMapId :many
SELECT
    zone
FROM
    map_annotations_zones
WHERE
    map_id = $1;

-- name: GetMaps :many
SELECT
    *
FROM
    map;

-- name: GetZones :many
SELECT
    *
FROM
    map_annotations_zones;

-- name: GetPaths :many
SELECT
    *
FROM
    map_annotations_routes;

-- name: GetMapById :one
SELECT
    *
FROM
    map
WHERE
    id = $1;

-- name: CreateZone :one
INSERT INTO
    map_annotations_zones (zone, map_id, created_at)
VALUES
    ($1, $2, $3) RETURNING *;

-- name: CreateRoute :one
INSERT INTO
    map_annotations_routes (route, map_id, created_at)
VALUES
    ($1, $2, $3) RETURNING *;

-- name: CreateMap :one
INSERT INTO
    map (name, image_url, created_at)
VALUES
    ($1, $2, $3) RETURNING *;

-- name: UpdateMapById :exec
UPDATE
    map
SET
    name = $2, image_url = $3, created_at = $4
WHERE
    id = $1;

-- name: UpdateZoneById :exec
UPDATE
    map_annotations_zones
SET
    zone = $2,
    created_at = $3
WHERE
    map_id = $1;