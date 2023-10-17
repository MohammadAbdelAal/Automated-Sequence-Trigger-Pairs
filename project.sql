set serveroutput on size 1000000

--GRID 1
SELECT distinct cols.column_name, cols.table_name
FROM USER_constraints cons, USER_cons_columns cols, USER_TAB_COLUMNS tc
WHERE cons.constraint_name = cols.constraint_name AND cols.COLUMN_NAME = tc.COLUMN_NAME
AND cons.constraint_type = 'P'
AND tc.DATA_TYPE='NUMBER'
order by cols.column_name, cols.table_name;

declare
--varies for each table  
v_seq_start number; -- to store sequence start
v_column_name varchar2(4000);
v_table_name varchar2(30);

--to get all prev sequences to drop them
cursor all_seq_names_c is select SEQUENCE_NAME from USER_SEQUENCES;

-- to get all identifying columns and  their tables
cursor all_columns_pk_c is SELECT distinct cols.column_name, cols.table_name
FROM USER_constraints cons, USER_cons_columns cols, USER_TAB_COLUMNS tc
WHERE cons.constraint_name = cols.constraint_name AND cols.COLUMN_NAME = tc.COLUMN_NAME
AND cons.constraint_type = 'P'
AND tc.DATA_TYPE='NUMBER'
order by cols.column_name, cols.table_name;

begin

for all_seq_names_r in all_seq_names_c loop
Execute Immediate 'DROP SEQUENCE '||all_seq_names_r.SEQUENCE_NAME;
end loop;
-- all prev sequences are dropped

-- LOOP on all identifying columns and their tables
for all_columns_pk_r in all_columns_pk_c loop

--print current iteration
dbms_output.put_line('column '||all_columns_pk_r.COLUMN_NAME||' from '||all_columns_pk_r.table_name);

--calc the start of sequence of current iteration
execute immediate 'select max('||all_columns_pk_r.Column_name||')+1 from '||all_columns_pk_r.table_name into v_seq_start;

--if table is empty, assign the start of sequence of current iteration to 1 instead of null
--TO AVOID ERROR during creation later
if v_seq_start is null then v_seq_start:= 1; 
end if;

dbms_output.put_line('sequence starts from '||v_seq_start);



--create sequence for current iteration
Execute Immediate 'CREATE SEQUENCE '||all_columns_pk_r.table_name||'_SEQ
START WITH '||v_seq_start||' MAXVALUE 999999';

--assign record data to variables to avoid invalid reference error later
v_column_name:= all_columns_pk_r.COLUMN_NAME;
v_table_name:= all_columns_pk_r.table_name;

--creating trigger for current iteration
Execute Immediate 'create or replace TRIGGER '||v_table_name||'_TRG BEFORE INSERT ON '||v_table_name||' for each row
begin :new.'||v_column_name||':='||v_table_name||'_SEQ.nextval; END;';

end loop;
end;
show errors
