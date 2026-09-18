-- ============================================================
-- 04_subquery_analysis.sql
-- Analisis subquery dataset IMDb menggunakan SQL (SQLite)
--
-- Database : data/imdb_movies.db
--
-- Cara menjalankan:
--   sqlite3 data/imdb_movies.db < sql/04_subquery_analysis.sql
--
-- Catatan: sebagian query memakai tabel relasi
--   (genres, movie_genres, actors, movie_actors) yang dibuat
--   pada Bagian 0 file 03_join_analysis.sql.
--
-- Fokus: subquery skalar, IN, NOT EXISTS, derived table (FROM),
--        correlated subquery, dan CTE (WITH).
-- ============================================================


-- ------------------------------------------------------------
-- 1. Subquery skalar di WHERE
--    Film dengan rating di atas rata-rata seluruh film
-- ------------------------------------------------------------
SELECT
    title,
    year,
    rating
FROM movies
WHERE rating > (SELECT AVG(rating) FROM movies)
ORDER BY rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 2. Subquery dengan IN
--    Film yang disutradarai sutradara produktif (>= 6 film)
-- ------------------------------------------------------------
SELECT
    title,
    director,
    year,
    rating
FROM movies
WHERE director IN (
    SELECT director
    FROM movies
    GROUP BY director
    HAVING COUNT(*) >= 6
)
ORDER BY director, year;


-- ------------------------------------------------------------
-- 3. Subquery dengan NOT EXISTS
--    Film yang tidak memiliki genre Drama
--    (NOT EXISTS lebih aman daripada NOT IN bila ada NULL)
-- ------------------------------------------------------------
SELECT
    m.title,
    m.genre,
    m.rating
FROM movies AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM movie_genres AS mg
    JOIN genres       AS g ON g.genre_id = mg.genre_id
    WHERE mg.movie_id = m.movie_id
      AND g.genre_name = 'Drama'
)
ORDER BY m.rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 4. Subquery skalar di SELECT
--    Menampilkan selisih rating film terhadap rata-rata keseluruhan
-- ------------------------------------------------------------
SELECT
    title,
    rating,
    ROUND((SELECT AVG(rating) FROM movies), 2)        AS rata_rata_rating,
    ROUND(rating - (SELECT AVG(rating) FROM movies), 2) AS selisih
FROM movies
ORDER BY selisih DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 5. Subquery di FROM (derived table)
--    Menghitung rata-rata jumlah film per sutradara
-- ------------------------------------------------------------
SELECT
    ROUND(AVG(jumlah_film), 2) AS rata_rata_film_per_sutradara,
    MAX(jumlah_film)           AS jumlah_film_terbanyak,
    MIN(jumlah_film)           AS jumlah_film_tersedikit
FROM (
    SELECT director, COUNT(*) AS jumlah_film
    FROM movies
    GROUP BY director
) AS ringkasan_sutradara;


-- ------------------------------------------------------------
-- 6. Derived table + ORDER BY
--    10 sutradara dengan rata-rata rating terbaik (min. 5 film)
-- ------------------------------------------------------------
SELECT
    sutradara,
    jumlah_film,
    rata_rating
FROM (
    SELECT
        director              AS sutradara,
        COUNT(*)              AS jumlah_film,
        ROUND(AVG(rating), 2) AS rata_rating
    FROM movies
    GROUP BY director
    HAVING COUNT(*) >= 5
) AS peringkat_sutradara
ORDER BY rata_rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 7. CTE (WITH)
--    Ringkasan per tahun, lalu difilter di query utama
-- ------------------------------------------------------------
WITH ringkasan_tahun AS (
    SELECT
        year,
        COUNT(*)              AS jumlah_film,
        ROUND(AVG(rating), 2) AS rata_rating
    FROM movies
    GROUP BY year
)
SELECT *
FROM ringkasan_tahun
WHERE rata_rating < 6.6
ORDER BY year;


-- ------------------------------------------------------------
-- 8. Correlated subquery
--    Film dengan rating tertinggi pada setiap tahun
-- ------------------------------------------------------------
SELECT
    m.year,
    m.title,
    m.rating
FROM movies AS m
WHERE m.rating = (
    SELECT MAX(m2.rating)
    FROM movies AS m2
    WHERE m2.year = m.year
)
ORDER BY m.year;


-- ------------------------------------------------------------
-- 9. Subquery di HAVING
--    Genre dengan rata-rata pendapatan di atas rata-rata
--    pendapatan seluruh film
-- ------------------------------------------------------------
SELECT
    g.genre_name,
    COUNT(*)                          AS jumlah_film,
    ROUND(AVG(m.revenue_millions), 2) AS rata_pendapatan
FROM movie_genres AS mg
JOIN genres       AS g ON g.genre_id = mg.genre_id
JOIN movies       AS m ON m.movie_id = mg.movie_id
GROUP BY g.genre_name
HAVING AVG(m.revenue_millions) > (SELECT AVG(revenue_millions) FROM movies)
ORDER BY rata_pendapatan DESC;


-- ------------------------------------------------------------
-- 10. Correlated subquery
--     Film yang votes-nya di atas rata-rata votes pada tahun
--     yang sama (film populer di masanya)
-- ------------------------------------------------------------
SELECT
    m.year,
    m.title,
    m.votes
FROM movies AS m
WHERE m.votes > (
    SELECT AVG(m2.votes)
    FROM movies AS m2
    WHERE m2.year = m.year
)
ORDER BY m.year, m.votes DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 11. Subquery dengan EXISTS
--     Aktor yang pernah membintangi film rating >= 9
-- ------------------------------------------------------------
SELECT DISTINCT
    a.actor_name
FROM actors AS a
WHERE EXISTS (
    SELECT 1
    FROM movie_actors AS ma
    JOIN movies       AS m ON m.movie_id = ma.movie_id
    WHERE ma.actor_id = a.actor_id
      AND m.rating >= 9.0
)
ORDER BY a.actor_name
LIMIT 10;
