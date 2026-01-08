-- 1. Copy MOVIES table from ZTPD schema
create table movies as
select *
from ztpd.movies;

-- select count(*) from movies;

-- 2. Check table structure (BLOB column is the main point)
desc movies;

-- 3. Movies without covers (COVER is NULL)
select id, title
from movies
where cover is null;

-- 4. For movies with covers read the size in bytes
select id,
    title,
    dbms_lob.getlength(cover) as filesize
from movies
where cover is not null
order by id;

-- 5. What happens if we try getlength() for NULL covers?
-- It returns NULL (so filesize column is empty).
select id,
    title,
    dbms_lob.getlength(cover) as filesize
from movies
where cover is null
order by id;

-- 6. Check DIRECTORY object: TPD_DIR (path on server)
select directory_name, directory_path
from all_directories
where directory_name = 'TPD_DIR';

-- 7. Set movie 66 cover to EMPTY_BLOB() (locator without data) + set mime
update movies
set cover = empty_blob(),
    mime_type = 'image/jpeg'
where id = 66;

commit;

-- 8. Check size for movies 65 and 66 (66 is 0 now, 65 is NULL)
select id,
    title,
    dbms_lob.getlength(cover) as filesize
from movies
where id in (65, 66)
order by id;

-- 9. Load escape.jpg from server directory into MOVIES.COVER for movie 66
-- Steps:
-- 1) bind BFILE -> BFILENAME('TPD_DIR','escape.jpg')
-- 2) select BLOB FOR UPDATE (lock row)
-- 3) open file + loadfromfile + close
-- 4) commit

declare
v_src  bfile := bfilename('TPD_DIR', 'escape.jpg');
    v_dst  blob;
    v_size number;
begin
    -- lock row + get BLOB locator
select cover
into v_dst
from movies
where id = 66
    for update;

-- open file and copy bytes
dbms_lob.fileopen(v_src, dbms_lob.file_readonly);
    v_size := dbms_lob.getlength(v_src);

    dbms_lob.loadfromfile(v_dst, v_src, v_size);

    dbms_lob.fileclose(v_src);

commit;
end;

-- 10. Create TEMP_COVERS table (BFILE storage)
create table temp_covers (
    movie_id  number(12),
    image     bfile,
    mime_type varchar2(50)
);

-- 11. Insert eagles.jpg as BFILE for movie 65 + set mime
insert into temp_covers values
    (65, bfilename('TPD_DIR', 'eagles.jpg'), 'image/jpeg');

commit;

-- 12. Read size in bytes of BFILE (from TEMP_COVERS)
select movie_id,
       dbms_lob.getlength(image) as filesize
from temp_covers
where movie_id = 65;

-- 13. Create temporary BLOB, copy BFILE into it, update MOVIES for movie 65
-- Steps:
-- 1) read BFILE + MIME from TEMP_COVERS
-- 2) create temporary BLOB
-- 3) open file + loadfromfile + close
-- 4) update MOVIES (set cover + mime)
-- 5) free temporary LOB
-- 6) and commit
declare
v_mime varchar2(50);
    v_src  bfile;
    v_tmp  blob;
    v_size number;
begin
    -- get bfile + mime from temp table
select image, mime_type
into v_src, v_mime
from temp_covers
where movie_id = 65;

-- make temporary blob
dbms_lob.createtemporary(v_tmp, true);

    -- copy bytes from file
    dbms_lob.fileopen(v_src, dbms_lob.file_readonly);
    v_size := dbms_lob.getlength(v_src);

    dbms_lob.loadfromfile(v_tmp, v_src, v_size);
    dbms_lob.fileclose(v_src);

    -- update target row
update movies
set cover = v_tmp,
    mime_type = v_mime
where id = 65;

-- free temp lob (I don’t want to leak it)
dbms_lob.freetemporary(v_tmp);

commit;
end;

-- 14. Check cover sizes again (65 and 66)
select id as movie_id,
    dbms_lob.getlength(cover) as filesize
from movies
where id in (65, 66)
order by id;

-- 15. Drop MOVIES from my schema
drop table temp_covers purge;
drop table movies purge;
