--8. Создайте процедуру регистрации нового пациента. Входные параметры: фамилия, имя, отчество пациента, адрес (необязательный параметр). Выходные параметры – нет. 
--Действие процедуры: формирование новой строки и вставка соответствующих значений в таблицу H_Patient. При формировании номера карты учитывать адрес пациента. 
--Пациенты из Артемовска, Черноморска, Верхнехолмска и Южногорска относятся к участку №1. Пациенты из
--Бердянска, Прокопьевска, Криворукова и Урюпинска – к участку №2. Прочие пациенты регистрируются на участке №3. Протестируйте процедуру с различными вариантами входных параметров.
CREATE SEQUENCE SEQ_Patient_3R
  START WITH 316001
  MAXVALUE 316999
  increment by 1;

CREATE OR REPLACE PROCEDURE hr_newpatient(
    surname VARCHAR2,
    firstname VARCHAR2,  
    middle_name VARCHAR2, 
    address VARCHAR2,
    phone VARCHAR2  
    ) 
    IS new_ncard INTEGER;
    BEGIN
      IF address IN ('г. Артемовск', 'г. Черноморск', 'г. Верхнехолмск', 'г. Южногорск') THEN
      new_ncard := SEQ_PATIENT_1R.NEXTVAL;
      END IF; 
      IF address IN ('г. Бердянск', 'г. Прокопьевск', 'г. Криворуков', 'г. Урюпинск') THEN
      new_ncard := SEQ_PATIENT_2R.NEXTVAL;
      ELSE
      new_ncard := SEQ_PATIENT_3R.NEXTVAL;
      END IF;
      INSERT INTO hr_patient
      VALUES
      (
         new_ncard,
         surname, 
         firstname,
         middle_name,
         address,
         phone
       );      
     END;

--вызов для проверки пациента, приписанного ко второму участку
BEGIN
    hr_newpatient('Иванов', 'Иван', 'Иванович', 'г. Мурск', '+375256788098'); 
END; 

--вызов для проверки пациента, приписанного к первому участку
BEGIN
    hr_newpatient('Иванов', 'Иван', 'Иванович', 'г. Артёмовск', '+375256788098'); 
END; 

--1. Создайте функцию, вычисляющую премию за всё время начислений для конкретного сотрудника. Входной параметр – фамилия или идентификатор сотрудника. Выходной параметр – значение суммы премии.
CREATE OR REPLACE FUNCTION premium(doctor_id IN NUMBER)
RETURN NUMBER
IS
amnt NUMBER;
BEGIN
    SELECT count(distinct hr_visit.date_visit) * 200 as working_days 
    INTO amnt
    FROM hr_doctor  
    JOIN hr_visit ON hr_doctor.id_doctor = hr_visit.id_doctor 
    WHERE hr_doctor.id_doctor = doctor_id;
    RETURN amnt;
END;

EXEC DBMS_OUTPUT.PUT_LINE(premium(65)); 

    
--2. Создайте функцию, вычисляющую сумму оплаты за услуги для конкретного пациента за указанный период. Входные параметры – фамилия или номер карты пациента, начало и конец периода (необязательный).
--Выходной параметр – значение суммы. Протестировать функцию с различными вариантами входных параметров.
CREATE OR REPLACE FUNCTION periodsum(patient_id IN NUMBER, startTime DATE, endTime DATE DEFAULT sysdate)
RETURN NUMBER
AS 
amnt NUMBER;
BEGIN
    SELECT SUM(hr_services.price) 
    INTO amnt
    FROM hr_patient 
    JOIN hr_visit ON hr_patient.n_card = hr_visit.id_patient
    JOIN hr_services ON hr_services.code_srv = hr_visit.code_srv
    WHERE hr_patient.n_card = patient_id AND hr_visit.date_visit >= startTime AND hr_visit.date_visit <= endTime;
RETURN amnt;
END;


EXEC DBMS_OUTPUT.PUT_LINE(periodsum(216021, to_date('2022-09-19', 'YYYY-MM-DD'), NULL)); 

--3. Создайте функцию для вычисления размера скидки при оплате услуг для указанного пациента. Входные параметры – фамилия или номер карты пациента. Выходной параметр – размер скидки в процентах. 
--Размер скидки определяется следующим образом: 
--если общая сумма оплаты за услуги составляет менее 50 руб. – размер скидки 3%; от 50 до 100 руб. – 10%; от 100 до 200 руб. – 20%; от 200 до 400 руб. – 30%; свыше 400 руб. – 40%.

CREATE OR REPLACE VIEW patient_amnt AS
SELECT hr_patient.n_card AS id, SUM(hr_services.price) AS amnt
FROM hr_patient
JOIN hr_visit ON hr_patient.n_card = hr_visit.id_patient
JOIN hr_services ON hr_services.code_srv = hr_visit.code_srv
GROUP BY hr_patient.n_card;

SELECT *
FROM patient_amnt;

CREATE OR REPLACE FUNCTION discount(patient_id IN NUMBER)
RETURN NUMBER
AS 
discount NUMBER;
amnt NUMBER;
BEGIN
    SELECT patient_amnt.amnt
    INTO amnt
    FROM patient_amnt
    WHERE patient_amnt.id = patient_id;
    
    IF amnt < 50 THEN RETURN 3;
    ELSIF amnt between 50 and 100 THEN RETURN 10;
    ELSIF amnt between 100 and 200 THEN RETURN 20;
    ELSIF amnt between 200 and 400 THEN RETURN 30;
    ELSE RETURN 40;
    END IF;
END;

EXEC DBMS_OUTPUT.PUT_LINE(discount(216021)); 

--4. Создайте функцию определения количества принятых специалистом пациентов. Входные параметры – фамилия или идентификатор сотрудника. Выходной параметр – количество пациентов.
CREATE OR REPLACE VIEW doctor_visit_amnt AS
SELECT hr_doctor.id_doctor id, COUNT(hr_visit.n_visit) amnt
FROM hr_doctor
JOIN hr_visit  ON hr_doctor.id_doctor = hr_visit.id_doctor
GROUP BY hr_doctor.id_doctor;

SELECT *
FROM doctor_visit_amnt;

CREATE OR REPLACE FUNCTION patdoc_amount(doctor_id IN NUMBER)
RETURN NUMBER
AS
amnt NUMBER;
BEGIN
    SELECT hr_doctor.amnt 
    INTO amnt
    FROM doctor_visit_amnt 
    WHERE hr_doctor.doctor_id = doctor_id;
RETURN amnt;
END;

EXEC DBMS_OUTPUT.PUT_LINE(patdoc_amount(65)); 

--5. Создайте функцию, вычисляющую максимальную разность количества принятых специалистом пациентов за определенный период. Входные параметры – начальная дата, конечная дата
--(необязательный параметр).
--Выходной параметр – максимальная разность количества пациентов и фамилии специалистов.
create or replace type query_5 as object
(
    min_patients varchar2(30),
    max_patients varchar2(30),
    total_patients_diff number
);

create or replace type result_table_5 as table of query_5;

create or replace function getMaxPatientsCountDifference(start_date varchar2, end_date varchar2 default '29-SEP-22')
return result_table_5
as
    result5 result_table_5;
is 
    max_count number := 0;
    min_count number := 0;
    cur_count number := 0;
begin
    with subquery as (select hr_doctor.id_doctor, hr_doctor.surname as surname, count(distinct id_patient) as cur_count,
    min(count(distinct id_patient)) as min_count, max(count(distinct id_patient)) as max_count
    from hr_doctor inner join hr_visit
    on hr_doctor.id_doctor = hr_visit.id_doctor
    and hr_visit.date_visit between to_date(startdate, 'dd-mm-yy') and to_date(enddate, 'dd-mm-yy'))
    select (select surname from subquery where cur_count = min_count and rownum = 1),
    (select surname from subquery where cur_count = max_count and rownum = 1),
    (select max_count - min_count from subquery) bulk collect into result5
    from dual;

    return result5;
end;

select getMaxPatientsCountDifference('11-SEP-22') from dual;


--6. Составьте процедуру начисления премии специалистам. Премия начисляется из суммарной стоимости услуг, оказанных этим специалистом пациентам. Правила начисления: 
--если суммарная стоимость до 50 руб. – премия в размере 10% от суммы; от 50 до 100 руб. – 15%; от 100 до 400 руб. – 30%;
--более 400 руб. – 50%. Входные параметры: фамилия специалиста, идентификатор, специальность, период начисления, без параметров. 
--Выходные параметры – нет. Действие процедуры:
--если указана фамилия или идентификатор – начисление премии указанному сотруднику за весь период и запись значения в соответствующей строке; если указана специальность – 
--начисление всем сотрудникам указанной специальности за весь период и запись значений в соответствующих строках; 
--если входной параметр не указан – начисление всем сотрудникам за весь период и запись значений в соответствующих строках.
--Необходимые предварительные действия: с помощью команды ALTER TABLE H_Doctor добавьте в структуру таблицы столбец bonus, тип NUMBER(9,2). Протестируйте процедуру с различными вариантами входных параметров. Сравните результат.

CREATE OR REPLACE FUNCTION summ_prices(doctor_id IN NUMBER)
RETURN NUMBER
IS
amnt NUMBER;
BEGIN
    SELECT sum(hr_services.price) as total_price
    INTO amnt
    FROM hr_doctor  
    JOIN hr_visit ON hr_doctor.id_doctor = hr_visit.id_doctor  
    JOIN hr_services ON hr_visit.code_srv = hr_services.code_srv
    WHERE hr_doctor.id_doctor = doctor_id;
    RETURN amnt;
END;

EXEC DBMS_OUTPUT.PUT_LINE(premium(65));

ALTER TABLE hr_doctor ADD bonus NUMBER(9,2);

CREATE OR REPLACE FUNCTION CountBonus_f
(Doctor_Surname IN varchar2,Begin_Date IN Date DEFAULT NULL, End_Date IN Date DEFAULT sysdate)
RETURN number IS
pragma autonomous_transaction;
temp number;
bonus number;
BeginSearch Date := Begin_Date;
EndSearch Date := End_Date;
BEGIN

IF BeginSearch IS NULL THEN
    SELECT min(DATE_VISIT) INTO BeginSearch FROM hr_Visit;
END IF;

IF EndSearch IS NULL THEN
    SELECT max(DATE_VISIT) INTO EndSearch FROM hr_Visit;
END IF;

WITH
    Doctors_Income AS (
        SELECT sum(Price) AS Income,Surname
        FROM hr_Visit
             JOIN hr_Doctor ON hr_Doctor.ID_Doctor=hr_Visit.ID_Doctor
             JOIN hr_Services ON hr_Services.Code_Srv=hr_Visit.Code_Srv
        WHERE Date_Visit BETWEEN TO_DATE(BeginSearch,'dd.mm.yy') AND TO_DATE(EndSearch,'dd.mm.yy')
        GROUP BY Surname
    )
SELECT Income
INTO bonus
FROM Doctors_Income
WHERE Surname=Doctor_Surname;

IF bonus < 50 THEN temp:=10;
ELSIF bonus >=50 AND bonus < 100 THEN temp:=15;
ELSIF bonus>=100 AND bonus < 400 THEN temp:=30;
ELSE temp:=50;
END IF;

return (bonus*temp)/100;
END;

CREATE OR REPLACE PROCEDURE premium_count
(DoctorSurname IN varchar2 DEFAULT NULL, Speciality IN varchar2 DEFAULT NULL,
Begin_Date IN Date DEFAULT NULL, End_Date IN Date DEFAULT sysdate)
IS
BEGIN

IF DoctorSurname IS NOT NULL THEN
    UPDATE hr_Doctor SET Bonus=CountBonus_f(DoctorSurname,Begin_Date,End_Date)
    WHERE hr_Doctor.Surname=DoctorSurname;
ELSIF Speciality IS NOT NULL THEN
    UPDATE hr_Doctor SET Bonus=CountBonus_f(hr_Doctor.Surname,Begin_Date,End_Date)
    WHERE hr_Doctor.Code_Spec=(SELECT Code_Spec FROM hr_Services WHERE Title=Speciality);
ELSE
    UPDATE hr_Doctor SET Bonus=CountBonus_f(hr_Doctor.Surname,Begin_Date,End_Date);
END IF;

END;

EXECUTE premium_count();


--7. Создайте процедуру зачисления нового сотрудника. Входные параметры: фамилия, имя, отчество сотрудника, специальность (необязательный параметр). 
--Выходные параметры – нет. Действие процедуры: формирование новой строки и вставка соответствующих значений в таблицу H_Doctor,
--если указанная специальность отсутствует в справочнике, добавить сведения об этой специальности в таблице H_Specialty. 
--Если специальность не указана, нового сотрудника зачислить в качестве интерна. Одного из интернов при этом перевести на вакантную специальность

CREATE OR REPLACE PROCEDURE new_doctor
(DoctorSurname IN varchar2,DoctorName IN varchar2, DoctorMiddleName IN varchar2 DEFAULT NULL,
Speciality IN NUMBER)
IS
DoctorId number;
BEGIN

IF Speciality IS NOT NULL THEN

    SELECT COUNT(Code_Spec)
    INTO CodeSpec
    FROM hr_Speciality
    WHERE Title=Speciality;

    INSERT INTO hr_Doctor VALUES (SEQ_DOC.nextval,DoctorSurname,DoctorName,DoctorMiddleName,CodeSpec,NULL);
    ELSE
    WITH
    DoctorsInfo AS(
        SELECT hr_Speciality.Code_Spec,
        COUNT(ID_Doctor) OVER(PARTITION BY hr_Speciality.Code_Spec ORDER BY hr_Speciality.Code_Spec) AS Amnt
        FROM hr_Speciality
        LEFT JOIN hr_Doctor ON hr_Doctor.Code_Spec=hr_Speciality.Code_Spec
    )
    SELECT Code_Spec
    INTO CodeSpec
    FROM DoctorsInfo
    WHERE Amnt=(SELECT MIN(Amnt) FROM DoctorsInfo) AND ROWNUM=1;

    SELECT ID_Doctor
    INTO DoctorID
    FROM hr_Doctor
    WHERE Code_Spec=1408 AND ROWNUM=1;

    UPDATE hr_Doctor SET Code_Spec=Code_Spec
    WHERE ID_Doctor=DoctorID;

    INSERT INTO hr_Doctor VALUES (SEQ_DOC.nextval,DoctorSurname,DoctorName,DoctorMiddleName,1408,NULL);
END IF;
END;

EXECUTE  new_doctor('Иванов','Иван','Иванович',1421);

--9. Создайте процедуру для переноса визитов на другую дату. Входные параметры: начальная дата, конечная дата. 
--Выходной параметр – количество перенесенных визитов. Действие процедуры: изменение значения столбца Date_Visit в таблице H_Visit с начальной даты на конечную. Протестируйте процедуру.
CREATE OR REPLACE PROCEDURE rearrangment(OldDate IN Date, NewDate IN Date, Counter OUT number)
IS
BEGIN
    SELECT COUNT(*)
    INTO Counter
    FROM hr_visit
    GROUP BY Date_Visit
    HAVING Date_Visit = OldDate;

    UPDATE hr_visit SET Date_Visit=NewDate
    WHERE Date_Visit=OldDate;
END;

DECLARE
    c number;
BEGIN
    rearrangment(TO_DATE('12.09.22','dd.mm.yy'),TO_DATE('13.09.22','dd.mm.yy'),c);
    dbms_output.put_line('Replaced : ' || c);
END;

--10. Создайте процедуру для удаления сведений о визитах, состоявшихся в указанный период. Входной параметр: количество дней периода (необязательный). 
--Выходной параметр – количество удаленных строк. Действие процедуры: формирование строк архивной таблицы для сохранения информации о визитах 
--(дата визита, специальность, ФИО специалиста, количество принятых пациентов, суммарная стоимость оказанных услуг); 
--удаление строк в таблице H_Visit, где дата входит в период указанного количества дней, начиная с первой даты визита. Протестируйте процедуру.
CREATE TABLE Visit_Archive
    (
     visit NUMBER (6)  NOT NULL ,
     doctor_id NUMBER (4) ,
     patient_id NUMBER (6) ,
     date_visit DATE ,
     code_srv NUMBER (4)
    )

CREATE OR REPLACE PROCEDURE visit_delete(Date_Period IN number DEFAULT NULL, Counter OUT number)
IS
Erased number;
BeginDate Date;
EndDate Date;
BEGIN
    SELECT MIN(Date_Visit)
    INTO BeginDate
    FROM H_Visit;

    IF Date_Period IS NULL THEN
        SELECT MAX(Date_Visit)
        INTO EndDate
        FROM H_Visit;
    ELSE
        EndDate := BeginDate+Date_Period;
    END IF;

    SELECT COUNT(*)
    INTO Counter
    FROM H_Visit
    WHERE Date_Visit BETWEEN BeginDate AND EndDate;

    INSERT INTO Visit_Archive SELECT * FROM H_Visit WHERE Date_Visit BETWEEN BeginDate AND EndDate;

    DELETE FROM H_Visit
    WHERE Date_Visit BETWEEN BeginDate AND EndDate;

    END;

DECLARE
    c number;
BEGIN
    Procedure10(10,c);
    dbms_output.put_line('Replaced : ' || c);
END;

SELECT * FROM Visit_Archive;