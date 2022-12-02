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
CREATE OR REPLACE PACKAGE PACK IS
    FUNCTION ObliczPodatek(pseudonim KOCURY.PSEUDO%TYPE) RETURN NUMBER;
    PROCEDURE  AddBanda(nr_ban BANDY.NR_BANDY%TYPE,
                                    naz_ban BANDY.NAZWA%TYPE,
                                    ter BANDY.TEREN%TYPE);
END PACK;

CREATE OR REPLACE PACKAGE BODY PACK IS
    FUNCTION ObliczPodatek(pseudonim KOCURY.PSEUDO%TYPE) RETURN NUMBER
        IS
        wysokosc_podatku NUMBER := 0;
        ile NUMBER := 0;
        BEGIN
            SELECT CEIL(0.05 * (NVL(przydzial_myszy,0) + NVL(myszy_extra,0)))
            INTO wysokosc_podatku
            FROM KOCURY
            WHERE pseudo = pseudonim;
            
            SELECT COUNT(pseudo) 
            INTO ile 
            FROM KOCURY
            WHERE szef = pseudonim;
            
            IF ile = 0 THEN
                wysokosc_podatku := wysokosc_podatku + 2;
            END IF;
            
            SELECT COUNT(pseudo) INTO ile FROM WROGOWIE_KOCUROW WHERE pseudo = pseudonim;
            if ile = 0 THEN
                wysokosc_podatku := wysokosc_podatku + 1;
            END IF;
            SELECT NVL(przydzial_myszy,0) INTO ile FROM KOCURY WHERE pseudo = pseudonim;
            IF ile > 20 THEN
                wysokosc_podatku := wysokosc_podatku + 5;
            END IF;
        RETURN wysokosc_podatku;
        END;

    PROCEDURE AddBanda(nr_ban BANDY.NR_BANDY%TYPE,
                                    naz_ban BANDY.NAZWA%TYPE,
                                    ter BANDY.TEREN%TYPE)
        IS
            liczba_znalezionych NUMBER;
            juz_istnieje_exc EXCEPTION;
            zly_numer_bandy_exc EXCEPTION;
            wiadomosc_exc    VARCHAR2(30) := '';
        BEGIN
            IF nr_ban < 0 THEN 
                RAISE zly_numer_bandy_exc;
            END IF;
        
            SELECT COUNT(*) 
            INTO liczba_znalezionych
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
END PACK;

EXECUTE PACK.AddBanda(1, 'PUSZYSCI', 'POLE');
EXECUTE PACK.AddBanda(2, 'CZARNI RYCERZE', 'POLE');
EXECUTE PACK.AddBanda(1, 'SZEFOSTWO', 'NOWE');
EXECUTE PACK.AddBanda(10, 'NOWI', 'NOWE');
SELECT * FROM bandy;

ROLLBACK;
BEGIN
        FOR kot IN (SELECT pseudo FROM Kocury)
        LOOP
            DBMS_OUTPUT.PUT_LINE(RPAD(kot.pseudo, 8) || ' podatek równy ' || PACK.ObliczPodatek(kot.pseudo));
        END LOOP;
END;

--zad41
CREATE OR REPLACE TRIGGER BiggerThenLastNumber
    BEFORE INSERT 
    ON BANDY
    FOR EACH ROW
DECLARE
    ostatni_nr BANDY.NR_BANDY%TYPE;
BEGIN
    SELECT MAX(NR_BANDY)
    INTO ostatni_nr
    FROM BANDY;
    IF ostatni_nr + 1 <> :NEW.NR_BANDY THEN
        :NEW.NR_BANDY := ostatni_nr + 1;
    END IF;
END;




EXECUTE AddBanda(10, 'NOWI', 'NOWE');

SELECT * FROM bandy;

ROLLBACK;

--zad42
-- 1. rozwiazanie -> kilka wyzwalaczy + pakiet
CREATE OR REPLACE PACKAGE wirus IS
    kara NUMBER := 0;
    nagroda NUMBER := 0;
    przydzial_tygrysa KOCURY.PRZYDZIAL_MYSZY%TYPE;
END;

CREATE OR REPLACE TRIGGER trg_wirus_bef_update
    BEFORE UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
DECLARE
BEGIN
    SELECT PRZYDZIAL_MYSZY INTO wirus.przydzial_tygrysa FROM KOCURY WHERE pseudo = 'TYGRYS';
END;

CREATE OR REPLACE TRIGGER trg_wirus_bef_update_row
    BEFORE UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
    FOR EACH ROW
DECLARE
BEGIN
    IF :NEW.funkcja = 'MILUSIA' THEN
        IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
            DBMS_OUTPUT.PUT_LINE('brak zmiany');
            :NEW.PRZYDZIAL_MYSZY := :OLD.PRZYDZIAL_MYSZY;
        ELSIF :NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1 * wirus.przydzial_tygrysa THEN
            DBMS_OUTPUT.PUT_LINE('podwyzka mniejsza niz 10% Tygrysa');
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1 * wirus.przydzial_tygrysa);
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            wirus.kara := wirus.kara + ROUND(0.1 * wirus.przydzial_tygrysa);
        ELSE
            wirus.nagroda := wirus.nagroda + 5;
        END IF;
    END IF;
END;

CREATE OR REPLACE TRIGGER trg_wirus_aft_update
    AFTER UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
DECLARE
    przydzial KOCURY.PRZYDZIAL_MYSZY%TYPE;
    ekstra    KOCURY.MYSZY_EXTRA%TYPE;
BEGIN
    SELECT PRZYDZIAL_MYSZY, MYSZY_EXTRA
    INTO przydzial, ekstra
    FROM KOCURY
    WHERE pseudo = 'TYGRYS';
    
    przydzial := przydzial - wirus.kara;
    ekstra := ekstra + wirus.nagroda;
    
    IF wirus.kara <> 0 OR wirus.nagroda <> 0 THEN
        wirus.kara := 0;
        wirus.nagroda := 0;
        UPDATE KOCURY
        SET PRZYDZIAL_MYSZY = przydzial,
            MYSZY_EXTRA     = ekstra
        WHERE pseudo = 'TYGRYS';
    END IF;
END;

UPDATE KOCURY
SET PRZYDZIAL_MYSZY = 50
WHERE PSEUDO = 'PUSZYSTA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 1
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 20
WHERE funkcja = 'MILUSIA';

SELECT *
FROM KOCURY
WHERE PSEUDO IN ('PUSZYSTA', 'TYGRYS');

ROLLBACK;

DROP TRIGGER TRG_WIRUS_AFT_UPDATE;
DROP TRIGGER TRG_WIRUS_BEF_UPDATE;
DROP TRIGGER TRG_WIRUS_BEF_UPDATE_ROW;
DROP PACKAGE WIRUS;


--rozwiazanie compound
CREATE OR REPLACE TRIGGER trg_wirus_comp
    FOR UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
    COMPOUND TRIGGER
    przydzial_tygrysa KOCURY.PRZYDZIAL_MYSZY%TYPE;
    ekstra KOCURY.MYSZY_EXTRA%TYPE;
    kara NUMBER:=0;
    nagroda NUMBER:=0;
    
BEFORE STATEMENT IS
BEGIN
    SELECT przydzial_myszy INTO przydzial_tygrysa
    FROM KOCURY
    WHERE pseudo = 'TYGRYS';
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    IF :NEW.funkcja = 'MILUSIA' THEN
        IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
            DBMS_OUTPUT.PUT_LINE('brak zmiany');
            :NEW.PRZYDZIAL_MYSZY := :OLD.PRZYDZIAL_MYSZY;
        ELSIF :NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1 * przydzial_tygrysa THEN
            DBMS_OUTPUT.PUT_LINE('podwyzka mniejsza niz 10% Tygrysa');
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1 * przydzial_tygrysa);
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            kara := kara + ROUND(0.1 * przydzial_tygrysa);
        ELSE
            nagroda := nagroda + 5;
        END IF;
    END IF;
END BEFORE EACH ROW;

AFTER STATEMENT IS
BEGIN
    SELECT myszy_extra INTO ekstra
    FROM KOCURY
    WHERE pseudo = 'TYGRYS';
    przydzial_tygrysa := przydzial_tygrysa - kara;
    ekstra := ekstra + nagroda;
    IF kara <> 0 AND nagroda <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nowy przydzial Tygrysa: ' || przydzial_tygrysa);
        DBMS_OUTPUT.PUT_LINE('Nowe myszy ekstra Tygrysa: ' || ekstra);
        kara := 0;
        nagroda := 0;
        UPDATE KOCURY
        SET przydzial_myszy = przydzial_tygrysa,
            myszy_extra = ekstra
        WHERE pseudo = 'TYGRYS';
    END IF;
END AFTER STATEMENT;
END;

UPDATE KOCURY
SET PRZYDZIAL_MYSZY = 50
WHERE PSEUDO = 'PUSZYSTA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 1
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 20
WHERE funkcja = 'MILUSIA';

SELECT *
FROM KOCURY
WHERE PSEUDO IN ('PUSZYSTA', 'TYGRYS');

ROLLBACK;
DROP TRIGGER trg_wirus_comp;

--zad43
SELECT DISTINCT FUNKCJA
FROM KOCURY;

SELECT funkcja
FROM FUNKCJE;

DECLARE 
    CURSOR funkcje IS SELECT DISTINCT FUNKCJA
                        FROM KOCURY;
    CURSOR iloscKotow IS SELECT COUNT(pseudo) ilosc, SUM(NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0)) sumaMyszy
                        FROM Kocury, Bandy WHERE Kocury.nr_bandy = Bandy.nr_bandy
                        GROUP BY Bandy.nazwa, Kocury.plec
                        ORDER BY Bandy.nazwa, plec;
    CURSOR funkcjezBand IS SELECT SUM(NVL(Kocury.PRZYDZIAL_MYSZY, 0) + NVL(Kocury.MYSZY_EXTRA, 0)) sumaMyszy,
                                Kocury.Funkcja funkcja,
                                Bandy.nazwa naz,
                                Kocury.plec pl
                            FROM Kocury, Bandy WHERE Kocury.nr_bandy = Bandy.nr_bandy
                            GROUP BY Bandy.nazwa, Kocury.plec, Kocury.funkcja
                            ORDER BY Bandy.nazwa, Kocury.plec, Kocury.funkcja;
    ilosc NUMBER;
    il iloscKotow%ROWTYPE;
    bpf funkcjezBand%ROWTYPE;
BEGIN
    DBMS_OUTPUT.put('NAZWA BANDY       PLEC    ILE ');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(RPAD(fun.funkcja, 10));
        END LOOP;
    DBMS_OUTPUT.put_line('    SUMA');
    DBMS_OUTPUT.put('---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    
    DBMS_OUTPUT.put_line(' --------');
    
    OPEN funkcjezBand;
    OPEN iloscKotow;
    FETCH funkcjezBand INTO bpf;
    FOR banda IN (SELECT nazwa, NR_BANDY FROM BANDY WHERE nazwa <> 'ROCKERSI' ORDER BY nazwa)
        LOOP
            FOR ple IN (SELECT PLEC FROM KOCURY GROUP BY PLEC ORDER BY PLEC )
                LOOP 
                    DBMS_OUTPUT.put(CASE WHEN ple.plec = 'M' THEN RPAD(' ', 18) ELSE RPAD(banda.nazwa, 18) END);
                    DBMS_OUTPUT.put(CASE WHEN ple.plec = 'M' THEN 'Kocor' ELSE 'Kotka' END);
                    
                    FETCH iloscKotow INTO il;
                    DBMS_OUTPUT.put(LPAD(il.ilosc, 4));
                    FOR fun IN funkcje
                        LOOP
                            IF fun.funkcja = bpf.funkcja AND banda.nazwa = bpf.naz AND ple.plec = bpf.pl
                            THEN 
                                DBMS_OUTPUT.put(LPAD(NVL(bpf.sumaMyszy, 0), 10));
                                FETCH funkcjezBand INTO bpf;
                            ELSE
                                DBMS_OUTPUT.put(LPAD(NVL(0, 0), 10));
                            END IF;
                        END LOOP;
                    DBMS_OUTPUT.put(LPAD(NVL(il.sumaMyszy, 0), 10));
                    DBMS_OUTPUT.new_line();
                END LOOP;
        END LOOP;
    CLOSE iloscKotow;
    CLOSE funkcjezBand;
    DBMS_OUTPUT.put('Z---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    DBMS_OUTPUT.put_line(' --------');
    DBMS_OUTPUT.put('Zjada razem                ');
    FOR fun IN funkcje
        LOOP
            SELECT SUM(NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0))
            INTO ilosc
            FROM Kocury K
            WHERE K.FUNKCJA = fun.FUNKCJA;
            DBMS_OUTPUT.put(LPAD(NVL(ilosc, 0), 10));
        END LOOP;
    SELECT SUM(nvl(PRZYDZIAL_MYSZY, 0) + nvl(MYSZY_EXTRA, 0)) INTO ilosc FROM Kocury;
    DBMS_OUTPUT.put(LPAD(ilosc, 10));
    DBMS_OUTPUT.new_line();
END;


--zad45
CREATE TABLE Dodatki_extra(
    pseudo VARCHAR2(15) CONSTRAINT dodatki_pseudo_fk REFERENCES Kocury(pseudo),
    dod_extra NUMBER(3) DEFAULT 0    
);

SELECT * FROM Dodatki_extra;

DROP TABLE Dodatki_extra;


--45 sprawdz to
CREATE OR REPLACE TRIGGER trg_tygrys_kara
    BEFORE UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
    FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF LOGIN_USER <> 'TYGRYS' AND :NEW.PRZYDZIAL_MYSZY > :OLD.PRZYDZIAL_MYSZY AND :NEW.FUNKCJA = 'MILUSIA' THEN
        EXECUTE IMMEDIATE
            'DECLARE
                ILE NUMBER;
                DOD NUMBER;
                CURSOR milusie IS SELECT PSEUDO
                FROM KOCURY
                WHERE funkcja = ''MILUSIA'';
            BEGIN
            FOR milusia IN milusie
                LOOP
                SELECT COUNT(*) INTO ILE FROM DODATKI_EXTRA WHERE PSEUDO = milusia.PSEUDO;
                IF ILE = 0 THEN
                    INSERT INTO DODATKI_EXTRA(PSEUDO, DOD_EXTRA) VALUES(milusia.PSEUDO, -10);
                    ELSE
                        SELECT DOD_EXTRA INTO DOD FROM DODATKI_EXTRA WHERE PSEUDO = milusia.PSEUDO;
                        UPDATE DODATKI_EXTRA SET DOD_EXTRA = DOD - 10 WHERE PSEUDO = milusia.PSEUDO;
                    END IF;
                END LOOP;
            END;';

        COMMIT;
    END IF;
END;

UPDATE KOCURY
SET PRZYDZIAL_MYSZY = 100
WHERE IMIE = 'SONIA';

UPDATE KOCURY
SET przydzial_myszy = 200
WHERE imie = 'SONIA';

SELECT *
FROM KOCURY
WHERE FUNKCJA = 'MILUSIA';

SELECT * FROM Dodatki_extra;

ROLLBACK;

DROP TRIGGER trg_tygrys_kara;


--zad 46
--tabela
CREATE TABLE Proby_wykroczenia 
(
    kto VARCHAR2(15) NOT NULL, --klucz obcy?
    kiedy DATE NOT NULL,
    jakiemu VARCHAR2(15) NOT NULL,
    operacja VARCHAR2(15) NOT NULL
);

DROP TABLE Proby_wykroczenia;

--wyzwalacz
CREATE OR REPLACE TRIGGER trg_monitor_wykroczenia
    BEFORE INSERT OR UPDATE OF PRZYDZIAL_MYSZY
    ON KOCURY
    FOR EACH ROW
DECLARE
    min_mysz FUNKCJE.MIN_MYSZY%TYPE;
    max_mysz FUNKCJE.MAX_MYSZY%TYPE;
    poza EXCEPTION;
    curr_data DATE DEFAULT SYSDATE;
    zdarzenie VARCHAR2(20);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT MIN_MYSZY, MAX_MYSZY INTO min_mysz, max_mysz FROM FUNKCJE WHERE FUNKCJA = :NEW.FUNKCJA;
    IF max_mysz < :NEW.PRZYDZIAL_MYSZY OR min_mysz > :NEW.PRZYDZIAL_MYSZY THEN
        IF INSERTING THEN 
            zdarzenie := 'INSERT';
        ELSIF UPDATING THEN
            zdarzenie := 'UPDATE';
        END IF;
        INSERT INTO Proby_wykroczenia(kto, kiedy, jakiemu, operacja) VALUES (ORA_LOGIN_USER, curr_data, :NEW.PSEUDO, zdarzenie);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20001,'przydzial myszy poza zakresem funkcji, nie wykonano zmian.');
        --:NEW.PRZYDZIAL_MYSZY := :OLD.PRZYDZIAL_MYSZY;
        --RAISE poza;
    END IF;
--EXCEPTION
    --WHEN poza THEN
        --DBMS_OUTPUT.PUT_LINE('poza zakresem');
END;


UPDATE KOCURY
SET PRZYDZIAL_MYSZY = 80
WHERE IMIE = 'JACEK';

SELECT * FROM Kocury;
SELECT * FROM Proby_wykroczenia;

ROLLBACK;

DROP TABLE Proby_wykroczenia;
DROP TRIGGER trg_monitor_wykroczenia;
