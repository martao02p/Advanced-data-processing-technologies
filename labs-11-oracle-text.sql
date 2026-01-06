-- część 1 -> CYTATY

-- 1. kopia tabeli
create table cytaty as
select * from ztpd.cytaty;


-- 2. like: optymista + pesymista (bez case)
select autor, tekst
from cytaty
where lower(tekst) like '%optymista%'
  and lower(tekst) like '%pesymista%';


-- 3. context index na TEKST
create index cytaty_ctx on cytaty(tekst)
    indextype is ctxsys.context;


-- 4. contains: optymista AND pesymista
select autor, tekst
from cytaty
where contains(tekst, 'optymista AND pesymista', 1) > 0;


-- 5. contains: pesymista ale bez optymista
-- ja wolę NOT, ale minus też działa
select autor, tekst
from cytaty
where contains(tekst, 'pesymista NOT optymista', 1) > 0;
-- where contains(tekst, 'pesymista - optymista', 1) > 0;


-- 6. near do 3 słów
select autor, tekst
from cytaty
where contains(tekst, 'near((optymista, pesymista), 3)', 1) > 0;


-- 7. near do 10 słów
select autor, tekst
from cytaty
where contains(tekst, 'near((optymista, pesymista), 10)', 1) > 0;


-- 8. "życie" i odmiany -> polski nie ma stemmingu więc lecimy prefiksem życi%
select autor, tekst
from cytaty
where contains(tekst, 'życi%', 1) > 0;


-- 9. score do wyników z 8
select autor, tekst, score(1) as dopasowanie
from cytaty
where contains(tekst, 'życi%', 1) > 0;


-- 10. tylko najlepszy (po score)
-- ważne: najpierw order by, potem fetch (rownum czasem robi psikusa)
select autor, tekst, score(1) as dopasowanie
from cytaty
where contains(tekst, 'życi%', 1) > 0
order by score(1) desc
    fetch first 1 row only;


-- 11. literówka: probelm vs problem -> fuzzy
select autor, tekst
from cytaty
where contains(tekst, 'fuzzy(probelm)', 1) > 0;


-- 12. insert + commit (żeby mieć w tabeli)
insert into cytaty
values (
  3000,
  'Bertrand Russell',
  'To smutne, że głupcy są tacy pewni siebie, a ludzie rozsądni tacy pełni wątpliwości.'
);

commit;


-- 13. contains: "głupcy"
-- jak nie zwróci -> indeks context nie musi się sam odświeżyć po commit
select autor, tekst
from cytaty
where contains(tekst, 'głupcy', 1) > 0;


-- 14. tabela odwróconego indeksu -> DR$<nazwa_indeksu>$I
-- u mnie indeks to cytaty_ctx, więc tabela: DR$CYTATY_CTX$I
select token_text, token_type, token_count
from dr$cytaty_ctx$i
where lower(token_text) = 'głupcy';


-- 15. przebudowa indeksu (prosto: drop + create)
drop index cytaty_ctx;

create index cytaty_ctx on cytaty(tekst)
    indextype is ctxsys.context;


-- 16. po przebudowie: sprawdzić token + powtorzenie 13
select token_text
from dr$cytaty_ctx$i
where lower(token_text) = 'głupcy';

select autor, tekst
from cytaty
where contains(tekst, 'głupcy', 1) > 0;


-- 17. sprzątanie
drop index cytaty_ctx;
drop table cytaty;



-- część 2 -> QUOTES

-- 1. kopia tabeli
create table quotes as
select * from ztpd.quotes;


-- 2. context index na TEXT
create index quotes_ctx on quotes(text)
    indextype is ctxsys.context;


-- 3. stemming po ang -> testy (work / $work / working / $working)
select author, text from quotes where contains(text, 'work', 1) > 0;
select author, text from quotes where contains(text, '$work', 1) > 0;
select author, text from quotes where contains(text, 'working', 1) > 0;
select author, text from quotes where contains(text, '$working', 1) > 0;


-- 4. sprobowanie "it"
-- zwykle 0 wyników -> stopword w domyślnej stopliście
select author, text
from quotes
where contains(text, 'it', 1) > 0;


-- 5. stoplisty w systemie
select *
from ctx_stoplists;


-- 6. stopwords (domyślna stoplista jest zwykle DEFAULT_STOPLIST)
select *
from ctx_stopwords;


-- 7. usunięcie indeks i zrobienie na empty stoplist (żeby it nie było blokowane)
drop index quotes_ctx;

create index quotes_ctx on quotes(text)
    indextype is ctxsys.context
parameters ('stoplist CTXSYS.EMPTY_STOPLIST');


-- 8. ponowienie "it" -> powinno coś zwrócić
select author, text
from quotes
where contains(text, 'it', 1) > 0;


-- 9. fool + humans
select author, text
from quotes
where contains(text, 'fool AND humans', 1) > 0;


-- 10. fool + computer
select author, text
from quotes
where contains(text, 'fool AND computer', 1) > 0;


-- 11. fool + humans w jednym zdaniu
-- tutaj na tym etapie zwykle błąd -> brak sekcji SENTENCE
select author, text
from quotes
where contains(text, '(fool AND humans) within sentence', 1) > 0;


-- 12. usunięcie indeksu
drop index quotes_ctx;


-- 13. section group -> bazowo null + dodanie SENTENCE i PARAGRAPH
begin
  ctx_ddl.create_section_group('quotes_sg', 'NULL_SECTION_GROUP');
  ctx_ddl.add_special_section('quotes_sg', 'SENTENCE');
  ctx_ddl.add_special_section('quotes_sg', 'PARAGRAPH');
end;
/


-- 14. stworzenie indeks z section group (i nadal empty stoplist)
create index quotes_ctx on quotes(text)
    indextype is ctxsys.context
parameters ('stoplist CTXSYS.EMPTY_STOPLIST section group quotes_sg');


-- 15.
select author, text
from quotes
where contains(text, '(fool AND humans) within sentence', 1) > 0;

select author, text
from quotes
where contains(text, '(fool AND computer) within sentence', 1) > 0;


-- 16. humans (czy łapie non-humans?)
-- domyślnie '-' często rozcina słowo na tokeny, więc "humans" może znaleźć "non-humans"
select author, text
from quotes
where contains(text, 'humans', 1) > 0;


-- 17. lexer -> chcę, żeby '-' był częścią tokenu (printjoins = '-')
drop index quotes_ctx;

begin
  ctx_ddl.create_preference('quotes_lex', 'BASIC_LEXER');
  ctx_ddl.set_attribute('quotes_lex', 'printjoins', '-');
  ctx_ddl.set_attribute('quotes_lex', 'index_text', 'yes');
end;
/

create index quotes_ctx on quotes(text)
    indextype is ctxsys.context
parameters ('stoplist CTXSYS.EMPTY_STOPLIST section group quotes_sg lexer quotes_lex');


-- 18. humans po lexerze -> teraz non-humans raczej nie powinno wpadać
select author, text
from quotes
where contains(text, 'humans', 1) > 0;


-- 19. non-humans jako fraza (escape myślnika)
select author, text
from quotes
where contains(text, 'non\-humans', 1) > 0;


-- 20. sprzątanie
drop index quotes_ctx;
drop table quotes;

begin
  ctx_ddl.drop_section_group('quotes_sg');
  ctx_ddl.drop_preference('quotes_lex');
end;
/
