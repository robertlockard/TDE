DROP TABLE sales_tst;

CREATE TABLE sales_tst TABLESPACE sensitive_dat AS (SELECT * FROM sales WHERE cust_id IN (SELECT ID FROM customers_tst));
ALTER TABLE sales_tst ADD CONSTRAINT s_pk PRIMARY KEY (ID) USING INDEX TABLESPACE sensitive_idx;
-- adding the fk constraint to customers_tst
ALTER TABLE sales_tst ADD CONSTRAINT s_fk1 FOREIGN KEY (cust_id) REFERENCES customers_tst(ID);

select tablespace_name from user_tables where table_name = 'SALES_TST';

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
