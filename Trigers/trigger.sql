UPDATE SALS
SET MINSAL=500;

SELECT * FROM SORD;
select * FROM SCUST;
--1. ������� �������, ����������� ��������� ������ � ����������� � ������� EMP � ��������� �����.
create or replace trigger CheckWorkingTime
before insert or update or delete on EMP
BEGIN
if (extract (hour from cast (systimestamp as timestamp)) < 12 or extract (hour from cast (systimestamp as timestamp)) > 20)
then
RAISE_APPLICATION_ERROR(-20212, '������ ������ �������� ������!');
END IF;
END;


SELECT * FROM EMP;
INSERT INTO EMP VALUES(7888, 'BIBA', 'SALESMAN', 7839, '19.04.77', 1400, 0, 10);

--2. ������� �������, ����������� ��������� ������� SCUST � ������������ ������� H_SCUST.
create sequence hscust_nom;
create table H_SCUST (
NOM NUMBER(3) default hscust_nom.nextval,
 S_DATE DATE,
 D_TAB  VARCHAR2(16),
 D_TIP VARCHAR2(16),
 CUSTID NUMBER(4)
);
create or replace trigger FixChange
before insert or update or delete on SCUST
for each row
declare 
cust_id number;
begin

if inserting then
insert into H_SCUST(S_DATE, D_TAB, D_TIP, CUSTID) values (sysdate, 'SCUST', 'INSERT', :new.custid);
end if;

if updating then
insert into H_SCUST(S_DATE, D_TAB, D_TIP, CUSTID) values (sysdate, 'SCUST', 'UPDATE', :new.custid);
end if;

if deleting then
insert into H_SCUST(S_DATE, D_TAB, D_TIP, CUSTID) values (sysdate, 'SCUST', 'DELETE', :old.custid);
end if;
end;
/

SELECT * FROM SCUST;
INSERT INTO SCUST values(200, '��� ���������', 666666, '�����', '������������ ������', 666666, 200);

SELECT * FROM H_SCUST;
SELECT * FROM SPROD;
SELECT * FROM ORD_PROD;

--3. ������� �������,  ������� ��� ���������� ������ ������ � ������� SORD ��������� �������  ���������� � ������ ��������� � ������� SCUST
create or replace trigger CheckCustomer
before insert on SORD
for each row
declare
cnt number;
begin
select count(*) into cnt from SCUST
where :new.custid=custid;
if cnt = 0 then
RAISE_APPLICATION_ERROR(-20212,'�������� ����������');
end if;
end;
/
insert into SORD (ORDERDATE, CUSTID, SHIPDATE, SUMMA)
values ('12.12.1990', 0, '10.02.2002', 10);

--4. ������� �������, ������� ��������� �������������� ����� � ������� ORD_PROD  �� �������� ������, ���� ���������� ����� ������  � ������� SPROD ���������� ������ 10 ������.
create table ord_prod (
PRODID NUMBER(6),
 DESCRIP CHAR(40),
 QTY NUMBER(5)
);

create or replace trigger OrderAdder
before insert or update on SPROD
for each row
when (new.p_qty < 10)
begin
insert into ord_prod values (:new.prodid, :new.descrip, 20 - :new.p_qty);
end;
/

SELECT * FROM EMP;
SELECT * FROM SALS;

--5. ������� �������,  �������  ��������� ������������� ������� ����������� �������� � ������� SALS  ���� 600
create or replace trigger CheckMinSalary
before insert or update of minsal on SALS
for each row
when (new.minsal < 600)
BEGIN
RAISE_APPLICATION_ERROR(-20212, '����������� ������ ������������ �������');
END;
/

--6.  ������� �������,  ������� ��� ���������� ������ ��������� � ������� 
--EMP ��� ��� ��������� ��������� ��� ������ ������-���� ��������� ������������, ��� �������� �������� � �������, ������������� ��� ������ ��������� � ������� SALS.
create or replace trigger CheckSalaryOk
before insert or update of deptno, job on emp
for each row
declare 
min_possible_salary number;
max_possible_salary number;
begin
select minsal, maxsal
into min_possible_salary, max_possible_salary
from SALS
where jobs=:new.job;
if :new.sal < min_possible_salary then
RAISE_APPLICATION_ERROR(-20212,'�������� �� ������ ���� ������ �����������!');
end if;
if :new.sal > max_possible_salary then 
RAISE_APPLICATION_ERROR(-20212,'�������� �� ������ ���� ������ ������������!');
end if;
end;
/
select * from emp;
insert into emp values(9999, 'Bebe', 'CLERK', 7839, sysdate, 10000, NULL, 10);
select systimestamp from dual;

--7. ������� �������,  ������� ��� ���������� ������ ��������� � ������� SCUST ������ ��������������� ��������� � ������� CR_SCUST.
SELECT * FROM SCUST;
create table CR_SCUST (
 CUSTID  NUMBER(4) primary key,
 DEBET   NUMBER(9),
 CREDIT  NUMBER(7)
);
create or replace trigger Crediting
after insert on scust
for each row
begin
INSERT INTO CR_SCUST
VALUES(:new.custid, :new.predoplata, 2000);
end;
/
INSERT INTO SCUST
VALUES (222, '������ ����', 234323, '�����', '��. ������', 234432, 5000);
SELECT * FROM CR_SCUST;

--8. ������� �������,  ������� ��� ���������� ������ ������  � ������� SITEM ������������ ����� ������ � ������� SORD.
SELECT * FROM SITEM;
SELECT * FROM SORD;

create or replace trigger CountSum
after insert on SITEM
FOR EACH ROW
declare remid number;
begin
select ordid
into remid
from sord
where ordid = :new.ordid;
if remid is null then
INSERT INTO SORD(ordid, orderdate, summa)
VALUES(:new.ordid, sysdate, :new.summa);
else
update sord
set sord.summa = sord.summa + :new.summa
where ordid = remid;
end if;
end;
/

INSERT INTO SITEM VALUES (
610, 10001, 60, 30, 1800);
SELECT * FROM SORD;