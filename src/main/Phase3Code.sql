set serveroutput on;

DROP TRIGGER PrintAfterAdmission;
DROP TRIGGER newEquipmentNeedsInspection;
DROP TRIGGER AutoFutureVisitDateEmergency;
DROP TRIGGER InsertSupervisor;
DROP TRIGGER AutoInsurancePercent;
DROP TRIGGER VisitComments;
DROP VIEW DoctorsLoad;
DROP VIEW CriticalCases;
DROP TABLE RoomToAdmission;
DROP TABLE DoctorExaminesAdmission;
DROP TABLE TechWorksWithType;
DROP TABLE EmployeeCanAccessRoom;
DROP TRIGGER UpdateAdmissionNum;
DROP TRIGGER AddAdmissionNum;
DROP TRIGGER NoNullAdmissionNum;
DROP TABLE AdmissionNumber;
DROP TABLE Admission;
DROP TABLE Patient;
DROP TABLE EquipmentUnit;
DROP TABLE EquipmentType;
DROP TABLE Services;
DROP TABLE Room;
DROP TABLE EquipmentTechnician;
DROP TABLE Doctor;
DROP TABLE Employee;


CREATE TABLE Employee (
    JobTitle Varchar2(1000),
    FirstName Varchar2(1000) NOT NULL,
    LastName Varchar2(1000) NOT NULL,
    Salary Real,
    EmployeeID INTEGER PRIMARY KEY,
    OfficeNumber INTEGER UNIQUE,
    Street Varchar2(1000),
    Town Varchar2(1000),
    Zip CHAR(5),
    ManagerID INTEGER,
    EmployeeLevel Varchar(30) NOT NULL,
    FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeID)
        ON DELETE CASCADE,
    CONSTRAINT employee_salary_ck CHECK (Salary > 0),
    CONSTRAINT employee_employeeid_ck CHECK (EmployeeID > 0),
    CONSTRAINT employee_officenum_ck CHECK (OfficeNumber > 0)
);



CREATE TABLE Doctor(
    EmployeeID INTEGER PRIMARY KEY,
    MedicalSchoolAttended Varchar2(1000) NOT NULL,
    Gender Varchar2(10),
    Specialty Varchar2(1000),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
       ON DELETE CASCADE
);



CREATE TABLE EquipmentTechnician(
    EmployeeID INTEGER PRIMARY KEY,
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
        ON DELETE CASCADE
);


CREATE TABLE Room(
    RoomNumber INTEGER PRIMARY KEY,
    Occupied INTEGER NOT NULL,
    CONSTRAINT room_roomnumber_ck CHECK (RoomNumber > 0),
    CONSTRAINT room_Occupied_ck CHECK (Occupied in ('0','1'))
);


CREATE TABLE Services(
    RoomNumber INTEGER,
    Service Varchar2(1000),
    CONSTRAINT Services_PK PRIMARY KEY (RoomNumber, Service),
    FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
        ON DELETE CASCADE
);


CREATE TABLE EquipmentType(
    TypeID INTEGER PRIMARY KEY,
    Model Varchar2(100),
    OperationalInstructions Varchar2(2000),
    Description Varchar2(1000)
);



CREATE TABLE EquipmentUnit(
    YearOfPurchase INTEGER,
    LastInspectionTime timestamp,
    SerialNumber Varchar2(10),
    RoomNumber INTEGER,
    TypeID INTEGER,
    CONSTRAINT EquipmentUnit_PK PRIMARY KEY(SerialNumber, TypeID),
    FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
        ON DELETE CASCADE,
    FOREIGN KEY (TypeID) REFERENCES EquipmentType(TypeID)
        ON DELETE CASCADE,
    CONSTRAINT EUnit_YOP_ck CHECK (YearOfPurchase > 0)
);


CREATE TABLE Patient(
    SSN CHAR(9)  PRIMARY KEY,
    FirstName Varchar2(1000) NOT NULL,
    LastName Varchar2(1000) NOT NULL,
    Street Varchar2(1000),
    Town Varchar2(1000),
    Zip CHAR(5),
    TelephoneNumber CHAR(10)
);

CREATE TABLE Admission(
    VisitCost REAL NOT NULL,
    PercentInsurance REAL NOT NULL,
    StartDate timestamp,
    FutureVisitDate timestamp,
    EndDate timestamp,
    SSN CHAR(9),
    CONSTRAINT Admission_PK PRIMARY KEY (StartDate, SSN),
    FOREIGN KEY (SSN) REFERENCES Patient(SSN)
        ON DELETE CASCADE,
    CONSTRAINT admission_visitcost_ck CHECK (VisitCost > 0),
    CONSTRAINT admission_percentinsurance_ck CHECK ((0 <= PercentInsurance) AND (PercentInsurance <= 100))
);


CREATE TABLE AdmissionNumber(
    AdmissionNum INTEGER UNIQUE,
    StartDate timestamp,
    SSN CHAR(9),
    CONSTRAINT AdmissionNumber_PK PRIMARY KEY (StartDate, SSN),
    FOREIGN KEY (StartDate, SSN) REFERENCES Admission(StartDate, SSN)
        ON DELETE CASCADE
);

CREATE TRIGGER NoNullAdmissionNum
    BEFORE INSERT ON AdmissionNumber
    FOR EACH ROW
BEGIN
    IF(:new.AdmissionNum is NULL) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Please add a comment to your examination');
END IF;
END;
/

CREATE TRIGGER AddAdmissionNum
    AFTER INSERT ON Admission
    FOR EACH ROW
DECLARE
cnt INTEGER;
BEGIN

SELECT COUNT(*) into cnt
FROM AdmissionNumber;

IF (cnt != 0) THEN
SELECT MAX(AdmissionNum) into cnt
FROM AdmissionNumber;
END IF;

INSERT INTO AdmissionNumber VALUES(cnt + 1, :new.StartDate, :new.SSN);

END;
/


CREATE TRIGGER UpdateAdmissionNum
    BEFORE UPDATE ON Admission
    FOR EACH ROW
BEGIN

    UPDATE AdmissionNumber SET SSN = :new.SSN, StartDate = :new.StartDate WHERE StartDate = :old.StartDate AND SSN = :old.SSN;

END;
/


CREATE TABLE EmployeeCanAccessRoom (
    EmployeeID INTEGER,
    RoomNumber INTEGER,
    CONSTRAINT EmployeeCanAccessRoom_PK PRIMARY KEY (EmployeeID, RoomNumber),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
        ON DELETE CASCADE,
    FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
        ON DELETE CASCADE
);


CREATE TABLE TechWorksWithType(
    EmployeeID INTEGER,
    TypeID INTEGER,
    CONSTRAINT TechWorksWithType_PK PRIMARY KEY (EmployeeID, TypeID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
        ON DELETE CASCADE,
    FOREIGN KEY (TypeID) REFERENCES EquipmentType(TypeID)
        ON DELETE CASCADE
);



CREATE TABLE DoctorExaminesAdmission (
    EmployeeID INTEGER,
    StartDate timestamp,
    DoctorsComments Varchar(2000),
    SSN CHAR(9),
    CONSTRAINT DoctorExaminesAdmission_PK PRIMARY KEY (EmployeeID, StartDate, DoctorsComments, SSN),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
        ON DELETE CASCADE,
    FOREIGN KEY (StartDate, SSN) REFERENCES Admission(StartDate, SSN)
        ON DELETE CASCADE
);



CREATE TABLE RoomToAdmission (
    StartDate timestamp NOT NULL,
    EndDate timestamp NOT NULL,
    RoomNumber INTEGER,
    AdmissionStartDate timestamp,
    SSN CHAR(9),
    CONSTRAINT RoomToAdmission_PK PRIMARY KEY (RoomNumber, AdmissionStartDate, SSN),
    FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
        ON DELETE CASCADE,
    FOREIGN KEY (AdmissionStartDate, SSN) REFERENCES Admission(StartDate, SSN )
        ON DELETE CASCADE
);





-- Trigger #1:-----------------------------
/*
	- If a doctor visits a patient in the ICU, they must leave a comment.
*/
CREATE TRIGGER VisitComments
    BEFORE INSERT ON DoctorExaminesAdmission
    FOR EACH ROW
BEGIN
    IF (:new.DoctorsComments IS NULL) THEN
		RAISE_APPLICATION_ERROR(-20004, 'Please add a comment to your examination');
END IF;
END;
/


-- Trigger #2:	-----------------------------
/*
	- The insurance payment should be calculated automatically as 65 percent of the total payment. If the total payment changes, then the insurance amount should also change.
	- If in your DB you store the insurance payment as a percent, then it should be always set to 65 percent.
*/
CREATE TRIGGER AutoInsurancePercent
    BEFORE INSERT ON Admission
    FOR EACH ROW
BEGIN
    :new.PercentInsurance := 65;
END;
/


-- Trigger #3/#4 : -----------------------------
/*
	- Ensure that regular employees (with rank 0) must have their supervisors as division managers (with rank 1). Also, each regular employee
		must have a supervisor at all times.
	- Similarly, division managers (with rank 1) must have their supervisors as general managers (with rank 2). Division managers must have supervisors
		at all times. General Managers must not have any supervisors.
*/

CREATE TRIGGER InsertSupervisor
    BEFORE INSERT ON Employee
    FOR EACH ROW
DECLARE
    managerType Varchar(30);
    cnt INTEGER;
BEGIN

    SELECT COUNT(*) into cnt
    FROM Employee
    WHERE EmployeeID = :new.ManagerID;


    IF(:new.EmployeeLevel = 'Regular') THEN

            IF(:new.ManagerID IS NULL) THEN
                RAISE_APPLICATION_ERROR(-20004, 'Regular managers must have supervisors at all times');
    END IF;


            IF(cnt != 0) THEN

    SELECT EmployeeLevel into managerType
    FROM Employee
    WHERE EmployeeID = :new.ManagerID;

    IF('Division' != managerType) THEN
                    RAISE_APPLICATION_ERROR(-20004, 'Manager must be a Division Manager');
    END IF;

    END IF;

    END IF;


        IF(:new.EmployeeLevel = 'Division') THEN

            IF(:new.ManagerID IS NULL) THEN
                RAISE_APPLICATION_ERROR(-20004, 'Division managers must have supervisors at all times');
    END IF;

            IF(cnt != 0) THEN

    SELECT EmployeeLevel into managerType
    FROM Employee
    WHERE EmployeeID = :new.ManagerID;

    IF('General' != managerType) THEN
                    RAISE_APPLICATION_ERROR(-20004, 'Manager must be a General Manager');
    END IF;

    END IF;

    END IF;

        IF(:new.EmployeeLevel = 'General') THEN

            IF(:new.ManagerID IS NOT NULL) THEN
                RAISE_APPLICATION_ERROR(-20004, 'General Managers must not have any supervisors');
    END IF;

    END IF;
END;
/




-- Trigger #5:-----------------------------
/*
	- When a patient is admitted to an Emergency Room (a room with an Emergency service) on date D, the futureVisitDate should be automatically
		set to 2 months after that date, i.e., D + 2 months. The futureVisitDate may be manually changed later, but when the Emergency Room admission
		happens, the date should be set to default as mentioned above.
*/

CREATE TRIGGER AutoFutureVisitDateEmergency
    AFTER INSERT ON RoomToAdmission
    FOR EACH ROW
DECLARE
    cnt INTEGER;

BEGIN

    SELECT COUNT(*) into cnt
    FROM    (SELECT Service
             FROM Services S
             WHERE S.RoomNumber =  :new.RoomNumber)
    WHERE Service = 'Emergency';


    IF(cnt != 0) THEN
    UPDATE Admission SET FutureVisitDate = (TO_TIMESTAMP(TO_CHAR(ADD_MONTHS(StartDate, 2), 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')) WHERE StartDate = :new.AdmissionStartDate AND SSN = :new.SSN;
    END IF;


END;
/


-- Trigger #6:-----------------------------
/*
	- When a new piece of equipment is purchased and it has not been inspected for over a month, check if there is an equipment technician who can service it.
		If there is, update the inspection date.
*/
CREATE TRIGGER newEquipmentNeedsInspection
    BEFORE INSERT ON EquipmentUnit
    FOR EACH ROW
DECLARE
    currentTimestamp DATE;
    dateExpectedBy DATE;

CURSOR UpdateableTypeIDs is
    SELECT TypeID
    FROM TechWorksWithType;

BEGIN
    SELECT TO_TIMESTAMP(TO_CHAR(ADD_MONTHS(SYSDATE, -2), 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS') INTO dateExpectedBy FROM dual;
    SELECT TO_TIMESTAMP(TO_CHAR(systimestamp, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS') INTO currentTimestamp FROM dual;

    FOR ID in UpdateableTypeIDs LOOP
            IF (ID.TypeID = :new.TypeID) THEN

                IF(:new.LastInspectionTime < dateExpectedBy) THEN
                    :new.LastInspectionTime := currentTimestamp;
    END IF;
    END IF;

    END LOOP;

END;
/


-- Trigger #7:-----------------------------
/*
	- When a patient leaves the hospital (admission leave time is set), print out the patient’s first and last name, address, all of the comments
		 from doctors involved in that admission, and which doctor (name) left each comment.
*/
CREATE TRIGGER PrintAfterAdmission
    BEFORE UPDATE OF EndDate ON Admission
    FOR EACH ROW
DECLARE

Cursor PatientInfo IS
    SELECT D.StartDate,  P.SSN, P.FirstName, P.LastName, P.Street, P.Town, P.Zip
    FROM Patient P,
        (SELECT DISTINCT StartDate, SSN
        FROM DoctorExaminesAdmission) D
    WHERE P.SSN = D.SSN;

Cursor DoctorInfo IS
    SELECT E.FirstName, E.LastName, D.EmployeeID, D.StartDate, D.DoctorsComments, D.SSN
    FROM Employee E, DoctorExaminesAdmission D
    WHERE E.EmployeeID = D.EmployeeID;

BEGIN

    FOR pInfo IN PatientInfo LOOP

            IF(pInfo.StartDate = :old.StartDate AND pInfo.SSN = :old.SSN) THEN

                dbms_output.put_line( ('Patient Name: ') || (TO_CHAR(pInfo.FirstName)) || (' ') || (TO_CHAR(pInfo.LastName)) );
                dbms_output.put_line( ('Patient Address: ') || (TO_CHAR(pInfo.Street)) || (', ') || (TO_CHAR(pInfo.Town) ) || (', ') || (TO_CHAR(pInfo.Zip)) );

    FOR dInfo IN DoctorInfo LOOP

                    IF(dInfo.StartDate = :old.StartDate AND dInfo.SSN = :old.SSN) THEN
                        dbms_output.put_line( ('Doctor Name: ') || (TO_CHAR(dInfo.FirstName)) || (' ') || (TO_CHAR(dInfo.LastName)) || (' ') || ('Comments: ') || (TO_CHAR(dInfo.DoctorsComments)) );
    END IF;

    END LOOP;

    END IF;

    END LOOP;



END;
/





INSERT INTO Patient VALUES('111223333', 'Andrew',    'Apeman',       'Rhododendron Rd',      'Lexington',    '02420', '1234567890');
INSERT INTO Patient VALUES('111111111', 'Billy',     'Bobface',      'Tulip Ln',             'Lexington',    '02421', '2345678901');
INSERT INTO Patient VALUES('222222222', 'Carl',      'Carboi',       'Daisy Ln',             'Lexington',    '02420', '3456789012');
INSERT INTO Patient VALUES('333333333', 'Dennis',    'Denisovich',   'Rose Ave',             'Lexington',    '02421', '4567890123');
INSERT INTO Patient VALUES('444444444', 'Eggbert',   'Egghead',      'Orchid Circle',        'Lexington',    '02420', '5678901234');
INSERT INTO Patient VALUES('555555555', 'Frankfurt', 'Frankenstein', 'Dandelion Rd',         'Harvard',      '01434', '6789012345');
INSERT INTO Patient VALUES('666666666', 'Geoffrey',  'Geff',         'Sunflower St',         'Harvard',      '01451', '7890123456');
INSERT INTO Patient VALUES('777777777', 'Harry',     'Harrington',   'Dahlia Ln',            'Harvard',      '01434', '8901234567');
INSERT INTO Patient VALUES('888888888', 'Isabella',  'Iceberg',      'Amaryllis Ave',        'Harvard',      '01451', '9012345678');
INSERT INTO Patient VALUES('999999999', 'Jacob',     'Jackfruit',    'Park St',              'Harvard',      '01434', '0123456789');

INSERT INTO Room VALUES(100, 0);
INSERT INTO Room VALUES(101, 0);
INSERT INTO Room VALUES(102, 0);
INSERT INTO Room VALUES(103, 0);
INSERT INTO Room VALUES(104, 0);
INSERT INTO Room VALUES(105, 1);
INSERT INTO Room VALUES(106, 1);
INSERT INTO Room VALUES(107, 1);
INSERT INTO Room VALUES(108, 1);
INSERT INTO Room VALUES(109, 1);

INSERT INTO Services VALUES (100, 'Bathing');
INSERT INTO Services VALUES (100, 'Bathrooming');
INSERT INTO Services VALUES (101, 'ICU');
INSERT INTO Services VALUES (101, 'Bathrooming');
INSERT INTO Services VALUES (102, 'ICU');
INSERT INTO Services VALUES (102, 'Bathrooming');
INSERT INTO Services VALUES (102, 'Cleaning');
INSERT INTO Services VALUES (103, 'Bathing');

INSERT INTO EquipmentType VALUES(1001, 'Moon',  'Hit it really hard',       'Big');
INSERT INTO EquipmentType VALUES(1002, 'Sun',   'Light it on fire',         'Very big');
INSERT INTO EquipmentType VALUES(1003, 'Stars', 'Throw it against a wall',  'Very small');

INSERT INTO EquipmentUnit VALUES(2010, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10000',   100,    1001);
INSERT INTO EquipmentUnit VALUES(2011, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10001',   100,    1001);
INSERT INTO EquipmentUnit VALUES(2010, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10008',   100,    1001);
INSERT INTO EquipmentUnit VALUES(2011, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10009',   100,    1001);
INSERT INTO EquipmentUnit VALUES(2010, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10002',   101,    1001);
INSERT INTO EquipmentUnit VALUES(2004, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10003',   101,    1002);
INSERT INTO EquipmentUnit VALUES(2005, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10004',   102,    1002);
INSERT INTO EquipmentUnit VALUES(2006, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10005',   102,    1002);
INSERT INTO EquipmentUnit VALUES(2007, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10006',   103,    1003);
INSERT INTO EquipmentUnit VALUES(2008, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10007',   103,    1003);
INSERT INTO EquipmentUnit VALUES(2009, TO_TIMESTAMP('2019-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'A01-02X', 104,    1003);

INSERT INTO Admission VALUES(2435245.,   11,     TO_TIMESTAMP('2020-03-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111223333');
INSERT INTO Admission VALUES(34563456.,  12,     TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111223333');
INSERT INTO Admission VALUES(45674567.,  13,     TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111111111');
INSERT INTO Admission VALUES(567856.,    14,     TO_TIMESTAMP('2020-03-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111111111');
INSERT INTO Admission VALUES(6789678.,   15,     TO_TIMESTAMP('2020-03-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111223333');
INSERT INTO Admission VALUES(0.11,       16,     TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO Admission VALUES(248726458,  17,     TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO Admission VALUES(45876,      18,     TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '333333333');
INSERT INTO Admission VALUES(2.2,        19,     TO_TIMESTAMP('2020-03-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '333333333');
INSERT INTO Admission VALUES(44,         20,     TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '444444444');
INSERT INTO Admission VALUES(45,         21,     TO_TIMESTAMP('2020-03-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '444444444');
INSERT INTO Admission VALUES(33,         22,     TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '555555555');
INSERT INTO Admission VALUES(666666,     10,     TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO Admission VALUES(666666,     10,     TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO Admission VALUES(666666,     10,     TO_TIMESTAMP('2020-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   NULL,                                                           TO_TIMESTAMP('2020-03-15 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');

INSERT INTO Employee VALUES('Big Man', 'Harry',  'Hairy',     10334,     105, 15, 'St5', 'Cambridge', '01621', NULL, 'General');
INSERT INTO Employee VALUES('Big Boy', 'Bill',   'Balding',   234876,    106, 16, 'St6', 'Cambridge', '01637', NULL, 'General');

INSERT INTO Employee VALUES('Mediumer',  'Bill',     'Big',      100, 101,   11, 'St1', 'Cambridge', '01609', 105, 'Division');
INSERT INTO Employee VALUES('Regularer', 'Lenny',    'Large',    101, 102,   12, 'St2', 'Cambridge', '01609', 105, 'Division');
INSERT INTO Employee VALUES('Averager',  'Joseph',   'Gigantic', 102, 10,    13, 'St3', 'Cambridge', '01609', 106, 'Division');
INSERT INTO Employee VALUES('Flattener', 'Geoffrey', 'Great',    103, 104,   14, 'St4', 'Cambridge', '01609', 106, 'Division');

INSERT INTO Employee VALUES('Clicker',   'Emp1FN',  'Emp1LN',    0.1,        107, 1,   'A St',   'Burlington',  '01111', 101, 'Regular');
INSERT INTO Employee VALUES('Bopper',    'Emp2FN',  'Emp2LN',    0.2,        108, 2,   'B St',   'Burlington',  '01112', 101, 'Regular');
INSERT INTO Employee VALUES('Booper',    'Emp3FN',  'Emp3LN',    0.3,        109, 3,   'C St',   'Burlington',  '01113', 101, 'Regular');
INSERT INTO Employee VALUES('Bleeper',   'Emp4FN',  'Emp4LN',    0.4,        110, 4,   'D St',   'Burlington',  '01114', 101, 'Regular');
INSERT INTO Employee VALUES('Slapper',   'Emp5FN',  'Emp5LN',    0.5,        111, 5,   'E St',   'Burlington',  '01111', 101, 'Regular');
INSERT INTO Employee VALUES('Slopper',   'Emp6FN',  'Emp6LN',    0.6,        112, 6,   'F St',   'Stowe',       '01112', 102, 'Regular');
INSERT INTO Employee VALUES('Schlooper', 'Emp7FN',  'Emp7LN',    0.7,        113, 7,   'G St',   'Stowe',       '01113', 102, 'Regular');
INSERT INTO Employee VALUES('Mlemer',    'Emp8FN',  'Emp8LN',    0.8,        114, 8,   'H St',   'Stowe',       '01114', 102, 'Regular');
INSERT INTO Employee VALUES('Memer',     'Emp9FN',  'Emp9LN',    0.9,        115, 9,   'I St',   'Stowe',       '01111', 102, 'Regular');
INSERT INTO Employee VALUES('Cook',      'Emp10FN', 'Emp10LN',   1.0,        116, 10,  'J St',   'Stowe',       '01112', 104, 'Regular');
INSERT INTO Employee VALUES('Popper',    'Emp11FN', 'Emp11LN',   1.1,        117, 110, 'K St',   'Oakland',     '01113', 10,  'Regular');
INSERT INTO Employee VALUES('Pope',      'Emp12FN', 'Emp12LN',   1.2,        118, 120, 'L St',   'Oakland',     '01114', 10,  'Regular');
INSERT INTO Employee VALUES('Dropper',   'Emp13FN', 'Emp13LN',   1.3,        119, 130, 'M St',   'Oakland',     '01111', 10,  'Regular');
INSERT INTO Employee VALUES('Catcher',   'Emp14FN', 'Emp14LN',   1.4,        120, 140, 'N St',   'Oakland',     '01112', 10,  'Regular');
INSERT INTO Employee VALUES('Thrower',   'Emp15FN', 'Emp15LN',   1000000.0,  121, 150, 'O St',   'Oakland',     '01113', 10,  'Regular');

INSERT INTO Doctor VALUES(107, 'WPI',        'Female',   'Knees');
INSERT INTO Doctor VALUES(108, 'WPI',        'Male',     'Head');
INSERT INTO Doctor VALUES(109, 'Harvard',    'Other',    'Brain');
INSERT INTO Doctor VALUES(110, 'Harvard',    'Female',   'Toes');
INSERT INTO Doctor VALUES(111, 'WSU',        'Other',    'Spine');

INSERT INTO EquipmentTechnician VALUES(112);
INSERT INTO EquipmentTechnician VALUES(113);
INSERT INTO EquipmentTechnician VALUES(114);
INSERT INTO EquipmentTechnician VALUES(115);
INSERT INTO EquipmentTechnician VALUES(116);


INSERT INTO TechWorksWithType VALUES(112, 1001);
INSERT INTO TechWorksWithType VALUES(112, 1002);
INSERT INTO TechWorksWithType VALUES(113, 1001);
INSERT INTO TechWorksWithType VALUES(114, 1001);
INSERT INTO TechWorksWithType VALUES(114, 1003);


INSERT INTO EmployeeCanAccessRoom VALUES(118, 100);
INSERT INTO EmployeeCanAccessRoom VALUES(118, 101);
INSERT INTO EmployeeCanAccessRoom VALUES(118, 102);
INSERT INTO EmployeeCanAccessRoom VALUES(119, 101);


INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boop ba doop',   '111223333');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Bleep',          '111223333');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Bo',             '111223333');
INSERT INTO DoctorExaminesAdmission VALUES(108, TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers',        '111111111');

INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers1',       '111111111');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers2',       '111111111');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers3',       '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers4',       '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers5',       '333333333');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers6',       '333333333');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers7',       '444444444');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers8',       '444444444');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers9',       '555555555');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers10',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers11',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers12',      '111111111');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers13',      '111111111');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers14',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers15',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers16',      '333333333');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers17',      '333333333');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers18',      '444444444');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers19',      '444444444');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers20',      '555555555');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers21',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(109, TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers69',      '222222222');
INSERT INTO DoctorExaminesAdmission VALUES(111, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boopers420',     '222222222');




INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 101, TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 102, TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 101, TO_TIMESTAMP('2020-03-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '111223333');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 101, TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 101, TO_TIMESTAMP('2020-03-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 101, TO_TIMESTAMP('2020-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '222222222');


-- Critical Cases View: -----------------------------
/*
	- Create a view named CriticalCases that selects the patients who have been admitted to Intensive Care Unit (ICU) at least 2 times.
		The view columns should be: Patient_SSN, firstName, lastName, numberOfAdmissionsToICU.
*/

CREATE VIEW CriticalCases AS
(SELECT A.Patient_SSN, P.FirstName AS firstName, P.LastName AS lastName, A.numberOfAdmissionsToICU
FROM Patient P,
     (SELECT Patient_SSN, numberOfAdmissionsToICU
      FROM	(SELECT SSN AS Patient_SSN, COUNT(StartDate) AS numberOfAdmissionsToICU
               FROM	(SELECT A.AdmissionStartDate AS StartDate, A.SSN AS SSN
                        FROM RoomToAdmission A,
                             (SELECT RoomNumber
                              FROM Services
                              WHERE Service = 'ICU') S
                        WHERE A.RoomNumber = S.RoomNumber)
               GROUP BY SSN)
      WHERE numberOfAdmissionsToICU > 1) A
WHERE A.Patient_SSN = P.SSN);


-- Doctors Load View:-----------------------------
/*
	- Create a view named DoctorsLoad that reports for each doctor whether this doctor has an overload or not. A doctor has an overload if they have more
		than 10 distinct admission cases; otherwise, the doctor has an underload. Notice that if a doctor examined a patient multiple times in the same admission,
		that still counts as one admission case. The view columns should be: DoctorID, graduatedFrom, load.
	- The load column should have either of these two values ‘Overloaded’, or ‘Underloaded’ according to the definition above.
*/
CREATE VIEW DoctorsLoad AS
(SELECT EmployeeID AS DoctorID, MedicalSchoolAttended AS graduatedFrom, 'Underloaded' AS load
FROM   (SELECT EmployeeID, MedicalSchoolAttended
        FROM Doctor

                 MINUS

            SELECT All_Docs.EmployeeID, All_Docs.MedicalSchoolAttended
        FROM Doctor All_Docs,
            (SELECT EmployeeID, 'Overloaded' AS loadd
            FROM    (SELECT EmployeeID, COUNT(StartDate) AS DoctorLoadNum
            FROM   (SELECT DISTINCT EmployeeID, StartDate, SSN
            FROM    (SELECT EmployeeID, SSN, StartDate
            FROM DoctorExaminesAdmission))
            GROUP BY EmployeeID)
            WHERE DoctorLoadNum > 10) OD_Doctors
        WHERE OD_Doctors.EmployeeID = All_Docs.EmployeeID)

UNION

SELECT All_Docs.EmployeeID AS DoctorID, All_Docs.MedicalSchoolAttended AS graduatedFrom, OD_Doctors.loadd AS load
FROM Doctor All_Docs,
     (SELECT EmployeeID, 'Overloaded' AS loadd
      FROM    (SELECT EmployeeID, COUNT(StartDate) AS DoctorLoadNum
               FROM    (SELECT DISTINCT EmployeeID, StartDate, SSN
                        FROM    (SELECT EmployeeID, SSN, StartDate
                                 FROM DoctorExaminesAdmission))
               GROUP BY EmployeeID)
      WHERE DoctorLoadNum > 10) OD_Doctors
WHERE OD_Doctors.EmployeeID = All_Docs.EmployeeID);



SELECT *
FROM CriticalCases;


-- Querie #1:-----------------------------
/*
	- Use the views created above (you may need the original tables as well) to report the critical-case patients with number of admissions
		to ICU greater than 4.
*/

SELECT Patient_SSN
FROM CriticalCases
WHERE  numberOfAdmissionsToICU > 4;



-- Querie #2:-----------------------------
/*
	- Use the views created above (you may need the original tables as well) to report the overloaded doctors that graduated from WPI. You should report
	the doctor ID, firstName, and lastName.
*/

SELECT D.DoctorID, E.firstName, E.lastName
FROM Employee E,
     (SELECT DoctorID, graduatedFrom
      FROM DoctorsLoad
      WHERE load = 'Overloaded'
        AND graduatedFrom = 'WPI') D
WHERE D.DoctorID = E.EmployeeID;


-- Querie #3:-----------------------------
/*
	- Use the views created above (you may need the original tables as well) to report the comments inserted by underloaded doctors when examining
		critical-case patients. You should report the doctor Id, patient SSN, and the comment.
*/
SELECT Dl.DoctorID, E.Patient_SSN, E.DoctorsComments
FROM DoctorsLoad Dl,
     (SELECT D.EmployeeID, D.DoctorsComments, C.Patient_SSN
      FROM DoctorExaminesAdmission D, CriticalCases C
      WHERE D.SSN = C.Patient_SSN) E
WHERE Dl.DoctorID = E.EmployeeID
  AND Dl.load = 'Underloaded';




-- Trigger #1 Test:-----------------------------
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL,		'111111111');




-- Trigger #2 Test:-----------------------------
INSERT INTO Patient VALUES('123456789', 'Spencer',    'Drew',       'Rhododendron Rd',      'Acton',    '02420', '1234567890');
INSERT INTO Admission VALUES(2435245.,	 11, 	 TO_TIMESTAMP('2020-03-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 NULL, 		TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '123456789');

SELECT PercentInsurance
FROM Admission
WHERE StartDate = TO_TIMESTAMP('2020-03-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') AND SSN = '111223333';


-- Trigger #3 Test:-----------------------------
/* Good */
INSERT INTO Employee VALUES('Clicker',   'Emp1FN',  'Emp1LN',    0.1,        1005, 17,   'A St',  'Burlington',  '01111', NULL, 'General');
/* ERROR: 'General Managers must not have any supervisors' */
INSERT INTO Employee VALUES('Carl',      'Bag',     'Ram',       0.3,        1008, 18,   'C St',  'Arlington',   '01122', 1005, 'General');
/* ERROR: 'Division managers must have supervisors at all times' */
INSERT INTO Employee VALUES('Thumb',     'Tag',     'Run',       0.3,        1007, 19,   'B St',  'Belmont',     '01121', NULL, 'Division');
/* Good */
INSERT INTO Employee VALUES('Flattener', 'Geoffrey', 'Great',    103,        1004,   20, 'St4', 'Cambridge', '01609', 1005, 'Division');
/* ERROR: 'Manager must be a General Manager' */
INSERT INTO Employee VALUES('Averager',  'Joseph',   'Gigantic', 102, 10,    21, 'St3', 'Cambridge', '01609', 1004, 'Division');
/* ERROR: 'Regular managers must have supervisors at all times' */
INSERT INTO Employee VALUES('Clicker',   'Stan',    'Egg',   0.1,        1009, 22,   'A St',  'Burlington',  '01111', NULL, 'Regular');
/* Good */
INSERT INTO Employee VALUES('Drawer',    'Jerry',   'Baccon',    0.2,        1010, 23,   'B St',  'Burlington',  '01112', 1004, 'Regular');
/* ERROR: 'Manager must be a Division Manager' */
INSERT INTO Employee VALUES('Flattener',     'Carlos',  'Lamb',  0.3,        1011, 24,   'C St',  'Burlington',  '01113', 1010, 'Regular');



-- Trigger #5 Tests:-----------------------------
INSERT INTO Room VALUES(110, 0);
INSERT INTO Room VALUES(111, 0);
INSERT INTO Services VALUES (110, 'Emergency');
INSERT INTO Services VALUES (110, 'Bathing');
INSERT INTO Services VALUES (111, 'Bathing');
INSERT INTO Patient VALUES('234567891', 'Carl',      'Carboi',       'Daisy Ln',             'Lexington',    '02420', '3456789012');
INSERT INTO Admission VALUES(0.11,       16,     TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),   TO_TIMESTAMP('2020-03-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO Admission VALUES(34563456.,  12, 	 TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 TO_TIMESTAMP('2020-03-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 TO_TIMESTAMP('2020-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO Admission VALUES(34563456.,  12, 	 TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 TO_TIMESTAMP('2020-03-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 TO_TIMESTAMP('2020-03-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 110, TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 111, TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 110, TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');
INSERT INTO RoomToAdmission VALUES(TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2020-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 111, TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '999999999');


--SHOULD BE 2 MONTHS AFTER START DATE
SELECT *
FROM (  SELECT A.StartDate, A. FutureVisitDate, A.SSN, R.RoomNumber
        FROM Admission A,RoomToAdmission R
        WHERE A.StartDate = R.AdmissionStartDate AND A.SSN = R.SSN)
WHERE SSN = 999999999 AND StartDate = TO_TIMESTAMP('2020-03-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

--SHOULD BE SAME AS ORIGINAL FUTURE VISIT DATE bc NOT IN 'EMERGENCY'
SELECT *
FROM (  SELECT A.StartDate, A. FutureVisitDate, A.SSN, R.RoomNumber
        FROM Admission A,RoomToAdmission R
        WHERE A.StartDate = R.AdmissionStartDate AND A.SSN = R.SSN)
WHERE SSN = 999999999 AND StartDate = TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

--SHOULD BE 2 MONTHS AFTER START DATE
SELECT *
FROM (  SELECT A.StartDate, A. FutureVisitDate, A.SSN, R.RoomNumber
        FROM Admission A,RoomToAdmission R
        WHERE A.StartDate = R.AdmissionStartDate AND A.SSN = R.SSN)
WHERE SSN = 999999999 AND StartDate = TO_TIMESTAMP('2020-03-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS');



-- Trigger #6 Tests:-----------------------------
INSERT INTO Room VALUES(112, 0);
INSERT INTO EquipmentType VALUES(1004, 'Moon', 	'Hit it really hard', 		'Big');
INSERT INTO Employee VALUES('Slopper',	 'Emp6FN',	'Emp6LN',	 0.6,		 122, 24,   'F St',	 'Stowe', 		'01112', 104, 'Regular');
INSERT INTO EquipmentTechnician VALUES(122);
INSERT INTO TechWorksWithType VALUES(122, 1004);

--should not be updated
INSERT INTO EquipmentUnit VALUES(2010, TO_TIMESTAMP('2021-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10000', 	112, 	1004);

SELECT LastInspectionTime, SerialNumber, TypeID
FROM EquipmentUnit
WHERE SerialNumber = 10000 AND TypeID = 1004;

--shoudl be updated
INSERT INTO EquipmentUnit VALUES(2011, TO_TIMESTAMP('2021-01-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10001', 	112, 	1004);

SELECT LastInspectionTime, SerialNumber, TypeID
FROM EquipmentUnit
WHERE SerialNumber = 10001 AND TypeID = 1004;

--should not be updated
INSERT INTO EquipmentUnit VALUES(2010, TO_TIMESTAMP('2021-02-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), '10008', 	112, 	1004);

SELECT LastInspectionTime, SerialNumber, TypeID
FROM EquipmentUnit
WHERE SerialNumber = 10008 AND TypeID = 1004;



-- Trigger #7 Tests:-----------------------------
INSERT INTO Employee VALUES('Clicker',	 'Emp1FN', 	'Emp1LN',	 0.1,		 123, 25,   'A St',	 'Burlington',  '01111', 101, 'Regular');
INSERT INTO Doctor VALUES(123, 'WPI',		 'Female',	 'Knees');
INSERT INTO Patient VALUES('345678912', 'John',    'Burke',       'Rhododendron Rd',      'Lexington',    '02420', '1234567890');
INSERT INTO Admission VALUES(34563456.,  12, 	 TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 TO_TIMESTAMP('2020-05-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),	 NULL, '345678912');

INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Boop ba doop',  	'345678912');
INSERT INTO DoctorExaminesAdmission VALUES(107, TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Bleep', 			'345678912');


UPDATE Admission SET EndDate = TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS') WHERE StartDate = TO_TIMESTAMP('2020-03-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS') AND SSN = '345678912';

