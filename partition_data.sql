------ PARTITION ------
-- This script partitions the initial database table (dataset) into two
-- subsets: testset and trainset. It also verticalizes the data in the
-- sense that it creates a record in testset or trainset for each column
-- in each record of dataset.
-- run using (-td~ -vf) 

---- INITIALIZATION ----

CONNECT TO DBKB~

-- drop the tables we're about to create, in case they already exist
DROP TABLE TESTDATA~
DROP TABLE TRAINDATA~

-- create the tables

CREATE TABLE TESTDATA("PID" INTEGER, "COLUMNNO" INTEGER, "ATT" VARCHAR(10),"DECISION" VARCHAR(10), "WEIGHT" INTEGER)~
CREATE TABLE TRAINDATA("PID" INTEGER, "COLUMNNO" INTEGER, "ATT" VARCHAR(10),"DECISION" VARCHAR(10), "WEIGHT" INTEGER)~

-- transfer content to trainset and testset

BEGIN ATOMIC
	FOR temp AS SELECT * FROM DATASET ORDER BY PID DO
	IF rand() > 0.8 THEN
		INSERT INTO TEST_DATASET VALUES 
		(temp.PID, 3, temp.sex, temp.survived, 1),
		(temp.PID, 1, temp.class, temp.survived, 1),
		(temp.PID, 2, temp.type, temp.survived, 1);
		
	ELSE
		INSERT INTO TRAIN_DATASET VALUES 
		(temp.PID, 3, temp.sex, temp.survived, 1),
		(temp.PID, 1, temp.class, temp.survived, 1),
		(temp.PID, 2, temp.type, temp.survived, 1);
	END IF;
	END FOR;
END~

---- CLEAN UP ----

CONNECT RESET ~
TERMINATE~
