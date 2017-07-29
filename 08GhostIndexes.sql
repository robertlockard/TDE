set echo on
set feedback on
CREATE TABLESPACE small_idx DATAFILE '/home/oracle/app/oracle/oradata/demo1/small_idx.dbf' SIZE 10M;
CREATE TABLESPACE dat DATAFILE '/home/oracle/app/oracle/oradata/demo1/dat.dbf' SIZE 10M;

-- now lets recreate our test data and encrypt it.

drop table employees_tst;

CREATE TABLE employees_tst
tablespace dat
    as (select *
        from employees
        where rownum <= 1000);

ALTER TABLE employees_tst MODIFY
    (ssn      encrypt USING 'AES256' NO SALT);

-- we are going to build an index on SSN
CREATE INDEX employees_ssn_idx ON employees_tst(ssn) TABLESPACE small_idx;
-- flush the buffer cache
alter system flush buffer_cache;


