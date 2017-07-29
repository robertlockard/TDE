ALTER USER rlockard DEFAULT TABLESPACE NOT_SENSITIVE;

drop table customers_tst;
-- create a table, encrypt cc_nbr and ssn with salt.
CREATE TABLE customers_tst (
 ID       NUMBER    PRIMARY KEY,
 FNAME    VARCHAR2(25),
 LNAME    VARCHAR2(25),
 CITY     VARCHAR2(25),
 STATE    VARCHAR2(25),
 ZIP      NUMBER,
 DISCOUNT NUMBER,
 CC_NBR   VARCHAR2(16) encrypt salt,
 REGION   NUMBER,
 SSN      VARCHAR2(11) encrypt salt
);

-- poplulate the table with data from the customers table.
INSERT INTO customers_tst
(SELECT * FROM customers WHERE ROWNUM <= 1000);

COMMIT;

-- attempt to create an index on ssn.
CREATE INDEX customers_tst_idx ON customers_tst(ssn)  TABLESPACE sensitive_idx;

-- alter the table so ssn is nt using salt
ALTER TABLE customers_tst MODIFY (ssn encrypt NO salt);

CREATE INDEX customers_tst_idx ON customers_tst(ssn)  TABLESPACE not_sensitive_idx;

-- strings /opt/oracle/oradata/DEV/datafile/not_sensitive01.dbf
-- strings /opt/oracle/oradata/DEV/datafile/not_sensitive_idx01.dbf