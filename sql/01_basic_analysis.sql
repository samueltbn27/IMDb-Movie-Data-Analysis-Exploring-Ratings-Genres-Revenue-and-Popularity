-- ============================================================
-- 01_basic_analysis.sql
-- Analisis dasar dataset IMDb menggunakan SQL (SQLite)
--
-- Database : data/imdb_movies.db
-- Tabel    : movies (1000 film, hasil cleaning)
--
-- Cara menjalankan:
--   sqlite3 data/imdb_movies.db < sql/01_basic_analysis.sql
--
-- Struktur tabel movies:
--   movie_id (INTEGER), title (TEXT), genre (TEXT), description (TEXT),
--   director (TEXT), actors (TEXT), year (INTEGER),
--   runtime_minutes (INTEGER), rating (REAL), votes (INTEGER),
--   revenue_millions (REAL), metascore (REAL)
-- ============================================================


-- ------------------------------------------------------------
-- 1. Menampilkan 5 film pertama (melihat struktur data)
--    SELECT ... FROM ... LIMIT
-- ------------------------------------------------------------
SELECT *
FROM movies
LIMIT 5;


-- ------------------------------------------------------------
-- 2. Memilih kolom tertentu saja (proyeksi)
--    Menampilkan judul, tahun, dan rating 10 film pertama
-- ------------------------------------------------------------
SELECT title, year, rating
FROM movies
LIMIT 10;


-- ------------------------------------------------------------
-- 3. Menampilkan daftar tahun rilis yang unik
--    SELECT DISTINCT
-- ------------------------------------------------------------
SELECT DISTINCT year
FROM movies
ORDER BY year;


-- ------------------------------------------------------------
-- 4. Menghitung nilai unik (kombinasi dengan fungsi agregat)
--    COUNT(DISTINCT ...)
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT director) AS jumlah_sutradara,
    COUNT(DISTINCT year)     AS jumlah_tahun,
    COUNT(DISTINCT genre)    AS jumlah_kombinasi_genre
FROM movies;


-- ------------------------------------------------------------
-- 5. Memfilter film dengan rating >= 8 (WHERE)
-- ------------------------------------------------------------
SELECT title, rating, votes
FROM movies
WHERE rating >= 8.0
ORDER BY rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 6. Memfilter dengan dua kondisi sekaligus (AND)
--    Film rating tinggi DAN populer (votes banyak)
-- ------------------------------------------------------------
SELECT title, rating, votes
FROM movies
WHERE rating >= 8.0
  AND votes > 500000
ORDER BY votes DESC;


-- ------------------------------------------------------------
-- 7. Memfilter rentang nilai (BETWEEN)
--    Film yang dirilis tahun 2015-2016
-- ------------------------------------------------------------
SELECT title, year, rating
FROM movies
WHERE year BETWEEN 2015 AND 2016
ORDER BY year, rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 8. Memfilter daftar nilai (IN)
--    Film pada tahun tertentu saja
-- ------------------------------------------------------------
SELECT title, year, rating
FROM movies
WHERE year IN (2006, 2010, 2016)
ORDER BY year, rating DESC
LIMIT 12;


-- ------------------------------------------------------------
-- 9. Pencarian pola teks (LIKE)
--    Film yang judulnya diawali "The "
-- ------------------------------------------------------------
SELECT title, year
FROM movies
WHERE title LIKE 'The %'
ORDER BY year
LIMIT 10;


-- ------------------------------------------------------------
-- 10. Negasi pola (NOT LIKE)
--     Film yang genrenya TIDAK mengandung "Drama"
-- ------------------------------------------------------------
SELECT title, genre
FROM movies
WHERE genre NOT LIKE '%Drama%'
LIMIT 10;


-- ------------------------------------------------------------
-- 11. 10 film dengan pendapatan tertinggi (ORDER BY + LIMIT)
-- ------------------------------------------------------------
SELECT title, revenue_millions, rating
FROM movies
ORDER BY revenue_millions DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 12. Mengurutkan berdasarkan beberapa kolom
--     Pendapatan tertinggi, jika sama maka rating tertinggi
-- ------------------------------------------------------------
SELECT title, revenue_millions, rating
FROM movies
ORDER BY revenue_millions DESC, rating DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 13. Kolom turunan (alias / hasil perhitungan)
--     Mengubah menit menjadi jam dan menghitung pendapatan dalam USD
-- ------------------------------------------------------------
SELECT
    title,
    runtime_minutes,
    ROUND(runtime_minutes / 60.0, 2)                    AS durasi_jam,
    ROUND(revenue_millions * 1000000, 0)                AS pendapatan_usd
FROM movies
ORDER BY revenue_millions DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 14. Pagination (LIMIT + OFFSET)
--     Film rating tertinggi peringkat 6 sampai 10
-- ------------------------------------------------------------
SELECT title, rating
FROM movies
ORDER BY rating DESC
LIMIT 5 OFFSET 5;


-- ------------------------------------------------------------
-- 15. Pemeriksaan kualitas data: memastikan tidak ada nilai NULL
--     pada kolom penting (hasil harus 0)
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_film,
    SUM(CASE WHEN revenue_millions IS NULL THEN 1 ELSE 0 END) AS null_revenue,
    SUM(CASE WHEN metascore        IS NULL THEN 1 ELSE 0 END) AS null_metascore
FROM movies;
