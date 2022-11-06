SELECT * FROM Bandy;
SELECT * FROM Wrogowie;
SELECT * FROM Kocury;
SELECT * FROM Funkcje;
SELECT * FROM Wrogowie_kocurow;
--ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
--zad1
SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA" FROM Wrogowie_kocurow
WHERE EXTRACT(YEAR FROM data_incydentu)=2009; 

--zad2
SELECT imie, funkcja, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "Z NAMI OD" FROM Kocury
WHERE plec='D' AND w_stadku_od BETWEEN '2005-09-01' AND '2007-07-31';

--zad3
SELECT imie_wroga "WROG", gatunek, stopien_wrogosci FROM Wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;

--zad4
SELECT imie || ' zwany ' || pseudo || ' (fun. '|| funkcja ||') lowi myszki w bandzie ' ||nr_bandy||' od '|| TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "WSZYSTKO O KOCURACH"
FROM Kocury
WHERE plec='M'
ORDER BY w_stadku_od DESC, pseudo;

--zad5 
SELECT pseudo, REGEXP_REPLACE(REGEXP_REPLACE(pseudo,'A','#',1,1),'L','%',1,1) "Po wymianie A na # oraz L na %" FROM KOCURY
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';

--zad6
SELECT imie, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "W stadku", NVL(ROUND(przydzial_myszy/1.1),0) "Zjadal", TO_CHAR(ADD_MONTHS(w_stadku_od, 6),'YYYY-MM-DD') "Podwyzka", przydzial_myszy "Zjada" FROM Kocury
WHERE EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM w_stadku_od) > 13
        AND EXTRACT(MONTH FROM w_stadku_od) >= 3 AND EXTRACT(MONTH FROM w_stadku_od) <= 9;
        
--zad7
SELECT imie, NVL(przydzial_myszy*3,0) "MYSZY KWARTALNE", NVL(myszy_extra*3,0) "KWARTALNE DODATKI" FROM Kocury
WHERE przydzial_myszy > (2 * myszy_extra) OR przydzial_myszy >= 55;


--zad8
SELECT imie, 
    DECODE(SIGN((12 * (NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))) - 660),
          -1, 'Ponizej 660',
          0, 'Limit',
          12 * (NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))) "Zjada rocznie" 
FROM Kocury;

--zad9 
SELECT pseudo, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "W STADKU",
    CASE
        WHEN NEXT_DAY(LAST_DAY('2022-10-25')-7,3) >= '2022-10-25' THEN
            CASE
                WHEN (EXTRACT (DAY FROM w_stadku_od) <= 15)
                THEN TO_CHAR(NEXT_DAY(LAST_DAY('2022-10-25')-7, 3), 'YYYY-MM-DD')
                ELSE TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-25',1))-7, 3), 'YYYY-MM-DD')
            END
        ELSE TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-25',1))-7,3), 'YYYY-MM-DD')
    END "Wyplata"
FROM Kocury
ORDER BY w_stadku_od;


SELECT pseudo, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "W STADKU",
    CASE
        WHEN NEXT_DAY(LAST_DAY('2022-10-27')-7,3) >= '2022-10-27' THEN
            CASE
                WHEN (EXTRACT (DAY FROM w_stadku_od) <= 15)
                THEN TO_CHAR(NEXT_DAY(LAST_DAY('2022-10-27')-7, 3), 'YYYY-MM-DD')
                ELSE TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-27',1))-7, 3), 'YYYY-MM-DD')
            END
        ELSE TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-27',1))-7,3), 'YYYY-MM-DD')
    END "Wyplata"
FROM Kocury
ORDER BY w_stadku_od;


--zad10 
SELECT pseudo || ' - ' || CASE COUNT(pseudo) 
                            WHEN 1 
                            THEN 'Unikalny'
                            ELSE 'nieunikalny' 
                            END "Unikalnosc atr. PSEUDO"
FROM Kocury
GROUP BY pseudo;

--* wszystkite krotki zlicza
SELECT szef || ' - ' || CASE COUNT(pseudo)
                            WHEN  1
                            THEN 'Unikalny'
                            ELSE 'nieunikalny' 
                            END "Unikalnosc atr. SZEF"
FROM Kocury
WHERE szef IS NOT NULL
GROUP BY szef;

--zad11

SELECT pseudo "Pseudonim", COUNT(imie_wroga) "Liczba wrogow"
FROM wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(pseudo)>=2;

--czy juz mozna JOIN?
SELECT K.pseudo "Pseudonim", COUNT(imie_wroga) "Liczba wrogow"
FROM Kocury K JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY K.pseudo
HAVING COUNT(WK.imie_wroga)>=2;


--zad12

SELECT 'Liczba kotow= ' " ", COUNT(pseudo) " ", 'lowi jako ' " ",  funkcja " ", 'i zjada max.' " ",
       TO_CHAR(MAX(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)),'00.00') " ", 'myszy miesiecznie' " "
FROM Kocury
WHERE plec != 'M'
GROUP BY funkcja
HAVING funkcja != 'SZEFUNIO' AND 
       AVG(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)) > 50;
       
       
--zad13
SELECT nr_bandy "Nr bandy", plec "Plec", MIN(NVL(przydzial_myszy,0)) "Minimalny przydzial"
FROM Kocury
GROUP BY nr_bandy, plec;

--zad14
SELECT LEVEL "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM Kocury
WHERE plec='M'
CONNECT BY PRIOR pseudo=szef
START WITH funkcja='BANDZIOR';

--zad15
SELECT LPAD((LEVEL-1),(LEVEL-1)*4+1,'===>') || '                ' || imie "Hierarchia", NVL(szef, 'Sam sobie panem') "Pseudo szefa", funkcja "Funkcja"
FROM Kocury
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

--zad16
-- jak usunac drzewo i galaz
SELECT LPAD(' ', 4*(LEVEL-1)) || pseudo "Droga sluzbowa"  
FROM Kocury
CONNECT BY pseudo = PRIOR szef AND pseudo!='RAFA'
START WITH plec='M' 
    AND EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM w_stadku_od) > 13
    AND myszy_extra IS NULL AND pseudo!='RAFA';
       