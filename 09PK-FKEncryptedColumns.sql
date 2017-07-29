DROP TABLE sales_tst;

CREATE TABLE sales_tst TABLESPACE NOT_SENSITIVE AS (SELECT * FROM sales WHERE cust_id IN (SELECT ID FROM customers_tst));

ALTER TABLE sales_tst ADD CONSTRAINT s_pk PRIMARY KEY (ID) USING INDEX TABLESPACE not_sensitive_idx;

-- adding the fk constraint to customers_tst
ALTER TABLE sales_tst ADD CONSTRAINT s_fk1 FOREIGN KEY (cust_id) REFERENCES customers_tst(ID);

-- what happens when we try to encrypte the fk column?
alter table sales_tst modify (cust_id encrypt);
-- so as long as the fk column is not encrypted, we can create a pk/fk relationship.
