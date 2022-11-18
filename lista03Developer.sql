--34
DECLARE
    funkcja_kocura KOCURY.funkcja%TYPE;
BEGIN
    SELECT FUNKCJA INTO funkcja_kocura
    FROM KOCURY
    WHERE FUNKCJA = UPPER('&nazwa_funkcji');
DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || funkcja_kocura);
EXCEPTION
    WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('znaleziono');
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('NIE znaleziono');
END;

--35
DECLARE 
    imie_kocura KOCURY.imie%TYPE;
    pzydzial_kocura NUMBER;
    miesiac_kocura NUMBER;
    znaleziony BOOLEAN DEFAULT FALSE;
BEGIN
    SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra,0))*12, EXTRACT(MONTH FROM w_stadku_od)
    INTO imie_kocura, pzydzial_kocura, miesiac_kocura
    FROM KOCURY
    WHERE PSEUDO = UPPER('&pseudonim');
    
    IF pzydzial_kocura > 700 THEN 
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
    ELSIF imie_kocura LIKE '%A%'
        THEN DBMS_OUTPUT.PUT_LINE('imiê zawiera litere A');
    ELSIF miesiac_kocura = 11 
        THEN DBMS_OUTPUT.PUT_LINE('listopad jest miesiacem przystapienia do stada');
    ELSE DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
    END IF;
    END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('BRAK TAKIEGO KOTA');
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;

--zad36
DECLARE 
    CURSOR kolejka IS
        SELECT PSEUDO, NVL(PRZYDZIAL_MYSZY,0) zjada, Funkcje.MAX_MYSZY maks
        FROM KOCURY JOIN FUNKCJE ON KOCURY.FUNKCJA = FUNKCJE.FUNKCJA
        ORDER BY 2
    FOR UPDATE OF PRZYDZIAL_MYSZY;
    zmiany NUMBER:=0;
    suma NUMBER:=0;
    kot kolejka%ROWTYPE;
BEGIN
    SELECT SUM(NVL(PRZYDZIAL_MYSZY,0)) INTO suma
    FROM KOCURY;
    OPEN kolejka;
    WHILE suma <= 1050
        LOOP
            FETCH kolejka INTO kot;
            EXIT WHEN kolejka%NOTFOUND;
            IF ROUND(kot.zjada * 1.1) <= kot.maks THEN
                UPDATE KOCURY
                SET PRZYDZIAL_MYSZY = ROUND(PRZYDZIAL_MYSZY * 1.1)
                WHERE CURRENT OF kolejka;
                suma := suma + ROUND(kot.zjada * 0.1);
                zmiany := zmiany + 1;
            ELSIF kot.zjada <> kot.maks THEN
                UPDATE KOCURY
                SET PRZYDZIAL_MYSZY = kot.maks
                WHERE CURRENT OF kolejka;
                suma := suma + kot.maks - kot.zjada;
                zmiany := zmiany + 1;
            END IF;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE(
                'Calk. przydzial w stadku - ' || TO_CHAR(suma) || ' Zmian - ' || TO_CHAR(zmiany));
    CLOSE kolejka;
END;

SELECT IMIE, PRZYDZIAL_MYSZY "Myszki po podwyzce"
FROM KOCURY
ORDER BY 2 DESC;

ROLLBACK;

--zad37
DECLARE 
    CURSOR topC IS
        SELECT pseudo, NVL(przydzial_myszy,0) +  NVL(myszy_extra, 0) "zjada"
        FROM KOCURY
        ORDER BY "zjada" DESC;
    top topC%ROWTYPE;
BEGIN
    OPEN topC;
    DBMS_OUTPUT.PUT_LINE('Nr   Pseudonim   Zjada');
    DBMS_OUTPUT.PUT_LINE('----------------------');
    FOR i IN 1..5
    LOOP
        FETCH topC INTO top;
        EXIT WHEN topC%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(i) ||'    '|| RPAD(top.pseudo, 8) || '    ' || LPAD(TO_CHAR(top."zjada"), 5));
    END LOOP;
END;


--zad38
DECLARE
    liczba_przelozonych     NUMBER := :liczba_przelozonych;
    max_liczba_przelozonych NUMBER;
    szerokosc_kol           NUMBER := 15;
    pseudo_aktualny         KOCURY.PSEUDO%TYPE;
    imie_aktualny           KOCURY.IMIE%TYPE;
    pseudo_nastepny         KOCURY.SZEF%TYPE;
    CURSOR podwladni IS SELECT PSEUDO, IMIE
                        FROM KOCURY
                        WHERE FUNKCJA IN ('MILUSIA', 'KOT');
BEGIN
    SELECT MAX(LEVEL) - 1
    INTO max_liczba_przelozonych
    FROM Kocury
    CONNECT BY PRIOR szef = pseudo
    START WITH funkcja IN ('KOT', 'MILUSIA');
    liczba_przelozonych := LEAST(max_liczba_przelozonych, liczba_przelozonych);

    DBMS_OUTPUT.PUT(RPAD('IMIE ', szerokosc_kol));
    FOR licznik IN 1..liczba_przelozonych
        LOOP
            DBMS_OUTPUT.PUT(RPAD('|  SZEF ' || licznik, szerokosc_kol));
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', szerokosc_kol * (liczba_przelozonych + 1), '-'));

    FOR kot IN podwladni
        LOOP
            DBMS_OUTPUT.PUT(RPAD(KOT.IMIE, szerokosc_kol));
            SELECT SZEF INTO pseudo_nastepny FROM KOCURY WHERE PSEUDO = kot.PSEUDO;
            FOR COUNTER IN 1..liczba_przelozonych
                LOOP
                    IF pseudo_nastepny IS NULL THEN
                        DBMS_OUTPUT.PUT(RPAD('|  ', szerokosc_kol));

                    ELSE
                        SELECT K.IMIE, K.PSEUDO, K.SZEF
                        INTO imie_aktualny, pseudo_aktualny, pseudo_nastepny
                        FROM KOCURY K
                        WHERE K.PSEUDO = pseudo_nastepny;
                        DBMS_OUTPUT.PUT(RPAD('|  ' || imie_aktualny, szerokosc_kol));
                    END IF;
                END LOOP;
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;
END;

--zad39
DECLARE
    nr_ban NUMBER:= &nr;
    naz_ban BANDY.NAZWA%TYPE := '&nazwa';
    ter BANDY.TEREN%TYPE := '&ter';
    liczba_znalezionych NUMBER;
    juz_istnieje_exc EXCEPTION;
    zly_numer_bandy_exc EXCEPTION;
    wiadomosc_exc    VARCHAR2(30)         := '';
BEGIN
    IF nr_ban < 0 THEN RAISE zly_numer_bandy_exc;
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nr_bandy = nr_ban;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || nr_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nazwa = naz_ban;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || naz_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE teren = ter;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || ter || ',';
    END IF;
    
    IF LENGTH(wiadomosc_exc) > 0 THEN
        RAISE juz_istnieje_exc;
    END IF;
    
    INSERT INTO BANDY(NR_BANDY, NAZWA, TEREN) VALUES (nr_ban, naz_ban, ter);
    
EXCEPTION
    WHEN zly_numer_bandy_exc THEN
        DBMS_OUTPUT.PUT_LINE('Nr bandy musi byc liczba dodatnia');
    WHEN juz_istnieje_exc THEN
        DBMS_OUTPUT.PUT_LINE(TRIM(TRAILING ',' FROM wiadomosc_exc) || ': juz istnieje');
END;

--zad40
CREATE OR REPLACE PROCEDURE AddBanda(nr_ban BANDY.NR_BANDY%TYPE,
                                    naz_ban BANDY.NAZWA%TYPE,
                                    ter BANDY.TEREN%TYPE)
IS
    liczba_znalezionych NUMBER;
    juz_istnieje_exc EXCEPTION;
    zly_numer_bandy_exc EXCEPTION;
    wiadomosc_exc    VARCHAR2(30) := '';
BEGIN
    IF nr_ban < 0 THEN RAISE zly_numer_bandy_exc;
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nr_bandy = nr_ban;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || nr_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nazwa = naz_ban;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || naz_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE teren = ter;
    IF liczba_znalezionych <> 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || ter || ',';
    END IF;
    
    IF LENGTH(wiadomosc_exc) > 0 THEN
        RAISE juz_istnieje_exc;
    END IF;
    
    INSERT INTO BANDY(NR_BANDY, NAZWA, TEREN) VALUES (nr_ban, naz_ban, ter);
EXCEPTION
    WHEN zly_numer_bandy_exc THEN
        DBMS_OUTPUT.PUT_LINE('Nr bandy musi byc liczba dodatnia');
    WHEN juz_istnieje_exc THEN
        DBMS_OUTPUT.PUT_LINE(TRIM(TRAILING ',' FROM wiadomosc_exc) || ': juz istnieje');
END;

EXECUTE AddBanda(1, 'PUSZYSCI', 'POLE');
EXECUTE AddBanda(2, 'CZARNI RYCERZE', 'POLE');
EXECUTE AddBanda(1, 'SZEFOSTWO', 'NOWE');
EXECUTE AddBanda(10, 'NOWI', 'NOWE');
SELECT *
FROM bandy;

ROLLBACK;


