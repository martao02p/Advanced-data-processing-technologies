-- 1. Object type SAMOCHOD + object table SAMOCHODY + sample data
-- basic object type (no methods yet)
create or replace type samochod as object (
    marka           varchar2(20),
    model           varchar2(20),
    kilometry       number,
    data_produkcji  date,
    cena            number(10,2)
);

-- object table
create table samochody of samochod;

-- sample inserts
insert into samochody values (samochod('FIAT', 'BRAVA', 60000, date '1999-11-30', 25000));
insert into samochody values (samochod('FORD', 'MONDEO',80000, date '1997-05-10', 45000));
insert into samochody values (samochod('MAZDA', '323', 12000, date '2000-09-22', 52000));

select * from samochody;

-- 2. Relational table WLASCICIELE with an object attribute (AUTO SAMOCHOD)
create table wlasciciele (
    imie        varchar2(100),
    nazwisko    varchar2(100),
    auto        samochod
);

insert into wlasciciele values
    ('JAN','KOWALSKI', samochod('FIAT', 'SEICENTO', 30000, date '2010-12-02', 19500));

insert into wlasciciele values
    ('ADAM', 'NOWAK',samochod('OPEL', 'ASTRA',34000, date '2009-06-01', 33700));

select * from wlasciciele;

-- 3. Add method WARTOSC(): price drops 10% each year (based on age)
-- easiest: replace type definition (keeps existing tables via CASCADE)
alter type samochod replace as object (
    marka           varchar2(20),
    model           varchar2(20),
    kilometry       number,
    data_produkcji  date,
    cena            number(10,2),

    -- current value = cena * 0.9^(years)
    member function wartosc return number
    ) cascade including table data;

create or replace type body samochod as
    member function wartosc return number is
        v_lata number;
begin
        -- I prefer months_between -> more real than only year difference
        v_lata := floor(months_between(sysdate, data_produkcji) / 12);
return round(cena * power(0.9, v_lata), 2);
end wartosc;
end;

select s.marka, s.cena, s.wartosc() as aktualna_wartosc
from samochody s;

-- 4. Add MAP method for sorting (age + wear); 10k km = 1 "year"
alter type samochod add map member function porownaj return number
    cascade including table data;

create or replace type body samochod as
    member function wartosc return number is
        v_lata number;
begin
        v_lata := floor(months_between(sysdate, data_produkcji) / 12);
return round(cena * power(0.9, v_lata), 2);
end wartosc;

    -- mapping: smaller = "better/newer"
    map member function porownaj return number is
        v_lata number;
begin
        v_lata := floor(months_between(sysdate, data_produkcji) / 12);
return v_lata + (kilometry / 10000);
end porownaj;
end;

-- order by VALUE(s) uses MAP method
select * from samochody s
order by value(s);

-- 5. Drop table WLASCICIELE (relational one)

drop table wlasciciele purge;

-- 6. Create object type WLASCICIEL + object table WLASCICIELE + sample data
create or replace type wlasciciel as object (
    imie        varchar2(100),
    nazwisko    varchar2(100)
);

create table wlasciciele of wlasciciel;

insert into wlasciciele values (wlasciciel('JAN',   'KOWALSKI'));
insert into wlasciciele values (wlasciciel('ADAM',  'NOWAK'));
insert into wlasciciele values (wlasciciel('OLA',   'ZIELINSKA'));

select * from wlasciciele;

-- 7. Add REF to owner in SAMOCHOD
alter type samochod add attribute wlasciciel_ref ref wlasciciel
    cascade including table data;

-- 8. Delete all objects from SAMOCHODY
delete from samochody;
commit;

-- 9. Restrict REF scope in SAMOCHODY to only WLASCICIELE objects
alter table samochody add scope for (wlasciciel_ref) is wlasciciele;

-- 10. Insert cars again + connect them with existing owners (REF)
insert into samochody values (
samochod('FIAT', 'BRAVA', 60000, date '1999-11-30', 25000,
      (select ref(w) from wlasciciele w where w.nazwisko = 'KOWALSKI')));

insert into samochody values (
samochod('FORD', 'MONDEO', 80000, date '1997-05-10', 45000,
      (select ref(w) from wlasciciele w where w.nazwisko = 'NOWAK')));

insert into samochody values (
samochod('MAZDA', '323',12000, date '2000-09-22', 52000,
    (select ref(w) from wlasciciele w where w.nazwisko = 'ZIELINSKA')));
commit;

-- show cars with owner (DEREF)
select
    s.marka,
    s.model,
    s.kilometry,
    s.data_produkcji,
    s.cena,
    deref(s.wlasciciel_ref) as wlasciciel
from samochody s;

-- 11. VARRAY: collection of "subjects" (basic operations)
set serveroutput on;

declare
type t_przedmioty is varray(10) of varchar2(30);
    moje_przedmioty t_przedmioty := t_przedmioty();
begin
    -- add first element
    moje_przedmioty.extend;
    moje_przedmioty(1) := 'MATH (sadly)';

    -- fill more
    moje_przedmioty.extend(4);
    moje_przedmioty(2) := 'DATABASES';
    moje_przedmioty(3) := 'NETWORKS';
    moje_przedmioty(4) := 'OS';
    moje_przedmioty(5) := 'AI (maybe)';

    dbms_output.put_line('--- before trim ---');
for i in moje_przedmioty.first .. moje_przedmioty.last loop
        dbms_output.put_line(moje_przedmioty(i));
end loop;

    -- remove last two
    moje_przedmioty.trim(2);

    dbms_output.put_line('--- after trim(2) ---');
for i in moje_przedmioty.first .. moje_przedmioty.last loop
        dbms_output.put_line(moje_przedmioty(i));
end loop;

    dbms_output.put_line('Limit = ' || moje_przedmioty.limit);
    dbms_output.put_line('Count = ' || moje_przedmioty.count);
end;

-- 12. VARRAY: list of book titles (extend / delete-ish / insert new)

declare
type t_ksiazki is varray(10) of varchar2(60);
    moje_ksiazki t_ksiazki := t_ksiazki();
begin
    moje_ksiazki.extend(4);
    moje_ksiazki(1) := 'Dune';
    moje_ksiazki(2) := 'Hobbit';
    moje_ksiazki(3) := 'Clean Code';
    moje_ksiazki(4) := 'Some Random PDF';

    dbms_output.put_line('--- initial books ---');
for i in moje_ksiazki.first .. moje_ksiazki.last loop
        dbms_output.put_line(i || ': ' || moje_ksiazki(i));
end loop;

    -- remove book 2 in varray style (overwrite with something)
    moje_ksiazki(2) := '[removed]';

    -- add new book at the end
    moje_ksiazki.extend;
    moje_ksiazki(moje_ksiazki.last) := 'New Book (late submission)';

    dbms_output.put_line('--- after changes ---');
for i in moje_ksiazki.first .. moje_ksiazki.last loop
        dbms_output.put_line(i || ': ' || moje_ksiazki(i));
end loop;
end;

-- 13. Nested table: lecturers (extend / trim / delete range / insert back)
declare
type t_wykladowcy is table of varchar2(40);
    moi t_wykladowcy := t_wykladowcy();
begin
    moi.extend(5);
    moi(1) := 'MORZY';
    moi(2) := 'WOJCIECHOWSKI';
    moi(3) := 'WYKLADOWCA_3';
    moi(4) := 'WYKLADOWCA_4';
    moi(5) := 'WYKLADOWCA_5';

    dbms_output.put_line('--- start ---');
for i in moi.first .. moi.last loop
        dbms_output.put_line(moi(i));
end loop;

    -- delete some in the middle
    moi.delete(3,4);

    dbms_output.put_line('--- after delete(3,4) ---');
for i in moi.first .. moi.last loop
        if moi.exists(i) then
            dbms_output.put_line(i || ': ' || moi(i));
end if;
end loop;

    moi(3) := 'ZAKRZEWICZ';
    moi(4) := 'KROLIKOWSKI';

    dbms_output.put_line('--- after insert back ---');
for i in moi.first .. moi.last loop
        if moi.exists(i) then
            dbms_output.put_line(i || ': ' || moi(i));
end if;
end loop;

    dbms_output.put_line('Count = ' || moi.count);
end;

-- 14. Nested table: months list (insert, delete a few, display)

declare
type t_miesiace is table of varchar2(20);
    mies t_miesiace := t_miesiace();
begin
    mies.extend(12);
    mies(1) := 'JANUARY';
    mies(2) := 'FEBRUARY';
    mies(3) := 'MARCH';
    mies(4) := 'APRIL';
    mies(5) := 'MAY';
    mies(6) := 'JUNE';
    mies(7) := 'JULY';
    mies(8) := 'AUGUST';
    mies(9) := 'SEPTEMBER';
    mies(10) := 'OCTOBER';
    mies(11) := 'NOVEMBER';
    mies(12) := 'DECEMBER';

    dbms_output.put_line('--- all months ---');
for i in mies.first .. mies.last loop
        dbms_output.put_line(mies(i));
end loop;

    -- delete "a couple months"
    mies.delete(2);
    mies.delete(11);

    dbms_output.put_line('--- after delete Feb + Nov ---');
for i in mies.first .. mies.last loop
        if mies.exists(i) then
            dbms_output.put_line(i || ': ' || mies(i));
end if;
end loop;
end;

-- 15. Collections as DB attributes: VARRAY + nested table attribute
-- varray attribute
create type jezyki_obce as varray(10) of varchar2(20);

create type stypendium as object (
    nazwa   varchar2(50),
    kraj    varchar2(30),
    jezyki  jezyki_obce
);

create table stypendia of stypendium;

insert into stypendia values
    (stypendium('SOKRATES', 'FRANCE', jezyki_obce('ENGLISH','FRENCH','GERMAN')));

insert into stypendia values
    (stypendium('ERASMUS', 'GERMANY', jezyki_obce('ENGLISH','GERMAN','SPANISH')));

select * from stypendia;
select s.jezyki from stypendia s;

update stypendia
set jezyki = jezyki_obce('ENGLISH','GERMAN','SPANISH','FRENCH')
where nazwa = 'ERASMUS';

-- nested table attribute
create type lista_egzaminow as table of varchar2(30);

create type semestr as object (
    numer   number,
    egzaminy lista_egzaminow
);

create table semestry of semestr
    nested table egzaminy store as tab_egzaminy;

insert into semestry values (semestr(1, lista_egzaminow('MATH','LOGIC','ALGEBRA')));
insert into semestry values (semestr(2, lista_egzaminow('DATABASES','OS')));

-- read nested table with TABLE()
select s.numer, e.column_value as egzamin
from semestry s, table(s.egzaminy) e;

-- add new exam to semester 2
insert into table (select s.egzaminy from semestry s where numer = 2)
    values ('NUMERICAL METHODS');

-- update one exam name in semester 2
update table (select s.egzaminy from semestry s where numer = 2) e
set e.column_value = 'DISTRIBUTED SYSTEMS'
where e.column_value = 'OS';

-- delete an exam from semester 2
delete from table (select s.egzaminy from semestry s where numer = 2) e
where e.column_value = 'DATABASES';

-- 16. ZAKUPY with nested table attribute + delete purchases containing a product
create type koszyk_produktow as table of varchar2(30);

create type zakup as object (
    id      number,
    koszyk  koszyk_produktow
);

create table zakupy of zakup
    nested table koszyk store as tab_koszyk;

insert into zakupy values (zakup(1, koszyk_produktow('MILK','BREAD','BUTTER')));
insert into zakupy values (zakup(2, koszyk_produktow('WATER','BREAD')));
insert into zakupy values (zakup(3, koszyk_produktow('CHEESE')));
insert into zakupy values (zakup(4, koszyk_produktow('BREAD','CHEESE')));

-- show full content (purchase + each product row)
select z.id, p.column_value as produkt
from zakupy z, table(z.koszyk) p
order by z.id;

-- delete all purchases that contain chosen product (example: CHEESE)
delete from zakupy z
where exists (
    select 1
    from table(z.koszyk) p
    where p.column_value = 'CHEESE'
);

select * from zakupy;

-- 17. Instruments hierarchy (inheritance + overriding + overloading)
create type instrument as object (
    nazwa   varchar2(20),
    dzwiek  varchar2(20),
    member function graj return varchar2
) not final;

create type body instrument as
    member function graj return varchar2 is
begin
return dzwiek;
end;
end;

create type instrument_dety under instrument (
    material varchar2(20),
    overriding member function graj return varchar2,
    member function graj(glosnosc varchar2) return varchar2
);

create type body instrument_dety as
    overriding member function graj return varchar2 is
begin
return 'blowing: ' || dzwiek;
end;

    member function graj(glosnosc varchar2) return varchar2 is
begin
return glosnosc || ': ' || dzwiek;
end;
end;

create type instrument_klawiszowy under instrument (
    producent varchar2(20),
    overriding member function graj return varchar2
);

create type body instrument_klawiszowy as
    overriding member function graj return varchar2 is
begin
return 'keys go brr: ' || dzwiek;
end;
end;

declare
tamburyn  instrument := instrument('tambourine', 'jingle-jingle');
    trabka    instrument_dety := instrument_dety('trumpet', 'tra-ta-ta', 'metal');
    fortepian instrument_klawiszowy := instrument_klawiszowy('piano', 'ping-ping', 'steinway');
begin
    dbms_output.put_line(tamburyn.graj);
    dbms_output.put_line(trabka.graj);
    dbms_output.put_line(trabka.graj('LOUD'));
    dbms_output.put_line(fortepian.graj);
end;
/

-- 18. Animals hierarchy + abstract class test
create type istota as object (
    nazwa varchar2(20),
    not instantiable member function poluj(ofiara varchar2) return varchar2
) not instantiable not final;

create type lew under istota (
    liczba_nog number,
    overriding member function poluj(ofiara varchar2) return varchar2
);

create type body lew as
    overriding member function poluj(ofiara varchar2) return varchar2 is
begin
return 'caught prey: ' || ofiara;
end;
end;

declare
krol_lew lew := lew('LION', 4);
begin
    dbms_output.put_line(krol_lew.poluj('antelope'));
    -- below would fail, because ISTOTA is abstract:
    -- declare x istota := istota('SOMETHING'); begin null; end;

-- 19. Polymorphism test on instruments
declare
a instrument;
    b instrument;
    t instrument_dety;
begin
    a := instrument('tambourine', 'jingle');
    b := instrument_dety('bells', 'ding-ding', 'metal'); -
    t := instrument_dety('trumpet', 'tra-ta-ta', 'metal');

    dbms_output.put_line(a.graj);
    dbms_output.put_line(b.graj);
    dbms_output.put_line(t.graj('soft'));
end;

-- 20. Table of instruments + virtual method behavior

create table instrumenty of instrument;

insert into instrumenty values (instrument('tambourine','jingle-jingle'));
insert into instrumenty values (instrument_dety('trumpet','tra-ta-ta','metal'));
insert into instrumenty values (instrument_klawiszowy('piano','ping-ping','steinway'));

-- virtual call (polymorphic)
select i.nazwa, i.graj() as co_slychac
from instrumenty i;
