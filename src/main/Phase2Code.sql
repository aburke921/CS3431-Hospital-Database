
DROP TABLE RoomToAdmission CASCADE CONSTRAINTS;
DROP TABLE DoctorExaminesDuringAdmission CASCADE CONSTRAINTS;
DROP TABLE EquipmentTechnicianWorksWithType CASCADE CONSTRAINTS;
DROP TABLE EmployeeCanAccessRoom CASCADE CONSTRAINTS;
DROP TABLE Admission CASCADE CONSTRAINTS;
DROP TABLE Patient CASCADE CONSTRAINTS;
DROP TABLE EquipmentUnit CASCADE CONSTRAINTS;
DROP TABLE EquipmentType CASCADE CONSTRAINTS;
DROP TABLE Services CASCADE CONSTRAINTS;
DROP TABLE Room CASCADE CONSTRAINTS;
DROP TABLE EquipmentTechnician CASCADE CONSTRAINTS;
DROP TABLE Doctor CASCADE CONSTRAINTS;
DROP TABLE Employee CASCADE CONSTRAINTS;



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


CREATE TABLE Room
	(RoomNumber INTEGER PRIMARY KEY,
	Occupied INTEGER NOT NULL,
	CONSTRAINT room_roomnumber_ck CHECK (RoomNumber > 0),
	CONSTRAINT room_Occupied_ck CHECK (Occupied in ('0','1'))
);


CREATE TABLE Services
	(RoomNumber INTEGER,
	Service Varchar2(1000),
	CONSTRAINT Services_PK PRIMARY KEY (RoomNumber, Service),
	FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
	    ON DELETE CASCADE
);


CREATE TABLE EquipmentType(
    TypeID INTEGER PRIMARY KEY,
	Model Varchar2(100),
	OperationalInstructions Varchar2(10000),
	Description Varchar2(1000)
);



CREATE TABLE EquipmentUnit(
    YearOfPurchase INTEGER,
	LastInspectionTime Varchar2(50),
	SerialNumber Varchar2(10),
	RoomNumber INTEGER,
	TypeID INTEGER,
	CONSTRAINT EquipmentUnit_PK PRIMARY KEY(SerialNumber, TypeID),
	FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
	    ON DELETE CASCADE,
	FOREIGN KEY (TypeID) REFERENCES EquipmentType(TypeID)
	    ON DELETE CASCADE,
	CONSTRAINT EquipmentUnit_Yearofpurchase_ck CHECK (YearOfPurchase > 0)
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
	StartDate Varchar2(50),
	StartTime Char(4),
	FutureVisitDate Varchar2(50),
	EndTime Char(4),
	EndDate Varchar2(50),
	SSN CHAR(9),
	CONSTRAINT Admission_PK PRIMARY KEY (StartDate, StartTime, SSN),
	FOREIGN KEY (SSN) REFERENCES Patient(SSN)
	    ON DELETE CASCADE,
	CONSTRAINT admission_visitcost_ck CHECK (VisitCost > 0),
	CONSTRAINT admission_percentinsurance_ck CHECK ((0 <= PercentInsurance) AND (PercentInsurance <= 100)),
	CONSTRAINT admission_Starttime_ck CHECK ((0 <= StartTime) AND (StartTime < 2400)),
	CONSTRAINT admission_Endtime_ck CHECK ((0 <= EndTime) AND (EndTime < 2400))
);





CREATE TABLE EmployeeCanAccessRoom (
    EmployeeID INTEGER,
	RoomNumber INTEGER,
	CONSTRAINT EmployeeCanAccessRoom_PK PRIMARY KEY (EmployeeID, RoomNumber),
	FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
	    ON DELETE CASCADE,
	FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
	    ON DELETE CASCADE
);


CREATE TABLE EquipmentTechnicianWorksWithType(
	EmployeeID INTEGER,
	TypeID INTEGER,
	CONSTRAINT EquipmentTechnicianWorksWithType_PK PRIMARY KEY (EmployeeID, TypeID),
	FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
	    ON DELETE CASCADE,
	FOREIGN KEY (TypeID) REFERENCES EquipmentType(TypeID)
	    ON DELETE CASCADE
);



CREATE TABLE DoctorExaminesDuringAdmission (
    EmployeeID INTEGER,
	StartDate Varchar2(50),
	StartTime CHAR(4),
	DoctorsComments Varchar(6000),
	SSN CHAR(9),
	CONSTRAINT DoctorExaminesDuringAdmission_PK PRIMARY KEY (EmployeeID, StartDate, StartTime, DoctorsComments, SSN),
	FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
	    ON DELETE CASCADE,
	FOREIGN KEY (StartDate, StartTime, SSN) REFERENCES Admission(StartDate, StartTime, SSN)
	    ON DELETE CASCADE
);



CREATE TABLE RoomToAdmission (
    StartDate Varchar2(50) NOT NULL,
	EndDate Varchar2(50) NOT NULL,
	RoomNumber INTEGER,
	AdmissionStartDate Varchar2(50),
	AdmissionStartTime Char(4),
	SSN CHAR(9),
	CONSTRAINT RoomToAdmission_PK PRIMARY KEY (RoomNumber, AdmissionStartDate, AdmissionStartTime, SSN),
	FOREIGN KEY (RoomNumber) REFERENCES Room(RoomNumber)
	    ON DELETE CASCADE,
	FOREIGN KEY (AdmissionStartDate, AdmissionStartTime, SSN) REFERENCES Admission(StartDate, StartTime, SSN )
	    ON DELETE CASCADE
);


DELETE FROM RoomToAdmission;
DELETE FROM DoctorExaminesDuringAdmission;
DELETE FROM EquipmentTechnicianWorksWithType;
DELETE FROM EmployeeCanAccessRoom;
DELETE FROM Admission;
DELETE FROM Patient;
DELETE FROM EquipmentUnit;
DELETE FROM EquipmentType;
DELETE FROM Services;
DELETE FROM Room;
DELETE FROM EquipmentTechnician;
DELETE FROM Doctor;
DELETE FROM Employee;

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
INSERT INTO Services VALUES (101, 'Bathing');
INSERT INTO Services VALUES (101, 'Bathrooming');
INSERT INTO Services VALUES (102, 'Bathing');
INSERT INTO Services VALUES (102, 'Bathrooming');
INSERT INTO Services VALUES (102, 'Cleaning');
INSERT INTO Services VALUES (103, 'Bathing');

INSERT INTO EquipmentType VALUES(1001, 'Moon', 	'Hit it really hard', 		'Big');
INSERT INTO EquipmentType VALUES(1002, 'Sun', 	'Light it on fire', 		'Very big');
INSERT INTO EquipmentType VALUES(1003, 'Stars', 'Throw it against a wall', 	'Very small');

INSERT INTO EquipmentUnit VALUES(2010, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10000', 	100, 	1001);
INSERT INTO EquipmentUnit VALUES(2011, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10001', 	100, 	1001);
INSERT INTO EquipmentUnit VALUES(2010, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10008', 	100, 	1001);
INSERT INTO EquipmentUnit VALUES(2011, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10009', 	100, 	1001);
INSERT INTO EquipmentUnit VALUES(2010, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10002', 	101, 	1001);
INSERT INTO EquipmentUnit VALUES(2004, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10003', 	101, 	1002);
INSERT INTO EquipmentUnit VALUES(2005, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10004', 	102, 	1002);
INSERT INTO EquipmentUnit VALUES(2006, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10005', 	102, 	1002);
INSERT INTO EquipmentUnit VALUES(2007, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10006', 	103, 	1003);
INSERT INTO EquipmentUnit VALUES(2008, TO_DATE('2019-03-02', 'YYYY-MM-DD'), '10007', 	103, 	1003);
INSERT INTO EquipmentUnit VALUES(2009, TO_DATE('2019-03-02', 'YYYY-MM-DD'), 'A01-02X', 104, 	1003); 



INSERT INTO Admission VALUES(2435245.,	 11, 	 TO_DATE('2020-03-01', 'YYYY-MM-DD'),	 1101,	 NULL, 			                       1201, TO_DATE('2020-03-02', 'YYYY-MM-DD'), '111223333');
INSERT INTO Admission VALUES(34563456.,  12, 	 TO_DATE('2020-03-02', 'YYYY-MM-DD'),	 1102,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),  1202, TO_DATE('2020-03-03', 'YYYY-MM-DD'), '111223333');
INSERT INTO Admission VALUES(45674567.,	 13, 	 TO_DATE('2020-03-03', 'YYYY-MM-DD'),	 1103,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),  1203, TO_DATE('2020-03-04', 'YYYY-MM-DD'), '111111111');
INSERT INTO Admission VALUES(567856.,	 14, 	 TO_DATE('2020-03-04', 'YYYY-MM-DD'),	 1104,	 NULL, 			                       1204, TO_DATE('2020-03-05', 'YYYY-MM-DD'), '111111111');
INSERT INTO Admission VALUES(6789678.,	 15, 	 TO_DATE('2020-03-05', 'YYYY-MM-DD'),	 1105,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),  1205, TO_DATE('2020-03-06', 'YYYY-MM-DD'), '111223333');
INSERT INTO Admission VALUES(0.11,		 16, 	 TO_DATE('2020-03-06', 'YYYY-MM-DD'),	 1106,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),  1206, TO_DATE('2020-03-07', 'YYYY-MM-DD'), '222222222');
INSERT INTO Admission VALUES(248726458,	 17,	 TO_DATE('2020-03-07', 'YYYY-MM-DD'),	 1107,	 NULL,			                       1207, TO_DATE('2020-03-08', 'YYYY-MM-DD'), '222222222');
INSERT INTO Admission VALUES(45876,		 18,	 TO_DATE('2020-03-08', 'YYYY-MM-DD'),	 1108,	 NULL,		                           1208, TO_DATE('2020-03-09', 'YYYY-MM-DD'), '333333333');
INSERT INTO Admission VALUES(2.2,		 19,	 TO_DATE('2020-03-09', 'YYYY-MM-DD'),	 1109,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),  1209, TO_DATE('2020-03-10', 'YYYY-MM-DD'), '333333333');
INSERT INTO Admission VALUES(44,		 20,	 TO_DATE('2020-03-10', 'YYYY-MM-DD'),	 1110,	 NULL,			                       1210, TO_DATE('2020-03-11', 'YYYY-MM-DD'), '444444444');
INSERT INTO Admission VALUES(45,		 21,	 TO_DATE('2020-03-11', 'YYYY-MM-DD'),	 1111,	 NULL,		                    	   1211, TO_DATE('2020-03-12', 'YYYY-MM-DD'), '444444444');
INSERT INTO Admission VALUES(33,		 22,	 TO_DATE('2020-03-12', 'YYYY-MM-DD'),	 1112,	 TO_DATE('2020-05-04', 'YYYY-MM-DD'),   1212, TO_DATE('2020-03-13', 'YYYY-MM-DD'),  '555555555');


INSERT INTO Employee VALUES('Big Man', 'Harry',	 'Hairy',     10334,	 105, 15, 'St5', 'Cambridge', '01621', NULL, 'General');
INSERT INTO Employee VALUES('Big Boy', 'Bill',	 'Balding',   234876,	 106, 16, 'St6', 'Cambridge', '01637', NULL, 'General');

INSERT INTO Employee VALUES('Mediumer',	 'Bill',	 'Big',		 100, 101,	 11, 'St1', 'Cambridge', '01609', 105, 'Division');
INSERT INTO Employee VALUES('Regularer', 'Lenny',	 'Large',	 101, 102,	 12, 'St2', 'Cambridge', '01609', 105, 'Division');
INSERT INTO Employee VALUES('Averager',	 'Joseph',	 'Gigantic', 102, 10,	 13, 'St3', 'Cambridge', '01609', 106, 'Division');
INSERT INTO Employee VALUES('Flattener', 'Geoffrey', 'Great', 	 103, 104, 	 14, 'St4', 'Cambridge', '01609', 106, 'Division');

INSERT INTO Employee VALUES('Clicker',	 'Emp1FN', 	'Emp1LN',	 0.1,		 107, 1,   'A St',	 'Burlington',  '01111', 101, 'Regular');
INSERT INTO Employee VALUES('Bopper', 	 'Emp2FN',	'Emp2LN',	 0.2,		 108, 2,   'B St',	 'Burlington',  '01112', 101, 'Regular');
INSERT INTO Employee VALUES('Booper',	 'Emp3FN',	'Emp3LN',	 0.3,		 109, 3,   'C St',	 'Burlington',  '01113', 101, 'Regular');
INSERT INTO Employee VALUES('Bleeper',	 'Emp4FN', 	'Emp4LN',	 0.4,		 110, 4,   'D St',	 'Burlington',  '01114', 101, 'Regular');
INSERT INTO Employee VALUES('Slapper',	 'Emp5FN',	'Emp5LN',	 0.5,		 111, 5,   'E St',	 'Burlington',  '01111', 101, 'Regular');
INSERT INTO Employee VALUES('Slopper',	 'Emp6FN',	'Emp6LN',	 0.6,		 112, 6,   'F St',	 'Stowe', 		'01112', 102, 'Regular');
INSERT INTO Employee VALUES('Schlooper', 'Emp7FN',	'Emp7LN',	 0.7,		 113, 7,   'G St',	 'Stowe', 		'01113', 102, 'Regular');
INSERT INTO Employee VALUES('Mlemer',	 'Emp8FN',	'Emp8LN',	 0.8,		 114, 8,   'H St',	 'Stowe', 		'01114', 102, 'Regular');
INSERT INTO Employee VALUES('Memer',	 'Emp9FN', 	'Emp9LN',	 0.9,		 115, 9,   'I St',	 'Stowe', 		'01111', 102, 'Regular');
INSERT INTO Employee VALUES('Cook',		 'Emp10FN', 'Emp10LN',	 1.0,		 116, 10,  'J St', 	 'Stowe', 		'01112', 104, 'Regular');
INSERT INTO Employee VALUES('Popper',	 'Emp11FN', 'Emp11LN',	 1.1,		 117, 110, 'K St',	 'Oakland',	 	'01113', 10,  'Regular');
INSERT INTO Employee VALUES('Pope',		 'Emp12FN', 'Emp12LN',	 1.2,		 118, 120, 'L St',   'Oakland', 	'01114', 10,  'Regular');
INSERT INTO Employee VALUES('Dropper',	 'Emp13FN', 'Emp13LN',	 1.3,		 119, 130, 'M St',   'Oakland', 	'01111', 10,  'Regular');
INSERT INTO Employee VALUES('Catcher', 	 'Emp14FN', 'Emp14LN',	 1.4,		 120, 140, 'N St',   'Oakland', 	'01112', 10,  'Regular');
INSERT INTO Employee VALUES('Thrower',	 'Emp15FN', 'Emp15LN',	 1000000.0,  121, 150, 'O St',   'Oakland',		'01113', 10,  'Regular');

INSERT INTO Doctor VALUES(107, 'WPI',		 'Female',	 'Knees');
INSERT INTO Doctor VALUES(108, 'WPI',		 'Male',	 'Head');
INSERT INTO Doctor VALUES(109, 'Harvard',	 'Other',	 'Brain');
INSERT INTO Doctor VALUES(110, 'Harvard',	 'Female',	 'Toes');
INSERT INTO Doctor VALUES(111, 'WSU',		 'Other', 	 'Spine');

INSERT INTO EquipmentTechnician VALUES(112);
INSERT INTO EquipmentTechnician VALUES(113);
INSERT INTO EquipmentTechnician VALUES(114);
INSERT INTO EquipmentTechnician VALUES(115);
INSERT INTO EquipmentTechnician VALUES(116);


INSERT INTO EquipmentTechnicianWorksWithType VALUES(112, 1001);
INSERT INTO EquipmentTechnicianWorksWithType VALUES(112, 1002);
INSERT INTO EquipmentTechnicianWorksWithType VALUES(113, 1001);
INSERT INTO EquipmentTechnicianWorksWithType VALUES(114, 1001);
INSERT INTO EquipmentTechnicianWorksWithType VALUES(114, 1003);


INSERT INTO EmployeeCanAccessRoom VALUES(118, 100);
INSERT INTO EmployeeCanAccessRoom VALUES(118, 101);
INSERT INTO EmployeeCanAccessRoom VALUES(118, 102);
INSERT INTO EmployeeCanAccessRoom VALUES(119, 101);

INSERT INTO DoctorExaminesDuringAdmission VALUES(107, TO_DATE('2020-03-01', 'YYYY-MM-DD'), 1101, 'Boop ba doop',  	'111223333');
INSERT INTO DoctorExaminesDuringAdmission VALUES(107, TO_DATE('2020-03-02', 'YYYY-MM-DD'), 1102, 'Bleep', 			'111223333');
INSERT INTO DoctorExaminesDuringAdmission VALUES(107, TO_DATE('2020-03-05', 'YYYY-MM-DD'), 1105, 'Bo',				'111223333');
INSERT INTO DoctorExaminesDuringAdmission VALUES(108, TO_DATE('2020-03-03', 'YYYY-MM-DD'), 1103, 'Boopers',			'111111111');



/* #1 This query is to select the  ID, School attended, specialty, and gender of all doctors that graduated from WPI*/
SELECT EmployeeID,MedicalSchoolAttended, Specialty, Gender
FROM Doctor
WHERE MedicalSchoolAttended = 'WPI';

/* #2 This query is to select Employee ID, first name, last name, and salary where the division manager ID = 10*/
SELECT EmployeeID, FirstName, LastName, Salary
FROM Employee
WHERE ManagerID = 10;

/* #3 This query is to select the SSN and sum of insurance payments for each patient */
SELECT SSN, SUM(PaidByInsurance) AS TotalPaidByInsurance
FROM (  SELECT SSN, (VisitCost*PercentInsurance/100) AS PaidByInsurance
        FROM Admission)
GROUP BY SSN;

/* #4 This query is to select the patient SSN, first and last names, and number of visits */
SELECT SSN, SUM(PaidByInsurance) AS TotalPaidByInsurance
FROM (  SELECT SSN, (VisitCost*PercentInsurance/100) AS PaidByInsurance
        FROM Admission)
GROUP BY SSN;

/* #5 This query is to select the room number containing equipment unit with serial number 'A01-02X' */
SELECT RoomNumber
FROM EquipmentUnit
WHERE SerialNumber = 'A01-02X';


/* #6 This query is to select the employeeID of the employee that can access the most rooms and the number of rooms they can access */
SELECT EmployeeID, RoomsAccessible
FROM (SELECT EmployeeID, count(RoomNumber) AS RoomsAccessible
        FROM EmployeeCanAccessRoom
        GROUP BY EmployeeID) T
WHERE RoomsAccessible = (   SELECT MAX(RoomsAccessible) As RoomsAccessible
                            FROM (   SELECT EmployeeID, count(RoomNumber) AS RoomsAccessible
                                     FROM EmployeeCanAccessRoom
                                     GROUP BY EmployeeID));

/* #7 This query is to select the number of regular employees, division managers, and general managers */
SELECT 'Regular Employees' AS Type, EmployeeLevelNum AS Count
FROM (  SELECT COUNT(EmployeeLevel) as EmployeeLevelNum
        FROM (  SELECT EmployeeLevel
            	FROM Employee
	            WHERE EmployeeLevel = 'Regular'))

UNION

SELECT 'Division Managers' AS Type, EmployeeLevelNum AS Count
FROM (  SELECT COUNT(EmployeeLevel) as EmployeeLevelNum
    	FROM (  SELECT EmployeeLevel
	        	FROM Employee
	            WHERE EmployeeLevel = 'Division'))

UNION

SELECT 'General Managers' AS Type, EmployeeLevelNum AS Count
FROM (  SELECT COUNT(EmployeeLevel) as EmployeeLevelNum
	    FROM (  SELECT EmployeeLevel
		        FROM Employee
            	WHERE EmployeeLevel = 'General'));


/* #8 This query is to select the SSN, first name, and last name of patients who have a scheduled future visit as part of their most recent visit */
SELECT P.SSN, FirstName, LastName, B.FutureVisitDate
FROM Patient P,   (SELECT A.SSN, FutureVisitDate
                FROM Admission A,  (SELECT SSN, MAX(StartDate) as StartDate, MAX(StartTime)AS StartTime
                                    FROM Admission
                                    GROUP BY SSN) MostRecent
                WHERE A.StartDate = MostRecent.StartDate
                AND A.StartTime = MostRecent.StartTime
                AND A.SSN = MostRecent.SSN
                AND FutureVisitDate is NOT NULL) B
WHERE P.SSN = B.SSN; 


/* #9 This query is to select all equipment types with less than 2 technicians that work with them */
Select TypeID
FROM EquipmentType
WHERE TypeID not in (   SELECT TypeID	
                        FROM	(SELECT TypeID, COUNT(EmployeeID) AS NumOfEmployees
    	                FROM EquipmentTechnicianWorksWithType
    	                GROUP BY TypeID) R
                        WHERE R.NumOfEmployees > 1);


/* #10 This query is to select the date of the coming future visit for patient with SSN = '111-22-3333' */
SELECT FutureVisitDate
FROM Admission
WHERE StartDate = (	SELECT MAX(StartDate)
					FROM Admission
					WHERE SSN = 111223333);

/* #11 This query is to select the employee id's of doctors who have examined patient with SSN = 111-22-3333 more than twice */
SELECT EmployeeID
FROM (  SELECT EmployeeID, COUNT(EmployeeID) AS NumOfTimesExamined
        FROM (  SELECT EmployeeID, SSN
                FROM DoctorExaminesDuringAdmission
                WHERE SSN =111223333)
        GROUP BY EmployeeID)
WHERE NumOfTimesExamined > 2;

/* #12 This query is to report the equipment types, typeID, for which the hospital has purchased units in 2010 and 2011, without duplications */
SELECT DISTINCT TypeID
FROM EquipmentUnit
WHERE TypeID IN (   (SELECT TypeID
                    FROM EquipmentUnit
                    WHERE YearOfPurchase = 2010)
                INTERSECT
                    (SELECT TypeID
                    FROM EquipmentUnit
                    WHERE YearOfPurchase = 2011));







