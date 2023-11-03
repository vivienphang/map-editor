ALTER TABLE
    map
ADD
    COLUMN version INT default 1;

ALTER TABLE
    map
ADD
    COLUMN is_latest BOOLEAN default true;