set echo on
set feedback on

DROP TABLE employees_tst;

DROP TABLESPACE small_idx INCLUDING CONTENTS;
DROP TABLESPACE dat INCLUDING CONTENTS;

shred /home/oracle/app/oracle/oradata/demo1/small_idx.dbf
shred /home/oracle/app/oracle/oradata/demo1/dat.dbf
rm /home/oracle/app/oracle/oradata/demo1/small_idx.dbf
rm /home/oracle/app/oracle/oradata/demo1/dat.dbf
