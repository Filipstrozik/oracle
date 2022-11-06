--zad17
SELECT pseudo "POLUJE W POLU", przydzial_myszy "PRZYDZIAL MYSZY", nazwa "BANDA"
FROM Kocury
JOIN Bandy
ON Kocury.nr_bandy=Bandy.nr_bandy
WHERE teren IN('POLE', 'CALOSC') AND przydzial_myszy>50
ORDER BY PRZYDZIAL_MYSZY DESC;

--zad18
SELECT  K2.imie, K2.w_stadku_od "POLUJE OD"
FROM Kocury K1
JOIN Kocury K2
ON K1.imie='JACEK'
WHERE K1.w_stadku_od>K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;

--zad19a
SELECT K.imie "Imie", K.funkcja "Funkcja", NVL(K1.imie,' ') "Szef 1",  NVL(K2.imie,' ') "Szef 2", NVL(K3.imie,' ') "Szef 3"
FROM Kocury K
LEFT JOIN Kocury K1 ON K.szef = K1.pseudo
LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
WHERE K.funkcja IN ('KOT','MILUSIA');


--zad19b
SELECT *
FROM (SELECT CONNECT_BY_ROOT imie "Imie", imie, CONNECT_BY_ROOT funkcja "Funkcja", LEVEL AS "LEV"
      FROM KOCURY
      CONNECT BY PRIOR szef = pseudo
      START WITH funkcja IN ('KOT','MILUSIA'))
PIVOT (
    MAX(imie) FOR LEV IN (2 "Szef 1", 3 "Szef 2", 4 "Szef 3")
    );

--zad19c
SELECT CONNECT_BY_ROOT imie "Imie",
       CONNECT_BY_ROOT funkcja "Funkcja",
       REPLACE(SYS_CONNECT_BY_PATH(imie, ' | '), ' | ' || CONNECT_BY_ROOT IMIE || ' ' , '') "Imiona kolejnych szefow"
FROM Kocury
WHERE szef IS NULL
CONNECT BY PRIOR szef = pseudo
START WITH funkcja IN ('KOT','MILUSIA');


--zad20
SELECT imie "Imie kotki", nazwa "Nazwa bandy", W.imie_wroga "Imie wroga", stopien_wrogosci "Ocena wroga", data_incydentu "Data inc."
FROM Kocury K1
LEFT JOIN Bandy B ON K1.nr_bandy=B.nr_bandy
LEFT JOIN wrogowie_kocurow WK ON K1.pseudo=WK.pseudo
LEFT JOIN Wrogowie W ON WK.imie_wroga=W.imie_wroga
WHERE
    plec='D' AND data_incydentu > TO_DATE('2007-01-01')
ORDER BY imie;

--zad21 ok
SELECT nazwa "Nazwa Bandy", COUNT(DISTINCT K.pseudo)  "Koty z wrogami"
FROM Kocury K
JOIN Bandy B ON K.nr_bandy = B.nr_bandy
JOIN wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY nazwa;


--zad22 --natural join laczy tabele wspolna kolumna ale zostawia tylko jedną, drugą pomija
SELECT funkcja "Funkcja", pseudo, count(pseudo) "Liczba wrogow"
FROM Kocury
NATURAL JOIN Wrogowie_kocurow
GROUP BY pseudo, funkcja
HAVING COUNT(pseudo)>1;

--zad23 -- obsluzyc
SELECT imie, 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM Kocury
WHERE 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) > 864 AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) "DAWKA ROCZNA", '864' "DAWKA"
FROM Kocury
WHERE 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) = 864 AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM Kocury
WHERE 12*(NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) < 864 AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;

--zad24
--bez podzapytań i operatorów zbiorowych
SELECT B.nr_bandy, nazwa, teren
FROM Bandy B
LEFT JOIN Kocury K
ON B.nr_bandy=K.nr_bandy
WHERE pseudo IS NULL;
--wykorzystując operatory zbiorowe
SELECT nr_bandy, nazwa, teren
FROM Bandy
MINUS
SELECT DISTINCT B.nr_bandy, nazwa, teren
FROM Bandy B JOIN Kocury K ON B.nr_bandy=K.nr_bandy;

--zad25 -- ALL kazda zwrocona wartosci przez zapytanie
SELECT imie, funkcja, NVL(przydzial_myszy,0) "PRZYDZIAL MYSZY"
FROM Kocury
WHERE NVL(przydzial_myszy,0) >= ALL (SELECT 3*NVL(przydzial_myszy,0)
                                    FROM Kocury K
                                    JOIN Bandy B
                                    ON K.nr_bandy = B.nr_bandy
                                    WHERE funkcja='MILUSIA' AND teren IN('SAD','CALOSC'));

--zad26
SELECT funkcja, ROUND(AVG(NVL(przydzial_myszy,0) + NVL(myszy_extra,0))) "Srednio najw. i najm. myszy"
FROM Kocury
WHERE funkcja<>'SZEFUNIO'
GROUP BY funkcja
HAVING
    ROUND(AVG(NVL(przydzial_myszy,0) + NVL(myszy_extra,0))) --czy obliczony przedzial jest w zbiorze wartosci min , max
    IN (
        (SELECT MIN(ROUND(AVG(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))))
                   FROM KOCURY
                   WHERE FUNKCJA <> 'SZEFUNIO'
                    GROUP BY FUNKCJA
        )
        ,
        (SELECT MAX(ROUND(AVG(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))))
                   FROM KOCURY
                   WHERE FUNKCJA <> 'SZEFUNIO'
                    GROUP BY FUNKCJA
        )
    );

--zad27
--Znaleźć koty zajmujące pierwszych n miejsc pod względem całkowitej liczby
--spożywanych myszy (koty o tym samym spożyciu zajmują to samo miejsce!). Zadanie
--rozwiązać na cztery sposoby:
--a. wykorzystując podzapytanie skorelowane,
--b. wykorzystując pseudokolumnę ROWNUM,
--c. wykorzystując złączenie relacji Kocuury z Kocury
--d. fun alaityczne

--a)
SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra,0) "ZJADA"
FROM  Kocury K
WHERE 12 > (SELECT COUNT(DISTINCT (przydzial_myszy + NVL(myszy_extra,0))) --ilosc kotow lepszych od kota w K,
                FROM Kocury
                WHERE (NVL(K.przydzial_myszy,0) + NVL(K.myszy_extra,0)) < (NVL(przydzial_myszy,0) + NVL(myszy_extra,0))
                )
ORDER BY "ZJADA" DESC;

--b)
SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra,0) "Zjada"
FROM  Kocury K
WHERE NVL(przydzial_myszy,0) + NVL(myszy_extra,0) IN (SELECT *
                                                        FROM (  SELECT DISTINCT NVL(przydzial_myszy,0) + NVL(myszy_extra,0) "ZJADA"
                                                                FROM Kocury
                                                                ORDER BY "ZJADA" DESC
                                                            )
                                                        WHERE ROWNUM<=12);

--c)
SELECT K1.pseudo, MIN(NVL(K1.przydzial_myszy,0) + NVL(K1.myszy_extra,0)) "ZJADA"
FROM Kocury K1
JOIN Kocury K2 ON NVL(K1.przydzial_myszy,0) + NVL(K1.myszy_extra,0) <= NVL(K2.przydzial_myszy,0) + NVL(K2.myszy_extra,0)
GROUP BY K1.pseudo
HAVING COUNT(DISTINCT NVL(K2.przydzial_myszy,0) +NVL(K2.myszy_extra,0)) <= 12
ORDER BY "ZJADA" DESC;

--d
SELECT pseudo, "ZJADA"
FROM (SELECT pseudo, (NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) "ZJADA",
             DENSE_RANK() over (ORDER BY NVL(przydzial_myszy,0) + NVL(myszy_extra,0) DESC )position
      FROM KOCURY)
WHERE position <= 12
ORDER BY "ZJADA" DESC;



--zad28
SELECT TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) "ROK", COUNT(pseudo) "LICZBA WSTAPIEN"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
HAVING COUNT(pseudo)  IN (
    (SELECT * FROM (SELECT DISTINCT COUNT(pseudo)
                    FROM KOCURY
                    GROUP BY EXTRACT(YEAR FROM w_stadku_od)
                    HAVING COUNT(pseudo) >
                           (SELECT AVG(COUNT(EXTRACT(YEAR FROM W_STADKU_OD)))
                            FROM KOCURY
                            GROUP BY EXTRACT(YEAR FROM W_STADKU_OD))
                    ORDER BY COUNT(pseudo))
    WHERE ROWNUM=1),
    (SELECT * FROM (SELECT DISTINCT COUNT(pseudo)
                    FROM KOCURY
                    GROUP BY EXTRACT(YEAR FROM w_stadku_od)
                    HAVING COUNT(pseudo) <
                           (SELECT AVG(COUNT(EXTRACT(YEAR FROM W_STADKU_OD)))
                            FROM KOCURY
                            GROUP BY EXTRACT(YEAR FROM W_STADKU_OD))
                    ORDER BY COUNT(pseudo) DESC)
    WHERE ROWNUM=1)
    )
UNION ALL
SELECT 'Srednia', ROUND(AVG(COUNT(pseudo)),7)
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
ORDER BY 2;

--zad29
--a ze zlaczeniem ale bez podzapytan
SELECT K1.imie, MIN(K1.przydzial_myszy + NVL(K1.myszy_extra, 0)) "ZJADA", K1.nr_bandy, AVG(NVL(K2.przydzial_myszy,0) + NVL(K2.myszy_extra,0)) "SREDNIA BANDY"
--SELECT K1.nr_bandy, AVG(NVL(K1.przydzial_myszy,0) + NVL(myszy_extra,0))
FROM Kocury K1
JOIN Kocury K2
ON K1.nr_bandy = K2.nr_bandy
WHERE K1.plec='M'
GROUP BY K1.imie, K1.nr_bandy
HAVING MIN(NVL(K1.przydzial_myszy,0) + NVL(K1.myszy_extra,0)) < AVG(NVL(K2.przydzial_myszy,0) + NVL(K2.myszy_extra,0));

--zad29b TODO 29 jak ma byc nazwana srednia
SELECT  K1.imie, (K1.przydzial_myszy + NVL(K1.myszy_extra, 0)) "ZJADA" ,K1.nr_bandy, AVG "SREDNIA BANDY"
FROM (SELECT nr_bandy nb, AVG(przydzial_myszy + NVL(myszy_extra,0)) "AVG"
        FROM Kocury
        GROUP BY nr_bandy)
JOIN  KOCURY K1 ON K1.nr_bandy = nb
WHERE K1.plec='M' AND przydzial_myszy + NVL(myszy_extra, 0) < AVG;

--zad29c
SELECT  imie, (przydzial_myszy + NVL(myszy_extra, 0)) "ZJADA" ,nr_bandy,
    (SELECT AVG(przydzial_myszy + NVL(myszy_extra,0)) "AVG"
        FROM Kocury K
        WHERE Kocury.nr_bandy = K.nr_bandy) "SREDNIA BANDY"
FROM Kocury
WHERE plec='M' AND (przydzial_myszy + NVL(myszy_extra, 0)) < (SELECT AVG(przydzial_myszy + NVL(myszy_extra,0)) "AVG"
    FROM Kocury K
    WHERE Kocury.nr_bandy = K.nr_bandy);

--zad30
SELECT imie, w_stadku_od "WSTAPIL DO STADKA", '<--- NAJMLODSZY STAZEM W BANDZIE ' || nazwa " "
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE w_stadku_od = (SELECT MAX(w_stadku_od)
                    FROM Kocury
                    WHERE nr_bandy = K.nr_bandy)
UNION ALL
SELECT imie, w_stadku_od "WSTAPIL DO STADKA", '<--- NAJSTARSZY STAZEM W BANDZIE ' || nazwa " "
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE w_stadku_od = (SELECT MIN(w_stadku_od)
                    FROM Kocury
                    WHERE nr_bandy = K.nr_bandy)
UNION ALL
SELECT imie, w_stadku_od "WSTAPIL DO STADKA", ' ' " "
FROM Kocury K
WHERE w_stadku_od NOT IN ((SELECT MIN(w_stadku_od)
                    FROM Kocury
                    WHERE nr_bandy = K.nr_bandy),(
                    SELECT MAX(w_stadku_od)
                    FROM Kocury
                    WHERE nr_bandy = K.nr_bandy))
ORDER BY imie;

--zad31
DROP VIEW O_BANDACH;

CREATE VIEW O_Bandach (nazwa_bandy, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS
SELECT nazwa, AVG(przydzial_myszy), MAX(przydzial_myszy), MIN(przydzial_myszy), COUNT(pseudo), COUNT(myszy_extra)
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY nazwa;

SELECT * FROM O_Bandach;

SELECT pseudo "PSEUDONIM", imie, funkcja, przydzial_myszy "ZJADA",
       'OD ' || min_spoz || ' DO ' || max_spoz "GRANICE SPOZYCIA", w_stadku_od "LOWI OD"
FROM O_Bandach
JOIN BANDY B ON nazwa_bandy = B.nazwa
JOIN KOCURY K ON B.NR_BANDY = K.NR_BANDY
WHERE pseudo = 'PLACEK';

--zad32
SELECT pseudo "Pseudonim", plec "Plec", przydzial_myszy "Myszy przed podw.", NVL(myszy_extra,0) "Extra przed podw."
FROM Kocury
LEFT JOIN BANDY B on KOCURY.NR_BANDY = B.NR_BANDY
WHERE pseudo IN (SELECT pseudo --po pseudo?
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'CZARNI RYCERZE'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3
                UNION ALL
                SELECT pseudo --po pseudo?
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'LACIACI MYSLIWI'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3);
--update
UPDATE Kocury
SET przydzial_myszy = CASE plec
                            WHEN 'D' THEN przydzial_myszy + (SELECT MIN(przydzial_myszy)
                                                             FROM KOCURY) * 0.10
                            WHEN 'M' THEN przydzial_myszy + 10
                        END,
    myszy_extra = NVL(myszy_extra,0) + (SELECT AVG(NVL(myszy_extra, 0))
                                        FROM KOCURY K
                                        WHERE K.NR_BANDY = Kocury.nr_bandy) * 0.15
WHERE pseudo IN (SELECT pseudo
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'CZARNI RYCERZE'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3
                UNION ALL
                SELECT pseudo
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'LACIACI MYSLIWI'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3);

--po podwyzce
SELECT pseudo "Pseudonim", plec "Plec", przydzial_myszy "Myszy po podw.", NVL(myszy_extra,0) "Extra po podw."
FROM Kocury
LEFT JOIN BANDY B on KOCURY.NR_BANDY = B.NR_BANDY
WHERE pseudo IN (SELECT pseudo --po pseudo?
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'CZARNI RYCERZE'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3
                UNION ALL
                SELECT pseudo --po pseudo?
                 FROM (SELECT pseudo
                       FROM KOCURY
                       LEFT JOIN BANDY USING (NR_BANDY)
                       WHERE NAZWA = 'LACIACI MYSLIWI'
                       ORDER BY W_STADKU_OD)
                WHERE ROWNUM <=3);
ROLLBACK;

--zad33a
SELECT DECODE(plec, 'Kotka', nazwa, '') "NAZWA BANDY", plec, ile, szefunio, bandzior,
       lowczy, lapacz, kot, milusia, dzielczy, suma
    FROM(SELECT nazwa,
            DECODE(plec, 'D', 'Kotka', 'Kocur') plec,
            TO_CHAR(COUNT(PSEUDO)) ile,
            TO_CHAR(SUM(DECODE(FUNKCJA,'SZEFUNIO', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) szefunio,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'BANDZIOR', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) bandzior,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'LOWCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lowczy,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'LAPACZ', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lapacz,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'KOT', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) kot,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'MILUSIA', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) milusia,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'DZIELCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) dzielczy,
            TO_CHAR(SUM(NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))) suma
        FROM Kocury
        JOIN BANDY B on KOCURY.NR_BANDY = B.NR_BANDY
        GROUP BY nazwa, plec
        ORDER BY 1, 2 DESC)
        UNION ALL
        SELECT 'Z----------------', '--------', '----------', '-----------', '-----------', '----------',
             '----------', '----------', '----------', '----------', '----------'
        FROM DUAL
        UNION ALL
        SELECT 'ZJADA RAZEM', '', '' ile,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'SZEFUNIO', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) szefunio,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'BANDZIOR', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) bandzior,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'LOWCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lowczy,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'LAPACZ', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lapacz,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'KOT', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) kot,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'MILUSIA', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) milusia,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'DZIELCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) dzielczy,
             TO_CHAR(SUM(NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))) suma
        FROM KOCURY JOIN BANDY B on KOCURY.NR_BANDY = B.NR_BANDY;


--33b
SELECT *
FROM
(
  SELECT TO_CHAR(DECODE(plec, 'D', nazwa, '')) "NAZWA BANDY",
        TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocor')) "PLEC",
        TO_CHAR(ile) "ILE",
        TO_CHAR(NVL(szefunio, 0)) "SZEFUNIO",
        TO_CHAR(NVL(bandzior,0)) "BANDZIOR",
        TO_CHAR(NVL(lowczy,0)) "LOWCZY",
        TO_CHAR(NVL(lapacz,0)) "LAPACZ",
        TO_CHAR(NVL(kot,0)) "KOT",
        TO_CHAR(NVL(milusia,0)) "MILUSIA",
        TO_CHAR(NVL(dzielczy,0)) "DZIELCZY",
        TO_CHAR(NVL(suma,0)) "SUMA"
  FROM
  (
        SELECT nazwa, plec, funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
        FROM Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
  ) PIVOT (
        SUM(liczba)
        FOR funkcja
        IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy,
            'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy)
  ) JOIN (
        SELECT nazwa "N", plec "P", COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
        FROM Kocury K JOIN Bandy B ON K.nr_bandy= B.nr_bandy
        GROUP BY nazwa, plec
        ORDER BY nazwa, plec
  ) ON N = nazwa AND P = plec
)
UNION ALL
SELECT 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------',
       '--------','--------', '--------'
FROM DUAL
UNION ALL

SELECT  'ZJADA RAZEM','','',
        TO_CHAR(NVL(szefunio, 0)),
        TO_CHAR(NVL(bandzior, 0)),
        TO_CHAR(NVL(lowczy, 0)),
        TO_CHAR(NVL(lapacz, 0)),
        TO_CHAR(NVL(kot, 0)),
        TO_CHAR(NVL(milusia, 0)),
        TO_CHAR(NVL(dzielczy, 0)),
        TO_CHAR(NVL(suma, 0))
FROM
(
  SELECT      funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
  FROM        Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
) PIVOT (
    SUM(liczba) FOR funkcja IN (
    'SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
    'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy
  )
) NATURAL JOIN (
  SELECT      SUM(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)) suma
  FROM        Kocury
);




--testing

