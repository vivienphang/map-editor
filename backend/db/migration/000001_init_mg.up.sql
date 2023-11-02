CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE if NOT EXISTS map (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    name VARCHAR(50),
    image_url TEXT
);

CREATE TABLE if NOT EXISTS map_annotations_zones (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    zone POLYGON,
    map_id uuid REFERENCES map (id) ON DELETE CASCADE
);

CREATE TABLE if NOT EXISTS map_annotations_routes (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    route PATH,
    map_id uuid REFERENCES map (id) ON DELETE CASCADE
);