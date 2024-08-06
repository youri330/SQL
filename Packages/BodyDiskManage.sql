create or replace editionable package BODY VideoManage AS
Function GetDiskInfo(did NUMBER) RETURN ARR_FILE AS
CURSOR record_cursor IS 
SELECT filename
FROM film_edition
WHERE id_storage = did;
files ARR_FILE := ARR_FILE();
counter NUMBER := 0;
BEGIN
--OPEN record_cursor;
FOR rec IN record_cursor LOOP
files.extend;
counter := counter + 1;
files(counter) := rec.filename;
END LOOP;
return files;
END;

Function MoveRecords(id_from NUMBER, id_to NUMBER) return NUMBER AS
rem_count NUMBER := 0;
pragma autonomous_transaction;
BEGIN
SELECT count(id_edition) into rem_count FROM FILM_EDITION WHERE id_storage = id_from;
update film_edition
set id_storage = id_to
where id_storage = id_from;
commit;
return rem_count;
END;

PROCEDURE ClearAndArchiveRecords(did NUMBER) AS
cursor to_del_titles IS 
SELECT id_content
FROM film_edition
WHERE id_storage = did and (select count(id_edition) FROM film_edition ed WHERE ed.id_content=id_content) < 1;
tof NUMBER;
BEGIN
MERGE INTO deleted_archive a
USING (SELECT id_edition, filename, title, film_year FROM FILM_EDITION INNER JOIN FILMCONTENT ON ID_CONTENT=FC_ID WHERE id_storage=did) d
ON (a.id_edition = d.id_edition)
WHEN NOT MATCHED THEN INSERT 
--(a.id_storage, a.s_owner, a.return_date)
VALUES(d.id_edition, d.filename, d.title, d.film_year);
open to_del_titles;
DELETE FROM film_edition
WHERE id_storage=did;
LOOP
EXIT WHEN to_del_titles%notfound;
fetch to_del_titles into tof;

DELETE FROM filmcontent
WHERE fc_id = tof;
END LOOP;
close to_del_titles;
END;

function GetReturns(d_id NUMBER) RETURN NUMBER
AS
ret_date DATE := NULL;
BEGIN
SELECT return_date
INTO ret_date
FROM video_storage
WHERE id_storage = d_id;
if ret_date IS NULL THEN
return NULL;
END IF;
return trunc(ret_date - current_date + 1);
END;

function CheckReturns(d_id NUMBER)
RETURN boolean
AS
return_in NUMBER := 0;
BEGIN
return_in := GetReturns(d_id);
return return_in >= 0;
END;

END VideoManage ;
/
