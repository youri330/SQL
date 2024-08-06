
create or replace type ARR_GENRES IS VARRAY(15) OF VARCHAR2(100); 
/
create or replace type ARR_DIRECTORS IS VARRAY(5) OF VARCHAR2(100);
/
create or replace type ARR_COUNTRIES IS VARRAY(15) OF VARCHAR(100);
/

create or replace type FILM AS OBJECT (
f_title VARCHAR2(200),
f_year NUMBER(4),
f_duration NUMBER(5),
f_filename VARCHAR2(250),
f_format VARCHAR2(10),
f_genres ARR_GENRES,
f_directors ARR_DIRECTORS,
f_countries ARR_COUNTRIES
);
/
create type ARR_FILM IS VARRAY(10) OF FILM;
/
create OR replace editionable package DiskFill AS

PROCEDURE add_collection(fc_name VARCHAR2, fc_id OUT NUMBER);
PROCEDURE add_country(fc_name VARCHAR2);
PROCEDURE add_director(fd_name VARCHAR2, fd_id OUT NUMBER);
PROCEDURE add_editor (fed_name VARCHAR2, fed_id OUT NUMBER);
PROCEDURE add_genre (fgname VARCHAR2);
PROCEDURE create_content(f_title VARCHAR2, f_year NUMBER, f_duration NUMBER, f_id OUT NUMBER);
PROCEDURE create_file(fname VARCHAR2, fmat VARCHAR2,  fid_stor NUMBER, fid_cont NUMBER, fdate DATE DEFAULT NULL, fid OUT NUMBER);
PROCEDURE create_disk(dstype VARCHAR2, dsvolume NUMBER DEFAULT NULL, dsowner VARCHAR2 DEFAULT NULL, dscollection NUMBER DEFAULT NULL, dscolname varchar2 DEFAULT NULL,  dseditor NUMBER DEFAULT NULL, dsretdate DATE DEFAULT NULL, didstor OUT NUMBER);
PROCEDURE insert_film(fstorage NUMBER, ffilm FILM);

PROCEDURE LOAD_DISK(did NUMBER, films ARR_FILM);
--PROCEDURE load_film();
--PROCEDURE insert_content(f_title VARCHAR f_year NUMBER, f_duration );
END DiskFill;
/
