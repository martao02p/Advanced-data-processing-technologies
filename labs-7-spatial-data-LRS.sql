set serveroutput on;

-- EX 1 - podstawy

-- 1A) tabela S6_LRS (jedna kolumna GEOM)
begin execute immediate 'drop table s6_lrs purge'; exception when others then null; end;

create table s6_lrs (
    geom mdsys.sdo_geometry
);

desc s6_lrs;

-- 1B) skopiuj odcinek z STREETS_AND_RAILROADS w odległości <= 10 km od Koszalina
-- (bierzemy 1 obiekt, żeby było "1 row inserted")
insert into s6_lrs(geom)
select sr.geom
from streets_and_railroads sr
where sdo_relate(
    sr.geom,
    sdo_geom.sdo_buffer(
          (select geom from major_cities where city_name = 'Koszalin'),
          10, 1, 'unit=km'
    ),
    'mask=anyinteract'
) = 'TRUE'
fetch first 1 row only;

select * from s6_lrs;

-- 1C) długość + liczba punktów
select  sdo_geom.sdo_length(geom, 1, 'unit=km') as distance,
    st_linestring(geom).st_numpoints()      as st_numpoints
from s6_lrs;

-- 1D) konwersja do LRS: miary M od 0 do długości odcinka
update s6_lrs
set geom = sdo_lrs.convert_to_lrs_geom(
    geom,
    0,
    sdo_geom.sdo_length(geom, 1, 'unit=km')
);

-- 1E) metadane (X,Y + wymiar M)
-- (zakresy X/Y/M są "bezpieczne" dla środkowej Europy + M ~ do 300 km)
delete from user_sdo_geom_metadata where table_name = 'S6_LRS';

insert into user_sdo_geom_metadata
values (
'S6_LRS',
'GEOM',
mdsys.sdo_dim_array(
    mdsys.sdo_dim_element('X', 12.0, 26.5, 1),
    mdsys.sdo_dim_element('Y', 45.5, 58.5, 1),
    mdsys.sdo_dim_element('M', 0, 300, 1)
),
8307
);

select * from user_sdo_geom_metadata where table_name = 'S6_LRS';

-- 1F) indeks przestrzenny
begin execute immediate 'drop index s6_lrs_idx'; exception when others then null; end;

create index s6_lrs_idx
    on s6_lrs(geom)
    indextype is mdsys.spatial_index_v2;


-- EX 2 - przetwarzanie LRS

-- 2A) czy miara 500 jest prawidłowa?
select sdo_lrs.valid_measure(geom, 500) as valid_500
from s6_lrs;

-- 2B) punkt końcowy segmentu LRS
select sdo_lrs.geom_segment_end_pt(geom) as end_pt
from s6_lrs;

-- 2C) punkt na 150. kilometrze trasy
select sdo_lrs.locate_pt(geom, 150, 0) as km150
from s6_lrs;

-- 2D) fragment linii od 120 do 160 km
select sdo_lrs.clip_geom_segment(geom, 120, 160) as clipped
from s6_lrs;

-- 2E) "wjazd" najbliższy od Słupska jadąc w stronę Szczecina
-- (bierzemy "następny punkt kształtu" względem punktu Słupska)
select sdo_lrs.get_next_shape_pt(s6.geom, mc.geom) as wjazd_na_s6
from s6_lrs s6, major_cities mc
where mc.city_name = 'Slupsk';

-- 2F) Gazociąg 50 m na lewo od trasy, od km 50 do km 200:
-- koszt = długość (km) * 1 mln/km => tu zwracamy długość w km jako "koszt"
select sdo_geom.sdo_length(
sdo_lrs.offset_geom_segment(
   s6.geom,
   m.diminfo,
   50,    -- start measure
   200,   -- end measure
   50,    -- offset (metry)
   'unit=m arc_tolerance=1'
),
1,
'unit=km'
) as koszt
from s6_lrs s6, user_sdo_geom_metadata m
where m.table_name  = 'S6_LRS'
  and m.column_name = 'GEOM';
