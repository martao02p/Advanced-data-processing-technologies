-- A) Register layer in metadata (tolerance = 0.01)
-- if rerun -> remove previous metadata row first
delete from user_sdo_geom_metadata
where table_name = 'FIGURY' and column_name = 'KSZTALT';

insert into user_sdo_geom_metadata values (
    'FIGURY',
    'KSZTALT',
    mdsys.sdo_dim_array(
          mdsys.sdo_dim_element('X', 0, 10, 0.01),
          mdsys.sdo_dim_element('Y', 0, 10, 0.01)
    ),
    null
);

select * from user_sdo_geom_metadata where table_name = 'FIGURY';

-- B) Estimate R-tree index size (expected ~240)
select sdo_tune.estimate_rtree_index_size(3000000, 8192, 10, 2, 0) as est
from dual;

-- C) Create spatial index (R-tree)
-- if rerun -> drop index first
begin execute immediate 'drop index figury_spatial_idx';
exception when others then null;
end;

create index figury_spatial_idx
    on figury(ksztalt)
    indextype is mdsys.spatial_index_v2;

-- D) SDO_FILTER vs point (3,3) -> returns candidates (MBR check, can be "too many")
select id
from figury
where sdo_filter(
              ksztalt,
              mdsys.sdo_geometry(2001, null, mdsys.sdo_point_type(3,3,null), null, null)
      ) = 'TRUE';

-- E) SDO_RELATE with mask=ANYINTERACT -> exact geometry relation (real answer)
select id
from figury
where sdo_relate(
              ksztalt,
              mdsys.sdo_geometry(2001, null, mdsys.sdo_point_type(3,3,null), null, null),
              'mask=ANYINTERACT'
      ) = 'TRUE';

-- why different?:
-- SDO_FILTER = only first phase (bbox/MBR) -> candidates
-- SDO_RELATE = second phase (exact geometry) -> real result


-- 2A) 9 nearest cities from Warsaw (with distances)
-- (I use sdo_num_res=9; if you want same as sample (9 rows) -> 9)
select mc.city_name as miasto,
       sdo_nn_distance(1) as odl
from major_cities mc,
     (select geom from major_cities where city_name = 'Warsaw') w
where mc.city_name <> 'Warsaw'
  and sdo_nn(mc.geom, w.geom, 'sdo_num_res=9 unit=km', 1) = 'TRUE'
order by odl;

-- 2B) Cities within 100 km from Warsaw
select mc.city_name as miasto
from major_cities mc,
     (select geom from major_cities where city_name = 'Warsaw') w
where mc.city_name <> 'Warsaw'
  and sdo_within_distance(mc.geom, w.geom, 'distance=100 unit=km') = 'TRUE'
order by mc.city_name;

-- 2C) Cities inside Slovakia (SDO_RELATE mask=INSIDE)
select cb.cntry_name as kraj,
       mc.city_name  as miasto
from country_boundaries cb,
     major_cities mc
where cb.cntry_name = 'Slovakia'
  and sdo_relate(mc.geom, cb.geom, 'mask=INSIDE') = 'TRUE'
order by miasto;

-- 2D) Distances between Poland and countries that do NOT border Poland
-- We filter out neighbors by ANYINTERACT (neighbors touch/interact -> TRUE).
-- For non-neighbors it is not TRUE -> then compute distance.
select cb.cntry_name as panstwo,
       sdo_geom.sdo_distance(cb.geom, pl.geom, 1, 'unit=km') as odl
from country_boundaries cb,
     (select geom from country_boundaries where cntry_name = 'Poland') pl
where cb.cntry_name <> 'Poland'
  and sdo_relate(cb.geom, pl.geom, 'mask=ANYINTERACT') <> 'TRUE'
order by odl;


-- EX 3: Geometry functions (intersection, area, mbr, union, centroid, length)

-- 3A) Neighbors of Poland + border length
-- touch => they share boundary; intersection gives border geometry; length gives km.
select cb.cntry_name as cntry_name,
sdo_geom.sdo_length(
    sdo_geom.sdo_intersection(cb.geom, pl.geom, 1),
    1,
    'unit=km'
) as odleglosc
from country_boundaries cb,
     (select geom from country_boundaries where cntry_name = 'Poland') pl
where cb.cntry_name <> 'Poland'
  and sdo_relate(cb.geom, pl.geom, 'mask=TOUCH') = 'TRUE'
order by odleglosc desc;

-- 3B) Country with biggest stored fragment (max area)
select cntry_name
from country_boundaries
order by sdo_geom.sdo_area(geom, 1, 'unit=SQ_KM') desc
    fetch first 1 row only;

-- 3C) Area of MBR that contains Warsaw + Lodz
-- union -> take both points, mbr -> rectangle, area -> sq km
select sdo_geom.sdo_area(
    sdo_geom.sdo_mbr(
           sdo_geom.sdo_union(w.geom, l.geom, 0.01)
    ),
    1,
    'unit=SQ_KM'
) as sq_km
from (select geom from major_cities where city_name = 'Warsaw') w,
     (select geom from major_cities where city_name = 'Lodz')   l;

-- 3D) Geometry type of union(Poland, Prague)
-- result should be 2004 (collection) in sample
select sdo_geom.sdo_union(pl.geom, pr.geom, 0.01).sdo_gtype as gtype
from (select geom from country_boundaries where cntry_name = 'Poland') pl,
     (select geom from major_cities       where city_name  = 'Prague') pr;

-- 3E) City closest to centroid of its own country
-- join by country name -> compute dist(city, centroid(country)), take min
select city_name, cntry_name
from (
 select mc.city_name,
mc.cntry_name,
sdo_geom.sdo_distance(
    mc.geom,
    sdo_geom.sdo_centroid(cb.geom, 1),
    1,
    'unit=km'
) as dist_km
 from major_cities mc
          join country_boundaries cb
               on cb.cntry_name = mc.cntry_name
 order by dist_km
 )
fetch first 1 row only;

-- 3F) Length of rivers flowing through Poland (only parts inside Poland)
-- intersect river with Poland geom, then length; sum by river name
select r.name,
sum(
   sdo_geom.sdo_length(
       sdo_geom.sdo_intersection(r.geom, pl.geom, 1),
       1,
       'unit=km'
   )
) as dlugosc
from rivers r,
     (select geom from country_boundaries where cntry_name = 'Poland') pl
where sdo_relate(r.geom, pl.geom, 'mask=ANYINTERACT') = 'TRUE'
group by r.name
order by dlugosc desc;
