DROP TABLE EMPLOYEES;
CREATE TABLE EMPLOYEES AS SELECT * FROM EMPLOYEES_BAK;
DROP TABLE t1;
DROP TABLE t3;
set echo on

 --TEST 2)
 --Important note: THIS IS ALL PSEUDO DATA, NOTING IS REAL.

 -- the test customers table contains pseudo ssn's and cc numbers for demo purposes.
 -- reality is, because cc_nbr and ssn are distinct, histograms should not be gathered,
 -- however a "lazy" DBA may use the 'for all columns size skewonly' method_opt
 -- therefore, by using the defaults you will get out 254 rows with data that should be encrypted.

alter table employees modify (SSN encrypt using 'AES256');

pause

 begin
   dbms_stats.gather_table_stats(null,'EMPLOYEES');
 end;
 /

pause

set linesize 90
desc t3


select
       endpoint_number,
       endpoint_actual_value
from dba_tab_histograms
where owner = 'RLOCKARD'
  and table_name = 'EMPLOYEES'
  and column_name = 'SSN';

pause

info+ employees
