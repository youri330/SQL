--Скрипт для тримминга данных
-- triming titles

UPDATE stg_movie set title = trim(title), genres = trim(genres);

-- see parsed data (with year specified in correct format)
    with cte_splitTitleAndGenres(movieId, title, releaseYear, genre, remainingGenres) as
	(
		select movieId as movieId,
			   substr(title, 1, length(trim(title)) - 6) as title,
			   substr(title, -5, 4) as releaseYear,
			   substring_index(concat(genres, '|'),'|', 1) as genre,
		       substr(concat(genres, '|'), instr(concat(genres, '|'), '|') + 1) as remainingGenres
		from stg_movie
        where concat('',substr(title, -5, 4)) = substr(title, -5, 4)
        and movieId not in (select stgm.movieId from stg_movie stgm
                            where not regexp_like(substr(title, -5, 4), '^[0-9]{4}$'))
	    union all
        select movieId,
			   title,
			   releaseYear,
			   substring_index(remainingGenres,'|', 1) as genre, 
               substr(remainingGenres, instr(remainingGenres, '|') + 1) as remainingGenres
		from cte_splitTitleAndGenres
        where remainingGenres <> '|'
	)
	select movieId,
		   title as title, 
		   genre,
		   releaseYear
    from cte_splitTitleAndGenres
    order by movieId;

-- see parsed data (with no correct year specified)

with cte_splitTitleAndGenresNoYear(movieId, title, releaseYear, genre, remainingGenres) as
	(
		select movieId as movieId,
			   title as title,
			   null as releaseYear,
			   substring_index(concat(genres, '|'),'|', 1) as genre,
		       substr(concat(genres, '|'), instr(concat(genres, '|'), '|') + 1) as remainingGenres
		from stg_movie
        where concat('',substr(title, -5, 4)) = substr(title, -5, 4)
        and not regexp_like(substr(title, -5, 4), '^[0-9]{4}$') -- releaseYear not specified
        
	    union all
        select movieId,
			   title,
			   releaseYear,
			   substring_index(remainingGenres,'|', 1) as genre, 
               substr(remainingGenres, instr(remainingGenres, '|') + 1) as remainingGenres
		from cte_splitTitleAndGenresNoYear
        where remainingGenres <> '|'
	)
	select movieId,
		   title, 
		   genre,
		   releaseYear
    from cte_splitTitleAndGenresNoYear
    order by movieId;

create or replace procedure usp_parseMovies
as
begin

    insert into movie5 (movieId, title, genre, releaseYear)
    with cte_splitTitleAndGenres(movieId, title, releaseYear, genre, remainingGenres) as
  (
    select movieId as movieId,
         substr(title, 1, length(trim(title)) - 6) as title,
         substr(title, -5, 4) as releaseYear,
         substring_index(concat(genres, '|'),'|', 1) as genre,
           substr(concat(genres, '|'), instr(concat(genres, '|'), '|') + 1) as remainingGenres
    from stg_movie
        where concat('',substr(title, -5, 4)) = substr(title, -5, 4)
        and movieId not in (select stgm.movieId from stg_movie stgm
                            where not regexp_like(substr(title, -5, 4), '^[0-9]{4}$'))
      union all
        select movieId,
         title,
         releaseYear,
         substring_index(remainingGenres,'|', 1) as genre, 
               substr(remainingGenres, instr(remainingGenres, '|') + 1) as remainingGenres
    from cte_splitTitleAndGenres
        where remainingGenres <> '|'
  )
  select movieId,
       title as title, 
       genre,
       releaseYear
    from cte_splitTitleAndGenres;

    insert into movie5 (movieId, title, genre, releaseYear)
    with cte_splitTitleAndGenresNoYear(movieId, title, releaseYear, genre, remainingGenres) as
  (
    select movieId as movieId,
         title as title,
         null as releaseYear,
         substring_index(concat(genres, '|'),'|', 1) as genre,
           substr(concat(genres, '|'), instr(concat(genres, '|'), '|') + 1) as remainingGenres
    from stg_movie
        where concat('',substr(title, -5, 4)) = substr(title, -5, 4)
        and not regexp_like(substr(title, -5, 4), '^[0-9]{4}$') -- releaseYear not specified

      union all
        select movieId,
         title,
         releaseYear,
         substring_index(remainingGenres,'|', 1) as genre, 
               substr(remainingGenres, instr(remainingGenres, '|') + 1) as remainingGenres
    from cte_splitTitleAndGenresNoYear
        where remainingGenres <> '|'
  )
  select movieId,
       title, 
       genre,
       releaseYear
    from cte_splitTitleAndGenresNoYear;
end;


EXEC usp_parseMovies();
    
--1. Вывести все уникальные жанры, которые встречаются в фильмах. Отдельно найти все фильмы у которых жанр не указан.    
select distinct(m.genre) 
from movie5 m
order by m.genre;

select * from movie5 
where genre = '(no genres listed)';

--2. Создать таблицы и загрузить в них данные из Data  ratings.csv и tags.csv.

--3. Найти фильмы, которые имеют средний рейтинг >= 4.0. Посчитать кол-во оценок, которые были получены этими фильмами.
--Найти фильмы, которые имеют средний рейтинг <= 2.0. Посчитать кол-во оценок, которые были получены этими фильмами.
--Вывести title, releaseYear, avgRate, countMark.

CREATE OR REPLACE VIEW unique_movie AS
SELECT movieid, title, releaseYear 
FROM movie5
GROUP BY movieid, title, releaseYear;

SELECT m.movieid, m.releaseYear, m.title, to_char(avg(r.rating), 'fm9999999.90') as rating, count(r.rating) as votes
FROM unique_movie m
JOIN Rating r ON m.movieid = r.movieid
GROUP BY m.movieid, m.releaseYear, m.title
HAVING avg(r.rating) >= 4
ORDER BY m.movieid;

SELECT m.movieid, m.releaseYear, m.title, to_char(avg(r.rating), 'fm9999999.90') as rating, count(r.rating) as votes
FROM unique_movie m
JOIN Rating r ON m.movieid = r.movieid
GROUP BY m.movieid, m.releaseYear, m.title
HAVING avg(r.rating) <= 2
ORDER BY m.movieid;

--4.	Найти фильмы, у которых имеется тег family. Узнать средний рейтинг для фильмов с таким тегом. 
-- Вывести title, releaseYear, avgRate. 
-- Найти фильмы, которые содержат в теге слово bad или stupid. 
-- Вывести title, releaseYear.

CREATE OR REPLACE VIEW avg_rating5 AS
SELECT m.movieid, m.title, m.releaseYear, avg(r.rating) as rating
FROM unique_movie m
JOIN rating r ON m.movieid = r.movieid
GROUP BY m.movieid, m.title, m.releaseYear;

SELECT m.movieid, m.title, m.releaseYear, avg(r.rating) as rating
FROM unique_movie m
JOIN tags t ON m.movieid = t.movieid
JOIN avg_rating r ON m.movieid = r.movieid
where t.tag like '%family%'
GROUP BY m.movieid, m.title, m.releaseYear;

SELECT m.movieid, m.title, m.releaseYear
FROM unique_movie m
JOIN tags t ON m.movieid = t.movieid
JOIN avg_rating r ON m.movieid = r.movieid
where t."TAG" like '%bad%' or t."TAG" like '%stupid%'  
GROUP BY m.movieid, m.title, m.releaseYear;


--5. Найти пользователя(ей), который поставил больше всего оценок фильмам, посчитать среднее значение его оценок.
-- Вывести userId, countMark, avgMark.
CREATE OR REPLACE VIEW user_votes AS
SELECT r.userid, count(r.rating) as votes, to_char(avg(r.rating), 'fm9999999.90') as avg
FROM rating r
GROUP BY r.userid;

SELECT r.userid, uv.votes, uv.avg
FROM rating r
JOIN user_votes uv ON r.userid = uv.userid
WHERE uv.votes = (SELECT max(votes) FROM user_votes)
GROUP BY r.userid, uv.votes, uv.avg;


--6.	Написать хранимую процедуру, которая будет принимать в качестве параметров startYear int, finishYear int, titleTemplate text, genresTemplate и находить фильмы согласно этим параметрам. 
--То есть фильмы:
--с годом выпуска between startYear and finishYear
--у которых в title содержится titleTemplate (регистром пренебречь)
--у которых в жанрах содержатся все жанры из genresTemplate
--genresTemplate имеет формат: g1|g2|g3 или g1(если жанр один)

CREATE OR REPLACE VIEW movie_count_genres AS
SELECT movieid, title, releaseYear, count(genre) as genre_count
FROM movie5
GROUP BY movieid, title, releaseYear;

CREATE OR REPLACE FUNCTION count_words(test_string VARCHAR2, delim VARCHAR)
RETURN NUMBER
IS
words_count NUMBER;
BEGIN
    SELECT LENGTH(test_string) - LENGTH(REPLACE(test_string, delim, '')) + 1
    INTO words_count
    FROM DUAL;
    RETURN words_count;
END;

CREATE OR REPLACE FUNCTION search_movies
(startYear IN NUMBER,
finishYear IN NUMBER,
titleTemplate IN VARCHAR2,
genresTemplate IN VARCHAR2)
RETURN SYS_REFCURSOR  
IS
result_data SYS_REFCURSOR;
BEGIN
    OPEN result_data FOR
        SELECT mcg.title, mcg.releaseYear
        FROM movie_count_genres mcg
        WHERE mcg.releaseYear BETWEEN startYear AND finishYear
        AND INSTR(LOWER(mcg.title), LOWER(titleTemplate)) != 0
        AND count_words(genresTemplate, '|') = (
            SELECT COUNT(genre)
            FROM movie5
            WHERE movieid = mcg.movieid
                AND INSTR(LOWER(genresTemplate), LOWER(genre)) != 0
            );
    RETURN result_data;
END;

DECLARE
result_data SYS_REFCURSOR;
title VARCHAR2(4000);
releaseYear NUMBER;
BEGIN
    result_data := search_movies(2010, 2015, 'love', 'Drama|Romance');
    LOOP
        FETCH result_data INTO title, releaseYear;
        EXIT WHEN result_data%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(title || ' (' || releaseYear || ')');
    END LOOP;
    CLOSE result_data;    
END;    


--7. Написать хранимую процедуру, которая принимает в качестве параметра title и считает рейтинг для этого фильма.

CREATE OR REPLACE PROCEDURE get_rating
(movie_title IN VARCHAR2, 
movie_rating OUT NUMBER)
IS
BEGIN
    SELECT ar.rating
    INTO movie_rating
    FROM avg_rating5 ar
    WHERE ar.title = movie_title;
END;

EXEC get_rating('The OA', c number);

DECLARE
    c number;
BEGIN
    get_rating('The OA', c);
END;

