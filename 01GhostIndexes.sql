set echo on
set feedback on
CREATE TABLESPACE small_idx DATAFILE '/home/oracle/app/oracle/oradata/demo1/small_idx.dbf' SIZE 10M;
CREATE TABLESPACE dat DATAFILE '/home/oracle/app/oracle/oradata/demo1/dat.dbf' SIZE 10M;

-- create a test table from employees.
CREATE TABLE employees_tst
tablespace dat
    as (select *
        from employees);

-- we are going to build an index on SSN
CREATE INDEX employees_ssn_idx ON employees_tst(ssn) TABLESPACE small_idx;

ALTER TABLE employees_tst MODIFY
    (ssn      encrypt USING 'AES256' NO SALT);

-- now lets do an index rebuild and test for ghost data
-- ALTER INDEX employees_ssn_idx REBUILD;

-- in root container run flush the buffer cache
alter system flush buffer_cache;

