--Build a Naive Bayesian Classifier using DB2's SQL aggregates and (preferably) table functions, and store it in a table called NBC. 
CONNECT TO DBKB;

DROP TABLE NBC;

CREATE TABLE NBC("CLASS_COUNT_PER_ATTRIBUTE" DECIMAL,"TOTAL_CLASS_COUNT" DECIMAL,"DECISION" VARCHAR(10), "ATT" VARCHAR(10), "COLUMNNO" INTEGER, "PROBABILITY" DOUBLE);

INSERT INTO NBC
WITH TEMP1 AS(
--COUNT OF CLASS VARIABLES OVERALL 
SELECT COUNT(DISTINCT PID) AS CLASS_COUNT,DECISION FROM TRAINDATA GROUP BY DECISION
),
TEMP2 AS(
--COUNT OF CLASS VAR FOR EACH VARIABLE ATTRIBUTE
SELECT COLUMNNO, ATT,COUNT(DISTINCT PID) AS CLASS_COUNT_PER_ATTRIBUTE,DECISION FROM TRAINDATA GROUP BY COLUMNNO,ATT,DECISION
)
--PROBABILITY FOR EACH ATTRIBUTE VALUE => COUNT OF YES FOR THAT ATTRIBUTE/TOTAL YES
SELECT CLASS_COUNT_PER_ATTRIBUTE,CLASS_COUNT,T2.DECISION,T2.ATT,T2.COLUMNNO,FLOAT(CLASS_COUNT_PER_ATTRIBUTE)/CLASS_COUNT FROM TEMP1 AS T1, TEMP2 AS T2 WHERE T1.DECISION=T2.DECISION;



-- INSERT FOR CLASS LABEL AND THEIR PROBABILITIES

DROP TABLE PROBABILITY_CLASS_LABELS;

CREATE TABLE PROBABILITY_CLASS_LABELS("DECISION" VARCHAR(20), "CLASS_COUNT" DECIMAL, "TOTAL_ROWS" DECIMAL,"PROBABILITY" DOUBLE);

INSERT INTO PROBABILITY_CLASS_LABELS
WITH TEMP1 AS(
SELECT COUNT(DISTINCT PID) AS CLASS_COUNT,DECISION FROM TRAINDATA GROUP BY DECISION
),
TEMP2 AS(
SELECT COUNT(DISTINCT PID) AS TOTAL_ROW_COUNT FROM TRAINDATA
)
SELECT DECISION,CLASS_COUNT, TOTAL_ROW_COUNT, FLOAT(CLASS_COUNT)/TOTAL_ROW_COUNT FROM TEMP1,TEMP2;

DROP TABLE NBC_TESTDATA;

CREATE TABLE NBC_TESTDATA("PID" INTEGER,"PREDICTED_DECISION" VARCHAR(20),"TEST_DATA_DECISION" VARCHAR(20));

--create NBC table which stores the predicted value and actual test data values
INSERT INTO NBC_TESTDATA
WITH TEMP1 AS(
SELECT PID,COLUMNNO,ATT,P.DECISION AS PROBABLE_DECISION FROM TESTDATA, PROBABILITY_CLASS_LABELS AS P ORDER BY PID
), 
TEMP2 AS(
SELECT PID,T1.COLUMNNO,T1.ATT,DECISION,PROBABILITY FROM TEMP1 AS T1 INNER JOIN NBC AS P ON P.COLUMNNO=T1.COLUMNNO AND P.ATT=T1.ATT
),
TEMP4 AS(
SELECT DISTINCT * FROM TEMP2
),
TEMP3 AS(
SELECT SUM(LOG(PROBABILITY)) AS PROBS,PID,DECISION FROM TEMP4 GROUP BY DECISION,PID
),
TEMP5 AS(
--ADD CLASS LABELS'S PROBABILITY TO THESE VALUES
SELECT (PROBS+LOG(PROBABILITY)) AS FINAL_PROB,PID,T3.DECISION  FROM TEMP3 AS T3,PROBABILITY_CLASS_LABELS AS P WHERE T3.DECISION=P.DECISION
),
TEMP6 AS(
-- NOW WE FIND MAX OF THESE VALUES WHICH BECOME OUR PREDICTION
SELECT MAX(FINAL_PROB) AS PROB,PID FROM TEMP5 GROUP BY PID
),
TEMP7 AS(
--WE GET PREDICTED DECISION
SELECT T5.PID,T5.DECISION FROM TEMP5 AS T5, TEMP6 AS T6 WHERE T5.PID=T6.PID AND T5.FINAL_PROB=T6.PROB
),
TEMP9 AS(
--THIS HAS ALL THE ACTUAL DATASET
SELECT DISTINCT PID, DECISION FROM TESTDATA ORDER BY PID
),
TEMP8 AS(
SELECT T7.PID,T7.DECISION AS PREDICTED_DECISION, T9.DECISION AS TEST_DATA_DECISION FROM TEMP7 AS T7, TEMP9 AS T9 WHERE T7.PID=T9.PID
)
SELECT * FROM TEMP8;
 --SUM OF PROB FOR EVERY CLASS LABEL

--HANDLE MISSING ATTRIBUTE CLASS LABEL PAIR 
WITH ATT_COL_COMBO AS(
--handle missing values
--get all col, attribute pair
SELECT DISTINCT ATT,COLUMNNO FROM TRAINDATA
),
DECISION_PERMUTATION AS(
SELECT A.*,P.DECISION FROM ATT_COL_COMBO AS A,PROBABILITY_CLASS_LABELS AS P
),
ALL_NBC AS(
-- ATTRIBUTE AND CLASS LABEL PAIR IS NOT MISSING, GET THOSE ROWS
SELECT D.* FROM NBC AS P,DECISION_PERMUTATION AS D WHERE D.COLUMNNO=P.COLUMNNO AND D.ATT=P.ATT AND D.DECISION=P.DECISION
),
MISSING_ROWS AS(
SELECT ATT,COLUMNNO,DECISION FROM NBC WHERE NOT EXISTS(SELECT * FROM DECISION_PERMUTATION)
)
SELECT 0 AS CLASS_COUNT_PER_ATTRIBUTE,0 AS TOTAL_CLASS_COUNT, DECISION,ATT, 0.00001 AS PROBABILITY FROM MISSING_ROWS;

CALL GET_ACCURACY_NBC(?,?,?);

TERMINATE;



