-- ============================================================
-- 03_join_analysis.sql
-- Analisis JOIN dataset IMDb menggunakan SQL (SQLite)
--
-- Database : data/imdb_movies.db
--
-- Cara menjalankan:
--   sqlite3 data/imdb_movies.db < sql/03_join_analysis.sql
--
-- Tabel yang digunakan:
--   movies          : data film (1 baris = 1 film)
--   directors       : daftar sutradara unik
--   movie_directors : relasi film <-> sutradara
--   genres          : daftar genre unik
--   movie_genres    : relasi film <-> genre
--   actors          : daftar aktor unik
--   movie_actors    : relasi film <-> aktor
--
-- Tabel relasi di atas sudah tersedia pada database.
-- Bagian 0 di bawah hanya dijalankan bila ingin membangun ulang
-- tabel relasi tersebut dari kolom teks pada tabel movies.
-- ============================================================


-- ============================================================
-- BAGIAN 0 - MEMBANGUN TABEL RELASI (idempotent, opsional)
-- ============================================================

-- 0.1 Tabel sutradara
DROP TABLE IF EXISTS directors;
CREATE TABLE directors (
    director_id   INTEGER PRIMARY KEY,
    director_name TEXT NOT NULL UNIQUE
);

INSERT INTO directors (director_name)
SELECT DISTINCT director
FROM movies
ORDER BY director;

-- 0.2 Relasi film <-> sutradara
DROP TABLE IF EXISTS movie_directors;
CREATE TABLE movie_directors (
    movie_id    INTEGER NOT NULL,
    director_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, director_id),
    FOREIGN KEY (movie_id)    REFERENCES movies(movie_id),
    FOREIGN KEY (director_id) REFERENCES directors(director_id)
);

INSERT INTO movie_directors (movie_id, director_id)
SELECT m.movie_id, d.director_id
FROM movies AS m
JOIN directors AS d ON d.director_name = m.director;

-- 0.3 Memecah kolom genre (dipisahkan koma) menjadi satu genre per baris
DROP TABLE IF EXISTS movie_genres_raw;
CREATE TABLE movie_genres_raw (
    movie_id   INTEGER,
    genre_name TEXT
);

INSERT INTO movie_genres_raw (movie_id, genre_name)
WITH RECURSIVE pecah(movie_id, sisa, genre) AS (
    SELECT movie_id, TRIM(genre) || ',', NULL
    FROM movies
    UNION ALL
    SELECT
        movie_id,
        SUBSTR(sisa, INSTR(sisa, ',') + 1),
        TRIM(SUBSTR(sisa, 1, INSTR(sisa, ',') - 1))
    FROM pecah
    WHERE sisa <> ''
)
SELECT movie_id, genre
FROM pecah
WHERE genre IS NOT NULL AND genre <> '';

-- 0.4 Tabel genre dan relasinya
DROP TABLE IF EXISTS genres;
CREATE TABLE genres (
    genre_id   INTEGER PRIMARY KEY,
    genre_name TEXT NOT NULL UNIQUE
);

INSERT INTO genres (genre_name)
SELECT DISTINCT genre_name
FROM movie_genres_raw
ORDER BY genre_name;

DROP TABLE IF EXISTS movie_genres;
CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id)
);

INSERT INTO movie_genres (movie_id, genre_id)
SELECT r.movie_id, g.genre_id
FROM movie_genres_raw AS r
JOIN genres AS g ON g.genre_name = r.genre_name;

DROP TABLE movie_genres_raw;

-- 0.5 Memecah kolom actors menjadi satu aktor per baris, lalu tabel aktor
DROP TABLE IF EXISTS movie_actors_raw;
CREATE TABLE movie_actors_raw (
    movie_id   INTEGER,
    actor_name TEXT
);

INSERT INTO movie_actors_raw (movie_id, actor_name)
WITH RECURSIVE pecah(movie_id, sisa, aktor) AS (
    SELECT movie_id, TRIM(actors) || ',', NULL
    FROM movies
    UNION ALL
    SELECT
        movie_id,
        SUBSTR(sisa, INSTR(sisa, ',') + 1),
        TRIM(SUBSTR(sisa, 1, INSTR(sisa, ',') - 1))
    FROM pecah
    WHERE sisa <> ''
)
SELECT movie_id, aktor
FROM pecah
WHERE aktor IS NOT NULL AND aktor <> '';

DROP TABLE IF EXISTS actors;
CREATE TABLE actors (
    actor_id   INTEGER PRIMARY KEY,
    actor_name TEXT NOT NULL UNIQUE
);

INSERT INTO actors (actor_name)
SELECT DISTINCT actor_name
FROM movie_actors_raw
ORDER BY actor_name;

DROP TABLE IF EXISTS movie_actors;
CREATE TABLE movie_actors (
    movie_id INTEGER NOT NULL,
    actor_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, actor_id),
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);

INSERT INTO movie_actors (movie_id, actor_id)
SELECT r.movie_id, a.actor_id
FROM movie_actors_raw AS r
JOIN actors AS a ON a.actor_name = r.actor_name;

DROP TABLE movie_actors_raw;


-- ============================================================
-- BAGIAN 1 - ANALISIS JOIN
-- ============================================================

-- ------------------------------------------------------------
-- 1. INNER JOIN: daftar film sutradara Ridley Scott
--    movies -> movie_directors -> directors
-- ------------------------------------------------------------
SELECT
    m.title,
    m.year,
    m.rating
FROM movies AS m
JOIN movie_directors AS md ON md.movie_id = m.movie_id
JOIN directors       AS d  ON d.director_id = md.director_id
WHERE d.director_name = 'Ridley Scott'
ORDER BY m.year;


-- ------------------------------------------------------------
-- 2. JOIN + agregasi: 10 genre dengan jumlah film terbanyak
--    movie_genres -> genres
-- ------------------------------------------------------------
SELECT
    g.genre_name,
    COUNT(*) AS jumlah_film
FROM movie_genres AS mg
JOIN genres AS g ON g.genre_id = mg.genre_id
GROUP BY g.genre_name
ORDER BY jumlah_film DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 3. JOIN 3 tabel + HAVING: rata-rata rating & pendapatan per genre
--    Hanya genre dengan minimal 100 film
-- ------------------------------------------------------------
SELECT
    g.genre_name,
    COUNT(*)                        AS jumlah_film,
    ROUND(AVG(m.rating), 2)         AS rata_rating,
    ROUND(AVG(m.revenue_millions), 2) AS rata_pendapatan
FROM movie_genres AS mg
JOIN genres       AS g ON g.genre_id = mg.genre_id
JOIN movies       AS m ON m.movie_id = mg.movie_id
GROUP BY g.genre_name
HAVING COUNT(*) >= 100
ORDER BY rata_rating DESC;


-- ------------------------------------------------------------
-- 4. JOIN + agregasi: 10 aktor dengan film terbanyak
--    movie_actors -> actors -> movies
-- ------------------------------------------------------------
SELECT
    a.actor_name,
    COUNT(*)              AS jumlah_film,
    ROUND(AVG(m.rating), 2) AS rata_rating
FROM movie_actors AS ma
JOIN actors       AS a ON a.actor_id = ma.actor_id
JOIN movies       AS m ON m.movie_id = ma.movie_id
GROUP BY a.actor_name
ORDER BY jumlah_film DESC, a.actor_name
LIMIT 10;


-- ------------------------------------------------------------
-- 5. JOIN banyak tabel + GROUP_CONCAT
--    Film yang dibintangi Mark Wahlberg beserta genrenya
-- ------------------------------------------------------------
SELECT
    m.title,
    m.year,
    m.rating,
    GROUP_CONCAT(g.genre_name, ', ') AS genre_film
FROM movie_actors AS ma
JOIN actors       AS a  ON a.actor_id = ma.actor_id
JOIN movies       AS m  ON m.movie_id = ma.movie_id
JOIN movie_genres AS mg ON mg.movie_id = m.movie_id
JOIN genres       AS g  ON g.genre_id = mg.genre_id
WHERE a.actor_name = 'Mark Wahlberg'
GROUP BY m.movie_id, m.title, m.year, m.rating
ORDER BY m.year;


-- ------------------------------------------------------------
-- 6. LEFT JOIN: sutradara yang tidak punya film rating >= 8
--    LEFT JOIN tetap mempertahankan baris sutradara meski
--    tidak ada film yang cocok (nilainya NULL / COUNT = 0)
-- ------------------------------------------------------------
SELECT
    d.director_name,
    COUNT(m.movie_id) AS jumlah_film_rating_tinggi
FROM directors       AS d
LEFT JOIN movie_directors AS md ON md.director_id = d.director_id
LEFT JOIN movies          AS m  ON m.movie_id = md.movie_id
                               AND m.rating >= 8.0
GROUP BY d.director_name
HAVING COUNT(m.movie_id) = 0
ORDER BY d.director_name
LIMIT 10;


-- ------------------------------------------------------------
-- 7. JOIN banyak tabel: pasangan sutradara - aktor yang paling
--    sering bekerja sama
-- ------------------------------------------------------------
SELECT
    d.director_name,
    a.actor_name,
    COUNT(*) AS jumlah_kolaborasi
FROM movie_directors AS md
JOIN directors       AS d  ON d.director_id = md.director_id
JOIN movie_actors    AS ma ON ma.movie_id = md.movie_id
JOIN actors          AS a  ON a.actor_id = ma.actor_id
GROUP BY d.director_name, a.actor_name
ORDER BY jumlah_kolaborasi DESC, d.director_name
LIMIT 10;


-- ------------------------------------------------------------
-- 8. JOIN + HAVING pada jumlah relasi
--    Film yang memiliki tepat 3 genre
-- ------------------------------------------------------------
SELECT
    m.title,
    m.year,
    COUNT(*) AS jumlah_genre
FROM movies       AS m
JOIN movie_genres AS mg ON mg.movie_id = m.movie_id
GROUP BY m.movie_id, m.title, m.year
HAVING COUNT(*) = 3
ORDER BY m.rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 9. JOIN + agregasi: sutradara dengan rata-rata rating terbaik
--    Minimal 5 film
-- ------------------------------------------------------------
SELECT
    d.director_name,
    COUNT(*)              AS jumlah_film,
    ROUND(AVG(m.rating), 2) AS rata_rating
FROM movie_directors AS md
JOIN directors       AS d ON d.director_id = md.director_id
JOIN movies          AS m ON m.movie_id = md.movie_id
GROUP BY d.director_name
HAVING COUNT(*) >= 5
ORDER BY rata_rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 10. JOIN + agregasi: pendapatan rata-rata per genre pada
--     film yang ratingnya di atas rata-rata keseluruhan
-- ------------------------------------------------------------
SELECT
    g.genre_name,
    COUNT(*)                          AS jumlah_film,
    ROUND(AVG(m.revenue_millions), 2) AS rata_pendapatan
FROM movie_genres AS mg
JOIN genres       AS g ON g.genre_id = mg.genre_id
JOIN movies       AS m ON m.movie_id = mg.movie_id
WHERE m.rating > (SELECT AVG(rating) FROM movies)
GROUP BY g.genre_name
ORDER BY rata_pendapatan DESC
LIMIT 10;
