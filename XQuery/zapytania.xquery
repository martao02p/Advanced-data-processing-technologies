(: --- bib.xml --- :)

(: zad.5 -> same last names (authors) :)
for $l in doc("db/bib/bib.xml")//book/author/last
return $l


(: zad.6 -> make pairs (title, author) inside <ksiazka> :)
for $b in doc("db/bib/bib.xml")//book
for $t in $b/title
for $a in $b/author
return
  <ksiazka>
    <title>{ data($t) }</title>
    <author>{ $a }</author>
  </ksiazka>


(: zad.7 -> like before but polish tags + concat w/o space :)
for $b in doc("db/bib/bib.xml")//book
for $t in $b/title
for $a in $b/author
return
  <ksiazka>
    <autor>{ concat($a/last, $a/first) }</autor>
    <tytul>{ data($t) }</tytul>
  </ksiazka>


(: zad.8 -> ok add space between last + first :)
for $b in doc("db/bib/bib.xml")//book
for $t in $b/title
for $a in $b/author
return
  <ksiazka>
    <autor>{ $a/last || " " || $a/first }</autor>
    <tytul>{ data($t) }</tytul>
  </ksiazka>


(: zad.9 -> wrap result :)
<wynik>{
  for $b in doc("db/bib/bib.xml")//book
  for $t in $b/title
  for $a in $b/author
  return
    <ksiazka>
      <autor>{ $a/last || " " || $a/first }</autor>
      <tytul>{ data($t) }</tytul>
    </ksiazka>
}</wynik>


(: zad.10 -> first names for "Data on the Web" :)
<imiona>{
  for $f in doc("db/bib/bib.xml")//book[title="Data on the Web"]/author/first
  return <imie>{ data($f) }</imie>
}</imiona>


(: zad.11 -> whole <book> for title "Data on the Web" (2 ways) :)

(: 11a path way :)
(: <DataOnTheWeb>{ doc("db/bib/bib.xml")//book[title="Data on the Web"] }</DataOnTheWeb> :)

(: 11b where way :)
<DataOnTheWeb>{
  for $b in doc("db/bib/bib.xml")//book
  where $b/title = "Data on the Web"
  return $b
}</DataOnTheWeb>


(: zad.12 -> last names where title contains "Data" :)
<Data>{
  for $a in doc("db/bib/bib.xml")//book[contains(title, "Data")]/author
  return <nazwisko>{ data($a/last) }</nazwisko>
}</Data>


(: zad.13 -> title + authors (for books w "Data") :)
for $b in doc("db/bib/bib.xml")//book[contains(title, "Data")]
return
  <Data>
    <title>{ data($b/title) }</title>
    {
      for $a in $b/author
      return <nazwisko>{ data($a/last) }</nazwisko>
    }
  </Data>


(: zad.14 -> titles with <= 2 authors :)
for $b in doc("db/bib/bib.xml")//book
where count($b/author) <= 2
return $b/title


(: zad.15 -> title + number of authors :)
for $b in doc("db/bib/bib.xml")//book
return
  <ksiazka>
    { $b/title }
    <autorow>{ count($b/author) }</autorow>
  </ksiazka>


(: zad.16 -> year range :)
let $years := doc("db/bib/bib.xml")//book/@year ! xs:integer(.)
return <przedział>{ min($years) || " - " || max($years) }</przedział>


(: zad.17 -> max-min price
   (remember: prices are strings in xml so i cast to decimal, otherwise it can compare weird) :)
let $p := doc("db/bib/bib.xml")//book/price ! xs:decimal(.)
return <różnica>{ max($p) - min($p) }</różnica>


(: zad.18 -> cheapest books + authors if any
   (do min once, then filter) :)
let $minP := min(doc("db/bib/bib.xml")//book/price ! xs:decimal(.))
return
  <najtańsze>{
    for $b in doc("db/bib/bib.xml")//book[xs:decimal(price) = $minP]
    return
      <najtańsza>
        { $b/title }
        { $b/author }
      </najtańsza>
  }</najtańsze>


(: zad.19 -> for each last name show titles
   (assumption from task: last name unique, so distinct-values is enough) :)
for $ln in distinct-values(doc("db/bib/bib.xml")//author/last ! data(.))
order by $ln
return
  <autor>
    <last>{ $ln }</last>
    {
      for $b in doc("db/bib/bib.xml")//book[author/last = $ln]
      return <title>{ data($b/title) }</title>
    }
  </autor>



(: --- shakespeare collection --- :)

(: zad.20 -> all play titles :)
<wynik>{
  for $p in collection("db/shakespeare")//PLAY
  return <TITLE>{ data($p/TITLE) }</TITLE>
}</wynik>


(: zad.21 -> titles where any LINE has "or not to be"
   (contains is case sensitive, leaving it like that) :)
for $p in collection("db/shakespeare")//PLAY
where some $l in $p//LINE satisfies contains(string($l), "or not to be")
return <TITLE>{ data($p/TITLE) }</TITLE>


(: zad.22 -> stats per play :)
<wynik>{
  for $p in collection("db/shakespeare")//PLAY
  let $t := data($p/TITLE)
  let $chars := count($p//PERSONA)
  let $acts := count($p//ACT)
  let $sc := count($p//SCENE)
  return
    <sztuka tytul="{$t}">
      <postaci>{ $chars }</postaci>
      <aktow>{ $acts }</aktow>
      <scen>{ $sc }</scen>
    </sztuka>
}</wynik>
