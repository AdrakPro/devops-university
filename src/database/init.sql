-- Movie Viewer database schema.
--
-- Create the database first, then apply this file, e.g.:
--   createdb -U postgres movies
--   psql -U postgres -d movies -f init.sql

CREATE TABLE IF NOT EXISTS movies (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    year        INTEGER NOT NULL,
    genre       VARCHAR(80) NOT NULL DEFAULT '',
    rating      DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (rating >= 0 AND rating <= 10),
    description TEXT NOT NULL DEFAULT ''
);

-- Seed a few rows the first time the schema is created.
INSERT INTO movies (title, year, genre, rating, description)
SELECT *
FROM (
    VALUES
        ('The Matrix', 1999, 'Sci-Fi', 8.7, 'A hacker discovers reality is a simulation.'),
        ('Spirited Away', 2001, 'Animation', 8.6, 'A girl wanders into a world of spirits.'),
        ('Parasite', 2019, 'Thriller', 8.5, 'Two families collide across a social divide.'),
        ('The Grand Budapest Hotel', 2014, 'Comedy', 8.1, 'A concierge and his lobby boy chase an inheritance.')
) AS seed(title, year, genre, rating, description)
WHERE NOT EXISTS (SELECT 1 FROM movies);
