(:XQuery swiat.xml:)
(:for $k in doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/swiat.xml')//KRAJ:)
(:doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/swiat.xml')/SWIAT/KRAJE/KRAJ:)
(:where starts-with($k/NAZWA, 'A'):)
(:where substring($k/NAZWA, 1, 1) = substring($k/STOLICA, 1, 1):)
(:return <KRAJ>:)
(:  {$k/NAZWA, $k/STOLICA}:)
(:</KRAJ>:)

(:XPath zesp_prac.xml:)
(:NAZWISKO:)
(:doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/zesp_prac.xml')//PRACOWNICY/ROW/NAZWISKO:)

(:SYSTEMY EKSPERCKIE:)
(:doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/zesp_prac.xml')/ZESPOLY/ROW[NAZWA='SYSTEMY EKSPERCKIE']/PRACOWNICY/ROW/NAZWISKO:)

(:ID=10:)
(:count(doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/zesp_prac.xml'):)
(:  /ZESPOLY/ROW[ID_ZESP=10]/PRACOWNICY/ROW ):)

(:SZEF ID=100:)
(:doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/zesp_prac.xml')//PRACOWNICY/ROW[ID_SZEFA=100]/NAZWISKO:)

(:SUMA PŁAC:)
sum(
  doc('C:/Users/marta/Desktop/MAGISTERKA/SEMESTR-2/ZTPD/XML/XPath-XSLT/zesp_prac.xml')
  //PRACOWNICY/ROW[ID_ZESP = //PRACOWNICY/ROW[NAZWISKO='BRZEZINSKI']/ID_ZESP]/PLACA_POD
)


