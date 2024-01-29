CREATE DATABASE ExamBook762Ch3;
GO
USE ExamBook762Ch3;
GO
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.TestParent
(
	ParentId int NOT NULL
		CONSTRAINT PkTestParent PRIMARY KEY,
	ParentName varchar(100) NULL
);

CREATE TABLE Examples.TestChild
(
	ChildId INT NOT NULL
		CONSTRAINT PkTestChild PRIMARY KEY,
	ParentId int NOT NULL,
	ChildName varchar(100) NULL
);

ALTER TABLE Examples.TestChild
	ADD CONSTRAINT FkTestchild_Ref_TestParent
		FOREIGN KEY (ParentId) REFERENCES Examples.TestParent(ParentId);

INSERT INTO Examples.TestParent (ParentId, ParentName)
VALUES (1, 'Dean'), (2, 'Michael'), (3, 'Robert');

INSERT INTO Examples.TestChild (ChildId, ParentId, ChildName)
VALUES (1, 1, 'Daniel'), (2, 1, 'Alex'), (3, 2, 'Matthew'), (4, 3, 'Jason');

UPDATE Examples.TestParent
SET ParentName = 'Robert'
WHERE ParentName = 'Bob';

BEGIN TRAN
	UPDATE Examples.TestParent
	SET ParentName = 'Bob'
	WHERE ParentName = 'Robert';

--ATOMICITY

BEGIN TRAN;
	UPDATE Examples.TestParent
	SET ParentName = 'Mike'
	WHERE ParentName = 'Michael';

	UPDATE Examples.TestChild
	SET ChildName = 'Matt'
	WHERE ChildName = 'Matthew';
COMMIT TRAN;

--SELECT @@TRANCOUNT

--DBCC OPENTRAN

SELECT TestParent.ParentId, ParentName, ChildId, ChildName
FROM Examples.TestParent
	FULL OUTER JOIN Examples.TestChild 
	ON TestParent.ParentId = TestChild.ParentId;

--Common misconception - BEGIN TRAN and COMMIT TRAN do not always ensure atomicity

BEGIN TRAN;
	INSERT INTO Examples.TestParent (ParentId, ParentName)
	VALUES (4, 'Linda');

--DELETE statement below fails due to violation of REFERENCE Constraint with the foreign key in TestChild Table
DELETE Examples.TestParent
WHERE ParentName = 'Bob';
COMMIT TRAN

SELECT *
FROM Examples.TestParent;

--First statement passed and the second statement failed, to ensure atomicity turn XACT_ABORT ON prior to executing the statement

DELETE Examples.TestParent
WHERE ParentId = 4;

SET XACT_ABORT ON;
BEGIN TRAN;
	INSERT INTO Examples.TestParent (ParentId, ParentName)
	VALUES (4, 'Linda');
	
DELETE Examples.TestParent
WHERE ParentName = 'Bob';
COMMIT TRAN

-- XACT_ABORT works when executing 2 statements and the second one fails, it rolls back the whole transaction
-- When there is a syntax error even in the second statement, the whole transaction does not execute.
SET XACT_ABORT OFF;
BEGIN TRAN;
	INSERT INTO Examples.TestParent (ParentId, ParentName)
	VALUES (5, 'Isabelle');
	
DELETE Examples.TestParent
WHEN ParentName = 'Bob';
COMMIT TRAN

-- Arguably the best way to ensure atomicity is by using Try - Catch block 

BEGIN TRY
	BEGIN TRAN;
		INSERT INTO Examples.TestParent (ParentId, ParentName)
		VALUES (5, 'Isabelle');

		DELETE Examples.TestParent
		WHERE ParentName = 'Bob';
	COMMIT TRAN;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRAN;
END CATCH

-- CONSISTENCY