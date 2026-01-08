-- A. Table FIGURY (ID + KSZTALT)
create table figury (
    id number(1) primary key,
    ksztalt mdsys.sdo_geometry
);

-- desc figury;
-- select * from figury;

-- B. Insert 3 shapes (no SRID -> cartesian)
-- 1) circle-like polygon element (3 points define arc)
insert into figury values (
  1,
  mdsys.sdo_geometry(
          2003, -- 2D polygon
          null, -- SRID = NULL (cartesian)
          null,
          mdsys.sdo_elem_info_array(1, 1003, 4),  -- 4 = circle/arc defined by 3 points
          mdsys.sdo_ordinate_array(5,7,  7,5,  3,5)
  )
);

-- 2) rectangle
insert into figury values (
  2,
  mdsys.sdo_geometry(
          2003,
          null,
          null,
          mdsys.sdo_elem_info_array(1, 1003, 3),  -- 3 = rectangle by two corners
          mdsys.sdo_ordinate_array(1,1,  5,5)
  )
);

-- 3)
insert into figury values (
  3,
  mdsys.sdo_geometry(
          2002, -- 2D line
          null,
          null,
          mdsys.sdo_elem_info_array(1, 2, 1), -- 2 = line string, 1 = straight segments
          mdsys.sdo_ordinate_array(3,2,  6,2,  7,3,  8,2,  7,1)
  )
);

select id, ksztalt from figury order by id;

-- C. Insert one invalid geometry

insert into figury values (
  4,
  mdsys.sdo_geometry(
          2003,
          null,
          null,
          mdsys.sdo_elem_info_array(1, 1003, 4),
          mdsys.sdo_ordinate_array(1,8,  2,8,  3,8) -- collinear points -> bad circle
  )
);

-- D. Validate geometries (TRUE or error code)
-- tolerance - 0.01 is fine for this simple cartesian example
select id,
       sdo_geom.validate_geometry_with_context(ksztalt, 0.01) as val
from figury
order by id;

-- E. Delete invalid rows
delete from figury
where sdo_geom.validate_geometry_with_context(ksztalt, 0.01) <> 'TRUE';

-- after delete
select id,
       sdo_geom.validate_geometry_with_context(ksztalt, 0.01) as val
from figury
order by id;

select * from figury order by id;

-- F.
commit;
