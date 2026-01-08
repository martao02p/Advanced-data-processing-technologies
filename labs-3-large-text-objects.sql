set serveroutput on;

-- 1. Create table DOKUMENTY (ID + CLOB)
create table dokumenty (
   id number(12) primary key,
   dokument clob
);

-- desc dokumenty;

-- 2. Insert doc ID=1 as 10000x Oto tekst.
declare
v_clob   clob;
    v_piece  varchar2(20) := 'Oto tekst. ';
begin
    dbms_lob.createtemporary(v_clob, true);

for i in 1..10000 loop
        dbms_lob.writeappend(v_clob, length(v_piece), v_piece);
end loop;

insert into dokumenty (id, dokument) values (1, v_clob);

dbms_lob.freetemporary(v_clob);
commit;
end;

-- 3. Queries for document(s)
-- a) full table
select * from dokumenty;

-- b) document uppercased
select id, upper(dokument) as dokument_upper
from dokumenty;

-- c) size using LENGTH (works for CLOB too)
select id, length(dokument) as doc_len_length
from dokumenty;

-- d) size using DBMS_LOB.GETLENGTH (proper LOB way)
select id, dbms_lob.getlength(dokument) as doc_len_lob
from dokumenty;

-- e) substring 1000 chars from position 5 using SUBSTR
select id, substr(dokument, 5, 1000) as doc_substr_sql
from dokumenty;

-- f) substring 1000 chars from position 5 using DBMS_LOB.SUBSTR
select id, dbms_lob.substr(dokument, 1000, 5) as doc_substr_lob
from dokumenty;

-- 4. Insert doc ID=2 as EMPTY_CLOB()
insert into dokumenty (id, dokument) values (2, empty_clob());

-- 5. Insert doc ID=3 as NULL
insert into dokumenty (id, dokument) values (3, null);

commit;

-- 6. Repeat queries from step 3 for all 3 docs
select * from dokumenty;

select id, upper(dokument) as dokument_upper
from dokumenty
order by id;

select id, length(dokument) as doc_len_length
from dokumenty
order by id;

select id, dbms_lob.getlength(dokument) as doc_len_lob
from dokumenty
order by id;

select id, substr(dokument, 5, 1000) as doc_substr_sql
from dokumenty
order by id;

select id, dbms_lob.substr(dokument, 1000, 5) as doc_substr_lob
from dokumenty
order by id;

-- 7. Load dokument.txt (BFILE) into CLOB for ID=2 using LOADCLOBFROMFILE
declare
v_src        bfile := bfilename('TPD_DIR', 'dokument.txt');
    v_dst        clob;

    v_dest_off integer := 1;
    v_src_off integer := 1;
    v_csid number := 0;
    v_lang_ctx integer := 0;
    v_warning integer := null;
begin
    -- lock the row and get the CLOB locator
select dokument
into v_dst
from dokumenty
where id = 2
    for update;

-- open file + copy text into CLOB
dbms_lob.fileopen(v_src, dbms_lob.file_readonly);

    dbms_lob.loadclobfromfile(
        dest_lob     => v_dst,
        src_bfile    => v_src,
        amount       => dbms_lob.lobmaxsize,
        dest_offset  => v_dest_off,
        src_offset   => v_src_off,
        bfile_csid   => v_csid,
        lang_context => v_lang_ctx,
        warning      => v_warning
    );

    dbms_lob.fileclose(v_src);

commit;

dbms_output.put_line(nvl(to_char(v_warning), 'NULL'));
end;

-- 8. Load dokument.txt into ID=3

update dokumenty
set dokument = to_clob(bfilename('TPD_DIR', 'dokument.txt'))
where id = 3;

commit;

-- 9.
select * from dokumenty;

-- 10. Read sizes of all docs
select id,
       length(dokument) as len_sql,
       dbms_lob.getlength(dokument) as len_lob
from dokumenty
order by id;

-- 11. Drop table DOKUMENTY
drop table dokumenty purge;

-- 12. Procedure CLOB_CENSOR: replace every occurrence of text with dots
create or replace procedure clob_censor(
    p_clob in out clob,
    p_pattern in varchar2
) is
    v_pos integer := 0;
    v_len integer := length(p_pattern);
    v_dots varchar2(32767);
    v_nth integer := 1;
begin
    v_dots := rpad('.', v_len, '.');

    loop
        -- DBMS_LOB.INSTR is safer for LOBs than plain INSTR
v_pos := dbms_lob.instr(p_clob, p_pattern, 1, v_nth);

        exit when v_pos = 0;

        -- overwrite text at v_pos with dots
        dbms_lob.write(p_clob, v_len, v_pos, v_dots);

        v_nth := v_nth + 1;
end loop;
end clob_censor;

-- 13. Copy BIOGRAPHIES from ZTPD and test censoring Cimrman
create table biographies_copy as
select *
from ztpd.biographies;

-- select * from biographies_copy;

declare
v_bio clob;
begin
    -- pick the row that contains Cimrman and lock it.
select bio
into v_bio
from biographies_copy
where dbms_lob.instr(bio, 'Cimrman') > 0
    fetch first 1 row only
    for update;

clob_censor(v_bio, 'Cimrman');

commit;
end;

select id, person, bio
from biographies_copy
where dbms_lob.instr(bio, '......') > 0
   or dbms_lob.instr(bio, 'Cimrman') > 0;

-- 14. Drop copy
drop table biographies_copy purge;
