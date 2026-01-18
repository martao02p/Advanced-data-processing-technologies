-- EX 1 - SQL/MM basics
-- 1A) Hierarchia typu ST_GEOMETRY (CONNECT BY)
select lpad('-',2*(level-1),'|-') ||
    t.owner||'.'||t.type_name||
    ' (FINAL:'||t.final||
    ', INSTANTIABLE:'||t.instantiable||
    ', ATTRIBUTES:'||t.attributes||
    ', METHODS:'||t.methods||')' as tree
from all_types t
    start with t.type_name = 'ST_GEOMETRY'
connect by prior t.type_name = t.supertype_name
       and prior t.owner = t.owner;

-- 1B) Metody typu ST_POLYGON
select distinct m.method_name
from all_type_methods m
where m.type_name = 'ST_POLYGON'
  and m.owner = 'MDSYS'
order by 1;

-- 1C) Tabela MYST_MAJOR_CITIES
begin execute immediate 'drop table myst_major_cities purge'; exception when others then null; end;

create table myst_major_cities (
   fips_cntry varchar2(2),
   city_name  varchar2(40),
   stgeom     st_point
);

desc myst_major_cities;

-- 1D) Przepisanie MAJOR_CITIES -> MYST_MAJOR_CITIES (konwersja SDO -> ST)
insert into myst_major_cities (fips_cntry, city_name, stgeom)
select mc.fips_cntry,
       mc.city_name,
       st_point(mc.geom)   -- prosto: konstruktor ST_POINT z SDO_GEOMETRY
from major_cities mc;

select * from myst_major_cities where rownum <= 5;


-- EX 2 - definicja geometrii (Szczyrk)

-- 2A) Szczyrk jako ST_POINT(x,y,srid)
-- ważne: SRID taki jak reszta danych -> najczęściej 8307
insert into myst_major_cities
values ('PL', 'Szczyrk', st_point(19.036107, 49.718655, 8307));

select * from myst_major_cities where city_name = 'Szczyrk';


-- EX 3 - granice państw w SQL/MM
-- 3A) Tabela MYST_COUNTRY_BOUNDARIES
begin execute immediate 'drop table myst_country_boundaries purge'; exception when others then null; end;

create table myst_country_boundaries (
    fips_cntry varchar2(2),
    cntry_name varchar2(40),
    stgeom     st_multipolygon
);

desc myst_country_boundaries;

-- 3B) Przepisanie COUNTRY_BOUNDARIES -> MYST_COUNTRY_BOUNDARIES (SDO -> ST)
insert into myst_country_boundaries (fips_cntry, cntry_name, stgeom)
select cb.fips_cntry,
       cb.cntry_name,
       st_multipolygon(cb.geom)
from country_boundaries cb;

-- 3C) Typ obiektu + ile sztuk
select b.stgeom.st_geometrytype() as typ_obiektu,
       count(*)                  as ile
from myst_country_boundaries b
group by b.stgeom.st_geometrytype()
order by 2 desc;

-- 3D) Czy geometrie są proste (1 = TRUE)
select b.cntry_name,
       b.stgeom.st_issimple() as is_simple
from myst_country_boundaries b
order by b.cntry_name;


-- EX 4 - przetwarzanie (ST_CONTAINS, ST_TOUCHES, ST_INTERSECTS, UNION, DIFFERENCE)

-- 4A) Ile miast w każdym państwie (contains)
-- jak ORA-13295 -> znaczy że jakieś miasto ma inny SRID (np. Szczyrk).
select cb.cntry_name,
       count(*) as ile_miast
from myst_country_boundaries cb,
     myst_major_cities mc
where cb.stgeom.st_contains(mc.stgeom) = 1
group by cb.cntry_name
order by ile_miast desc;

-- 4B) Państwa graniczące z Czechami (touches)
select a.cntry_name as a_name,
       b.cntry_name as b_name
from myst_country_boundaries a,
     myst_country_boundaries b
where a.stgeom.st_touches(b.stgeom) = 1
  and b.cntry_name = 'Czech Republic'
order by a_name;

-- 4C) Rzeki przecinające granicę Czech
-- rivers.geom jest SDO_GEOMETRY -> trzeba go "opakować" do ST_LINESTRING(...)
select distinct cb.cntry_name,
                r.name
from myst_country_boundaries cb,
     rivers r
where cb.cntry_name = 'Czech Republic'
  and cb.stgeom.st_intersects(st_linestring(r.geom)) = 1
order by r.name;

-- 4D) Powierzchnia Czech + Słowacja jako jeden obiekt
-- union zwraca raczej kolekcję/polygon -> treat i area
select treat(cz.stgeom.st_union(sk.stgeom) as st_polygon).st_area() as powierzchnia
from myst_country_boundaries cz,
     myst_country_boundaries sk
where cz.cntry_name = 'Czech Republic'
  and sk.cntry_name = 'Slovakia';

-- 4E) Węgry z "wykrojonym" Balatonem + typ wyniku
select h.stgeom.st_difference(st_geometry(wb.geom)).st_geometrytype() as wegry_bez
from myst_country_boundaries h,
     water_bodies wb
where h.cntry_name = 'Hungary'
  and wb.name = 'Balaton';


-- EX 5 - SDO_WITHIN_DISTANCE + metadata + index + plan

-- 5A) Ile miejscowości jest <=100 km od terytorium Polski
-- (tu celowo operator SDO_* bo tak jest w zadaniu)
explain plan for
select cb.cntry_name as a_name,
       count(*)      as ile
from myst_country_boundaries cb,
     myst_major_cities mc
where cb.cntry_name = 'Poland'
  and sdo_within_distance(mc.stgeom, cb.stgeom, 'distance=100 unit=km') = 'TRUE'
group by cb.cntry_name;

select plan_table_output from table(dbms_xplan.display);

-- 5B) Metadata (najprościej kopiujemy z ALL_SDO_GEOM_METADATA oryginalnych tabel)
-- (jak rerun -> usuń stare wpisy)
delete from user_sdo_geom_metadata where table_name in ('MYST_MAJOR_CITIES','MYST_COUNTRY_BOUNDARIES');

insert into user_sdo_geom_metadata
select 'MYST_MAJOR_CITIES', 'STGEOM', diminfo, srid
from all_sdo_geom_metadata
where table_name = 'MAJOR_CITIES' and column_name = 'GEOM';

insert into user_sdo_geom_metadata
select 'MYST_COUNTRY_BOUNDARIES', 'STGEOM', diminfo, srid
from all_sdo_geom_metadata
where table_name = 'COUNTRY_BOUNDARIES' and column_name = 'GEOM';

select * from user_sdo_geom_metadata
where table_name in ('MYST_MAJOR_CITIES','MYST_COUNTRY_BOUNDARIES');

-- 5C) Indeksy R-tree (spatial)
begin execute immediate 'drop index myst_major_cities_idx'; exception when others then null; end;
begin execute immediate 'drop index myst_country_boundaries_idx'; exception when others then null; end;

create index myst_major_cities_idx
    on myst_major_cities(stgeom)
    indextype is mdsys.spatial_index_v2;

create index myst_country_boundaries_idx
    on myst_country_boundaries(stgeom)
    indextype is mdsys.spatial_index_v2;

-- 5D) Ponownie zapytanie + plan (powinien pojawić się DOMAIN INDEX)
explain plan for
select cb.cntry_name as a_name,
       count(*)      as ile
from myst_country_boundaries cb,
     myst_major_cities mc
where cb.cntry_name = 'Poland'
  and sdo_within_distance(mc.stgeom, cb.stgeom, 'distance=100 unit=km') = 'TRUE'
group by cb.cntry_name;

select plan_table_output from table(dbms_xplan.display);
