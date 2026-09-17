-- ============================================================
-- 02_aggregate_analysis.sql
-- Analisis agregasi dataset IMDb menggunakan SQL (SQLite)
--
-- Database : data/imdb_movies.db
-- Tabel    : movies
--
-- Cara menjalankan:
--   sqlite3 data/imdb_movies.db < sql/02_aggregate_analysis.sql
--
-- Fokus: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING, CASE WHEN,
--        dan window function (RANK, SUM OVER).
-- ============================================================


-- ------------------------------------------------------------
-- 1. Menghitung jumlah baris (COUNT)
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_film
FROM movies;


-- ------------------------------------------------------------
-- 2. Statistik deskriptif seluruh dataset
--    AVG, MIN, MAX, dan ROUND
-- ------------------------------------------------------------
SELECT
    ROUND(AVG(rating), 2)          AS rata_rating,
    MIN(rating)                    AS rating_terendah,
    MAX(rating)                    AS rating_tertinggi,
    ROUND(AVG(runtime_minutes), 1) AS rata_durasi_menit,
    ROUND(AVG(revenue_millions), 2) AS rata_pendapatan,
    ROUND(AVG(metascore), 2)       AS rata_metascore
FROM movies;


-- ------------------------------------------------------------
-- 3. Total akumulasi (SUM)
-- ------------------------------------------------------------
SELECT
    SUM(votes)                       AS total_votes,
    ROUND(SUM(revenue_millions), 2)  AS total_pendapatan_juta_usd,
    ROUND(SUM(runtime_minutes) / 60.0, 1) AS total_durasi_jam
FROM movies;


-- ------------------------------------------------------------
-- 4. Jumlah film per tahun (GROUP BY)
-- ------------------------------------------------------------
SELECT
    year,
    COUNT(*) AS jumlah_film
FROM movies
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------
-- 5. Rata-rata rating per tahun + filter kelompok (HAVING)
--    Hanya menampilkan tahun yang memiliki lebih dari 50 film
-- ------------------------------------------------------------
SELECT
    year,
    COUNT(*)             AS jumlah_film,
    ROUND(AVG(rating), 2) AS rata_rating
FROM movies
GROUP BY year
HAVING COUNT(*) > 50
ORDER BY year;


-- ------------------------------------------------------------
-- 6. Pengelompokan kategori dengan CASE WHEN
--    Mengubah rating numerik menjadi kategori, lalu diagregasi
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN rating < 6 THEN '1. Rendah (< 6)'
        WHEN rating < 7 THEN '2. Sedang (6 - 7)'
        WHEN rating < 8 THEN '3. Bagus (7 - 8)'
        ELSE '4. Sangat bagus (>= 8)'
    END                        AS kategori_rating,
    COUNT(*)                   AS jumlah_film,
    ROUND(AVG(runtime_minutes), 1) AS rata_durasi,
    ROUND(AVG(revenue_millions), 2) AS rata_pendapatan
FROM movies
GROUP BY kategori_rating
ORDER BY kategori_rating;


-- ------------------------------------------------------------
-- 7. 10 sutradara dengan film terbanyak
--    GROUP BY + ORDER BY agregat
-- ------------------------------------------------------------
SELECT
    director,
    COUNT(*)              AS jumlah_film,
    ROUND(AVG(rating), 2) AS rata_rating
FROM movies
GROUP BY director
ORDER BY jumlah_film DESC, director
LIMIT 10;


-- ------------------------------------------------------------
-- 8. 10 kombinasi genre yang paling banyak muncul
-- ------------------------------------------------------------
SELECT
    genre,
    COUNT(*) AS jumlah_film
FROM movies
GROUP BY genre
ORDER BY jumlah_film DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 9. Rata-rata pendapatan dan rating per tahun
-- ------------------------------------------------------------
SELECT
    year,
    COUNT(*)                        AS jumlah_film,
    ROUND(AVG(revenue_millions), 2) AS rata_pendapatan,
    ROUND(AVG(rating), 2)           AS rata_rating
FROM movies
GROUP BY year
ORDER BY year;


-- ------------------------------------------------------------
-- 10. Window function: RANK
--     Memberi peringkat film berdasarkan rating (10 teratas)
-- ------------------------------------------------------------
SELECT
    title,
    year,
    rating,
    RANK() OVER (ORDER BY rating DESC) AS peringkat_rating
FROM movies
ORDER BY peringkat_rating
LIMIT 10;


-- ------------------------------------------------------------
-- 11. Window function: running total
--     Jumlah film kumulatif dari tahun ke tahun
-- ------------------------------------------------------------
SELECT
    t.year,
    t.jumlah_film,
    SUM(t.jumlah_film) OVER (ORDER BY t.year) AS jumlah_kumulatif
FROM (
    SELECT year, COUNT(*) AS jumlah_film
    FROM movies
    GROUP BY year
) AS t
ORDER BY t.year;


-- ------------------------------------------------------------
-- 12. Kelompok popularitas (votes) dan performanya
--     CASE WHEN + GROUP BY
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN votes <  50000 THEN '1. < 50rb'
        WHEN votes < 100000 THEN '2. 50rb - 100rb'
        WHEN votes < 250000 THEN '3. 100rb - 250rb'
        WHEN votes < 500000 THEN '4. 250rb - 500rb'
        ELSE '5. > 500rb'
    END                             AS kelompok_votes,
    COUNT(*)                        AS jumlah_film,
    ROUND(AVG(rating), 2)           AS rata_rating,
    ROUND(AVG(revenue_millions), 2) AS rata_pendapatan
FROM movies
GROUP BY kelompok_votes
ORDER BY kelompok_votes;


-- ------------------------------------------------------------
-- 13. Sutradara produktif sekaligus berkualitas
--     Rata-rata rating tertinggi, minimal 5 film
-- ------------------------------------------------------------
SELECT
    director,
    COUNT(*)              AS jumlah_film,
    ROUND(AVG(rating), 2) AS rata_rating,
    ROUND(AVG(votes), 0)  AS rata_votes
FROM movies
GROUP BY director
HAVING COUNT(*) >= 5
ORDER BY rata_rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 14. Ringkasan performa genre Drama vs Non-Drama
--     Agregasi kondisional dalam satu query
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_film,
    SUM(CASE WHEN genre LIKE '%Drama%' THEN 1 ELSE 0 END) AS jumlah_drama,
    SUM(CASE WHEN genre NOT LIKE '%Drama%' THEN 1 ELSE 0 END) AS jumlah_non_drama,
    ROUND(AVG(CASE WHEN genre LIKE '%Drama%' THEN rating END), 2) AS rata_rating_drama,
    ROUND(AVG(CASE WHEN genre NOT LIKE '%Drama%' THEN rating END), 2) AS rata_rating_non_drama
FROM movies;
