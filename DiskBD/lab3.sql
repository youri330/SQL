--1.Процедура контроля сроков возврата. Входной параметр – номер или название диска. 
-- Выходной параметр – количество дней до срока возврата или на сколько просрочен диск.

create or replace procedure ControlReturn(d_id NUMBER default NULL, d_name VARCHAR2 default NULL, left_days OUT NUMBER)
AS
s_id NUMBER := NULL;
ret_date DATE := NULL;
BEGIN
s_id := d_id;
if s_id IS NULL THEN
SELECT ID_STORAGE
INTO s_id
FROM FILM_EDITION
WHERE FILENAME = d_name;
END IF;
SELECT return_date
INTO ret_date
FROM storage_device
WHERE id_storage = s_id;
if ret_date IS NULL THEN
left_days := NULL;
ELSE
left_days:= ret_date - sysdate + 1);
END IF;
END;

/

DECLARE
left_days NUMBER := 0;
BEGIN
ControlReturn(5, NULL, left_days);
dbms_output.put_line(left_days);
END;

--2. Процедура перезаписи фильмов на носители большей емкости. Входные параметры – тип и емкость носителя.
-- Действие процедуры – фильмы, находящиеся на носителях указанного типа перенести на носители такого же типа большей емкости. 
-- Выходной параметр – количество фильмов, которые были перенесены на другие носители.
create or replace procedure MoveRecords(d_type VARCHAR2, d_volume NUMBER, moved OUT NUMBER)
AS
CURSOR good_cursor IS
SELECT id_storage
FROM video_storage
WHERE s_type=d_type AND s_volume > d_volume;
CURSOR bad_cursor IS
SELECT id_storage
FROM storage_device
WHERE s_type=d_type AND s_volume=d_volume;
good_id NUMBER;
bad_id NUMBER;
bad_step NUMBER;
BEGIN
OPEN good_cursor;
OPEN bad_cursor;
moved := 0;
LOOP
EXIT WHEN good_cursor%NOTFOUND OR bad_cursor%NOTFOUND;
FETCH bad_cursor into bad_id;

SELECT count(id_edition)
INTO bad_step
FROM film_edition
WHERE id_storage=bad_id;
moved := moved + bad_step;

if bad_step > 0 THEN

FETCH good_cursor into good_id;
UPDATE FILM_EDITION
SET ID_STORAGE = good_id
WHERE id_storage=bad_id;
END IF;

END LOOP;
CLOSE good_cursor;
CLOSE bad_cursor;

END MoveRecords;

/
DECLARE
num_moved NUMBER := 0;
BEGIN
MoveRecords('Disc', 2000, num_moved);
dbms_output.put_line(num_moved);
END;
/


--3.Процедура для архивирования записей о передаче носителей во временное пользование. 
-- Входных параметров нет. Действие процедуры – из таблицы удалить записи о передаче носителей во временное пользование, которые были возвращены более месяца назад. 
-- В архивной таблице сохранить следующие сведения: название или номер носителя, имя пользователя, количество дней, на сколько выдавался носитель.
-- Выходной параметр – количество архивных записей.
create table storage_archive(
id_storage NUMBER(2),
s_owner VARCHAR2(200),
return_date DATE);

create or replace procedure AlterAndDrop(num_records OUT NUMBER) AS
BEGIN
select count(id_storage)
INTO num_records
FROM borrowed
WHERE return_date < current_date;

MERGE INTO storage_archive a
USING (SELECT id_storage, s_owner, return_date FROM borrowed WHERE return_date < current_date) d
ON (a.id_storage = d.id_storage)
WHEN NOT MATCHED THEN INSERT (a.id_storage, a.s_owner, a.return_date)
VALUES(d.id_storage, d.s_owner, d.return_date);
delete from storage_device
where id_storage in (select id_storage from video_storage where return_date < current_date);
delete from borrowed where return_date < current_date;
END AlterAndDrop;
/

DECLARE
deleted NUMBER :=0;
BEGIN
AlterAndDrop(deleted);
dbms_output.put_line(deleted);
END;
/