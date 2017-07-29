SELECT segment_name FROM dba_segments WHERE tablespace_name = 'DAT';
purge recyclebin;

-- recreate the dat tablespace
CREATE TABLESPACE dat DATAFILE '/opt/oracle/oradata/DEV/datafile/dat01.dbf' SIZE 10M;

ALTER USER rlockard DEFAULT TABLESPACE dat;
DROP MATERIALIZED VIEW customer_sales;
DROP TABLE customers_tst CASCADE CONSTRAINTS;


-- move the table to an encrypted tablespace

CREATE TABLE customers_tst
  TABLESPACE sensitive_dat
  AS (SELECT * FROM customers
      WHERE ROWNUM <= 1000);
-- add the primary key      

ALTER TABLE customers_tst ADD CONSTRAINT c_pk PRIMARY KEY (id);

-- this will go into default tablespace.  
CREATE INDEX customers_tst_idx1 ON customers_tst(ssn);

SELECT tablespace_name FROM user_indexes
WHERE index_name = 'CUSTOMERS_TST_IDX1';

select ENCRYPTED from dba_tablespaces where tablespace_name = 'DAT';

-- create a materialized view on the customers_tst and sales table.
-- in this example we are putting the mv in a non-encrypted tablespace
-- to demo leakage.
CREATE MATERIALIZED VIEW customer_sales
     PARALLEL 4
     BUILD IMMEDIATE
     REFRESH COMPLETE
     ENABLE QUERY REWRITE
AS SELECT c.fname,
          c.lname,
          c.state,
          c.ssn,
          c.cc_nbr,
          s.product_id,
          s.price
   FROM customers_tst c,
        sales s
   where c.id = s.cust_id;
   
CREATE MATERIALIZED VIEW LOG ON CUSTOMERS_TST 
TABLESPACE DAT 
WITH PRIMARY KEY, 
    ROWID(
    FNAME, 
    LNAME, 
    CITY, 
    STATE, 
    ZIP, 
    DISCOUNT, 
    CC_NBR, 
    REGION, 
    SSN);
   
   
SELECT * FROM customer_sales;

select tablespace_name from dba_segments where segment_name = 'CUSTOMER_SALES';
   
-- how do you audit this?
-- get a list of all objects that are in encrypted tablepaces.
-- get a list of all objects that are dependent of objects
-- in encrypted tablespaces and what tablespaces they are in.          
-- for every object in an encrypted tablespace get a list of all dependencies
-- and what tablespace the object resides in.  We know physical objects  are
-- of type, 'TABLE', 'INDEX', 'MATERALIZED VIEW'

SELECT d.owner,
       d.NAME,
       s.tablespace_name,
       t.ENCRYPTED
FROM dba_dependencies d,
     dba_segments s,
     dba_tablespaces t
WHERE d.owner = s.owner
  AND d.NAME = s.segment_name
  and s.tablespace_name = t.tablespace_name
  and referenced_name IN (
  SELECT segment_name
  FROM dba_segments
  WHERE tablespace_name IN 
    (SELECT tablespace_name
     FROM dba_tablespaces
     WHERE ENCRYPTED = 'YES'))
UNION
SELECT i.owner,
       i.index_name,
       i.tablespace_name,
       dd.ENCRYPTED
FROM dba_indexes i,
     dba_tablespaces dd
WHERE i.tablespace_name = dd.tablespace_name
  AND table_name IN (
      SELECT segment_name
  FROM dba_segments
  WHERE tablespace_name IN 
    (SELECT tablespace_name
     FROM dba_tablespaces
     WHERE ENCRYPTED = 'YES'));


-- so we have learned that dependent objects will fall into the default tablespace.
-- if that tablespace is not encrypted, then you must drop those objects, shread 
-- and data and rebuild in encrypted tablespaces.  As an added control, make the 
-- default tablespace for shemas an encrypted tablespace.

ALTER USER rlockard DEFAULT TABLESPACE sensitive_dat;
ALTER INDEX CUSTOMERS_TST_IDX1 REBUILD TABLESPACE SENSITIVE_IDX;
alter index c_pk rebuild tablespace sensitive_idx;

-- drop the materialized view customer_sales;
DROP MATERIALIZED VIEW customer_sales;

-- drop the dat tablespace shred and remove it.
DROP TABLESPACE dat including contents;

-- strings /opt/oracle/oradata/DEV/datafile/dat01.dbf
select * from customers_tst where cc_nbr = '3421243562958464';
-- shred /opt/oracle/oradata/DEV/datafile/dat01.dbf
-- rm /opt/oracle/oradata/DEV/datafile/dat01.dbf

-- recreate the materialized view and materialized view log in 
-- the sensitive_dat tablespace
CREATE MATERIALIZED VIEW customer_sales
     PARALLEL 4
     BUILD IMMEDIATE
     REFRESH COMPLETE
     ENABLE QUERY REWRITE
AS SELECT c.fname,
          c.lname,
          c.state,
          c.ssn,
          c.cc_nbr,
          s.product_id,
          s.price
   FROM customers_tst c,
        sales s
   where c.id = s.cust_id;
   
CREATE MATERIALIZED VIEW LOG ON CUSTOMERS_TST 
TABLESPACE sensitive_dat
WITH PRIMARY KEY, 
    ROWID(
    FNAME, 
    LNAME, 
    CITY, 
    STATE, 
    ZIP, 
    DISCOUNT, 
    CC_NBR, 
    REGION, 
    SSN);


SELECT d.owner,
       d.NAME,
       s.tablespace_name,
       t.ENCRYPTED
FROM dba_dependencies d,
     dba_segments s,
     dba_tablespaces t
WHERE d.owner = s.owner
  AND d.NAME = s.segment_name
  and s.tablespace_name = t.tablespace_name
  and referenced_name IN (
  SELECT segment_name
  FROM dba_segments
  WHERE tablespace_name IN 
    (SELECT tablespace_name
     FROM dba_tablespaces
     WHERE ENCRYPTED = 'YES'))
UNION
SELECT i.owner,
       i.index_name,
       i.tablespace_name,
       dd.ENCRYPTED
FROM dba_indexes i,
     dba_tablespaces dd
WHERE i.tablespace_name = dd.tablespace_name
  AND table_name IN (
      SELECT segment_name
  FROM dba_segments
  WHERE tablespace_name IN 
    (SELECT tablespace_name
     FROM dba_tablespaces
     WHERE ENCRYPTED = 'YES'));
