create TABLE DELETED_ARCHIVE (
id_edition NUMBER(5),
filename VARCHAR2(250),
title VARCHAR2(200),
film_year NUMBER(4)
);
create or replace editionable package VideoManage AS
type ARR_FILE is VARRAY (200) of VARCHAR2(250);
Function GetDiskInfo(did NUMBER) RETURN ARR_FILE;
Function MoveRecords(id_from NUMBER, id_to NUMBER) return NUMBER;
PROCEDURE ClearAndArchiveRecords(did NUMBER);
function CheckReturns(d_id NUMBER) RETURN boolean;
function GetReturns(d_id NUMBER) RETURN NUMBER;
END VideoManage;
/
