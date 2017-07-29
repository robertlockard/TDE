DROP TABLE EMPLOYEES;
CREATE TABLE EMPLOYEES AS SELECT * FROM EMPLOYEES_BAK;
DROP TABLE t1;
DROP TABLE t3;
set echo on

--Test 1)   Note, we are putting this into a non-encrypted tablespace, we are going to explicitly encrypt column D1.

--CREATE A TEST TABLE
CREATE TABLE t1 (id NUMBER GENERATED AS IDENTITY, d1 VARCHAR2(255)) TABLESPACE users;


 -- ENCRYPT THE DATA
alter table t1 modify (d1 encrypt using 'AES256');

pause

 --INSERT SOME TEST DATA
insert into t1 (D1) (select 'Encrypt your data' from dual connect by level <= 10);
insert into t1 (D1) (select 'Is this encrypted?' from dual connect by level <= 5);
insert into t1 (D1) (select 'Practice Secure Computing' from dual connect by level <= 20);

commit;

pause

 -- GATHER STATISTICS ALONG WITH HISTOGRAMS.
begin
   dbms_stats.gather_table_stats(null,'T1', method_opt=> 'for all columns size skewonly');
end;
/

pause
 -- THIS LOOKS GOOD
select
         endpoint_number,
         endpoint_actual_value
from dba_tab_histograms
where owner = 'RLOCKARD'
  and table_name = 'T1'
  and column_name = 'D1';

pause

 -- HOWEVER, WHEN WE DIG  A BIT FURTHER IT'S QUITE EASY TO
 -- TRANSLATE ENDPOINT_VALUE INTO THE FIRST CHARACTERS OF THE
 -- DATA THEREBY EXPOSING THE INFORMATION.
 -- NOTE THIS QUERY IS FROM Jonathan Lewis blog at: https://jonathanlewis.wordpress.com/category/oracle/statistics/histograms/


select
          endpoint_number,
          endpoint_number - nvl(prev_endpoint,0) frequency,
          hex_val,
          chr(to_number(substr(hex_val, 2,2),'XX')) ||
          chr(to_number(substr(hex_val, 4,2),'XX')) ||
          chr(to_number(substr(hex_val, 6,2),'XX')) ||
          chr(to_number(substr(hex_val, 8,2),'XX')) ||
          chr(to_number(substr(hex_val,10,2),'XX')) ||
          chr(to_number(substr(hex_val,12,2),'XX')) ||
          chr(to_number(substr(hex_val,14,2),'XX')) ||
          chr(to_number(substr(hex_val,16,2),'XX')),
          endpoint_actual_value
from    (
          select
                  endpoint_number,
                  lag(endpoint_number,1) over(
                          order by endpoint_number
 ) prev_endpoint, to_char(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_val,
                  endpoint_actual_value
          from
                  dba_tab_histograms
          WHERE
                  owner = 'RLOCKARD'
          AND     table_name = 'T1'
          and     column_name = 'D1'
          )
order by
endpoint_number
/

pause


 --TEST 2)
 --Important note: THIS IS ALL PSEUDO DATA, NOTING IS REAL.

 -- the test customers table contains pseudo ssn's and cc numbers for demo purposes.
 -- reality is, because cc_nbr and ssn are distinct, histograms should not be gathered,
 -- however a "lazy" DBA may use the 'for all columns size skewonly' method_opt
 -- therefore, by using the defaults you will get out 254 rows with data that should be encrypted.

alter table employees modify (SSN encrypt using 'AES256');

pause

 -- GATHER STATISTICS ALONG WITH HISTOGRAMS.
begin
   dbms_stats.gather_table_stats(null,'EMPLOYEES', method_opt=> 'for all columns size skewonly');
end;
/
pause

set linesize 90
desc employees


select
       endpoint_number,
       endpoint_actual_value
from dba_tab_histograms
where owner = 'RLOCKARD'
  and table_name = 'EMPLOYEES'
  and column_name = 'SSN';

pause

SELECT * FROM employees WHERE SSN='&ssn';
