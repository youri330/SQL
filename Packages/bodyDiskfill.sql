
create or replace editionable package BODY DiskFill AS

PROCEDURE add_collection(fc_name VARCHAR2, fc_id OUT NUMBER) AS
colcount NUMBER := 0;
BEGIN
SELECT count(id_collection)
INTO colcount
FROM collection
WHERE c_name = fc_name;
fc_id := s_collection.nextval;
if colcount = 0 then
INSERT INTO collection VALUES (fc_id, fc_name);
else 
select id_collection
into fc_id
from collection
where fc_name = c_name;
end if;
END add_collection;

PROCEDURE add_country(fc_name VARCHAR2) AS 
exvar NUMBER := 0;
BEGIN
SELECT count(*) 
INTO exvar
FROM countries where c_name = fc_name;
--SELECT c_name INTO exname 
--FROM countries
--WHERE c_name = fc_name;
if exvar = 0 THEN
INSERT INTO countries VALUES(fc_name);
END IF;
END;


PROCEDURE add_director(fd_name VARCHAR2, fd_id OUT NUMBER) AS
cnt NUMBER := 0;
BEGIN
SELECT count(id_director) INTO cnt
FROM directors
WHERE d_name = fd_name;
if cnt > 0 then
SELECT id_director INTO fd_id
FROM directors
WHERE 
d_name=fd_name;
else
fd_id := s_director.nextval;
INSERT INTO directors VALUES (fd_name, fd_id);
END IF;
END;

PROCEDURE add_editor (fed_name VARCHAR2, fed_id OUT NUMBER) AS
BEGIN
fed_id := s_ed.nextval;
INSERT INTO editor VALUES(fed_id, fed_name);
END;

PROCEDURE add_genre (fgname VARCHAR2) AS 
exvar NUMBER := 0;
--exgen VARCHAR2(100) := NULL;
BEGIN
--SELECT g_name INTO exgen
--FROM Genres
--Where g_name = fgname;
select count(*)
INTO exvar
FROM genres
WHERE g_name = fgname;
if exvar = 0
THEN
INSERT INTO GENRES VALUES(fgname);
END IF;
END;

PROCEDURE create_content(f_title VARCHAR2, f_year NUMBER, f_duration NUMBER, f_id OUT NUMBER) AS
BEGIN
f_id := s_content.nextval;
INSERT INTO FILMCONTENT VALUES(f_id, f_title, f_year, f_duration);
END;

PROCEDURE create_file(fname VARCHAR2, fmat VARCHAR2,  fid_stor NUMBER, fid_cont NUMBER, fdate DATE DEFAULT NULL, fid OUT NUMBER) AS 
BEGIN
fid := s_edition.nextval;
INSERT INTO FILM_EDITION VALUES(fid, fname, fmat, fid_stor, fid_cont, fdate);
END;

PROCEDURE create_disk(dstype VARCHAR2, dsvolume NUMBER DEFAULT NULL, dsowner VARCHAR2 DEFAULT NULL, dscollection NUMBER DEFAULT NULL, dscolname varchar2 DEFAULT NULL,  dseditor NUMBER DEFAULT NULL, dsretdate DATE DEFAULT NULL, didstor OUT NUMBER) AS
colcount NUMBER := 0;
real_col NUMBER := 0;
BEGIN
didstor := s_storage.nextval;
real_col := dscollection;
if real_col IS NULL and dscolname  IS NOT NULL THEN
add_collection (dscolname, real_col);
END IF;
if dsvolume is null THEN
INSERT INTO VIDEO_STORAGE (id_storage, s_type, s_owner, s_collection, id_editor, modified_date, return_date)
VALUES (didstor, dstype, dsowner, real_col, dseditor, current_date, dsretdate);
ELSE INSERT INTO VIDEO_STORAGE
VALUES(didstor, dstype, dsvolume, dsowner, real_col, dseditor, current_date, dsretdate);
END IF;
END;

--PROCEDURE create_edition(ffilename VARCHAR2, fformat_name VARCHAR2, fid_storage NUMBER, fid_content NUMBER, fid_edition OUT NUMBER) AS
--BEGIN
--fid_edition := s_edition.next;
--INSERT INTO FILM_EDITION (id_edition, filename, format_name, id_storage, id_content)
--VALUES(fid_edition, ffilename, fformat_name, fid_storage, fid_content);
--END;

PROCEDURE insert_film(fstorage NUMBER, ffilm FILM) AS
cont_id NUMBER;
edit_id NUMBER;
dir_id NUMBER;
BEGIN
create_content(ffilm.f_title, ffilm.f_year, ffilm.f_duration, cont_id);
create_file(ffilm.f_filename, ffilm.f_format, fstorage, cont_id, NULL, edit_id);

for i in 1..ffilm.f_genres.count LOOP
add_genre(ffilm.f_genres(i));
INSERT INTO GENRE_FILM VALUES(s_genre_film.nextval, ffilm.f_genres(i), cont_id);
END LOOP;

for i in 1..ffilm.f_countries.count LOOP
add_country(ffilm.f_countries(i));
INSERT INTO COUNTRY_FILM VALUES(s_cf.nextval, ffilm.f_countries(i), cont_id);
END LOOP;


for i in 1..ffilm.f_directors.count LOOP
add_director(ffilm.f_directors(i), dir_id);
INSERT INTO DIRECTOR_FILM VALUES(s_df.nextval, dir_id, cont_id);
END LOOP;
END;


PROCEDURE LOAD_DISK(did NUMBER, films ARR_FILM) AS
BEGIN
for i in 1..films.count LOOP
insert_film(did, films(i));
END LOOP;
END;

--PROCEDURE load_on_disk() AS
--BEGIN
--END;

END DiskFIll;
/
