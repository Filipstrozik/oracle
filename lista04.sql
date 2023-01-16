--sekcja usuwania:
DROP TABLE KocuryT CASCADE CONSTRAINTS;
DROP TABLE PlebsT CASCADE CONSTRAINTS;
DROP TABLE ElitaT CASCADE CONSTRAINTS;
DROP TABLE KontoT CASCADE CONSTRAINTS;
DROP TABLE IncydentyT CASCADE CONSTRAINTS;
DROP TYPE BODY KocuryO ;
DROP TYPE KocuryO FORCE;
DROP TYPE BODY ElitaO;
DROP TYPE ElitaO FORCE;
DROP TYPE BODY PlebsO;
DROP TYPE PlebsO FORCE;
DROP TYPE BODY KontoO;
DROP TYPE KontoO FORCE;
DROP TYPE BODY IncydentO;
DROP TYPE IncydentO FORCE;

SET serveroutput ON;
--zad47
CREATE OR REPLACE TYPE KocuryO AS OBJECT
(
    imie            VARCHAR2(15),
    plec            VARCHAR2(1),
    pseudo          VARCHAR2(15),
    funkcja         VARCHAR2(10),
    w_stadku_od     DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra     NUMBER(3),
    nr_bandy        NUMBER(2),
    szef            REF KocuryO,
    MEMBER FUNCTION caly_przydzial RETURN NUMBER,
    MAP MEMBER FUNCTION info RETURN VARCHAR2
);

DROP TYPE KocuryO;

ROLLBACK;

CREATE OR REPLACE TYPE BODY KocuryO
AS
    MEMBER FUNCTION caly_przydzial RETURN NUMBER IS
    BEGIN
        RETURN NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0);
    END;
    MAP MEMBER FUNCTION info RETURN VARCHAR2 IS
    BEGIN
        RETURN imie || ', ' || plec ||', pseudo:' || pseudo || ' funkcja: '|| funkcja ||', zjada:'|| SELF.CALY_PRZYDZIAL();
    END;
END;


CREATE TABLE KocuryT OF KocuryO (
  imie CONSTRAINT kocuryo_imie_nn NOT NULL,
  plec CONSTRAINT kocuryo_plec_ch CHECK(plec IN ('M', 'D')),
  pseudo CONSTRAINT kocuryo_pseudo_pk PRIMARY KEY,
  funkcja CONSTRAINT ko_f_fk REFERENCES Funkcje(funkcja),
  szef SCOPE IS KocuryT,
  w_stadku_od DEFAULT SYSDATE,
  nr_bandy CONSTRAINT ko_nr_fk REFERENCES Bandy(nr_bandy)
);

DROP TABLE KocuryT;

--plebs
CREATE OR REPLACE TYPE PlebsO AS OBJECT
(
    pseudo   VARCHAR2(15),
    kot       REF KocuryO,
    MEMBER FUNCTION get_details RETURN VARCHAR2
);


CREATE OR REPLACE TYPE BODY PlebsO
AS
    MEMBER FUNCTION get_details RETURN VARCHAR2
        IS
        details VARCHAR2(400);
    BEGIN
        SELECT 'IMIE: ' || DEREF(kot).imie || ' PSEUDO ' || DEREF(kot).pseudo INTO details FROM dual;
        RETURN details;
    END;
END;

CREATE TABLE PlebsT OF PlebsO(
    kot SCOPE IS KocuryT CONSTRAINT plebso_kot_nn NOT NULL,
    CONSTRAINT plebso_fk FOREIGN KEY (pseudo) REFERENCES KocuryT(pseudo),
    CONSTRAINT plebso_pk PRIMARY KEY (pseudo));


-- ElitaO
CREATE OR REPLACE TYPE ElitaO AS OBJECT
(
    pseudo VARCHAR2(15),
    kot      REF KocuryO,
    slugus   REF PlebsO,
    MEMBER FUNCTION get_sluga RETURN REF PlebsO
);
-- ElitaO Body
CREATE OR REPLACE TYPE BODY ElitaO AS
  MEMBER FUNCTION get_sluga RETURN REF PlebsO IS
    BEGIN
      RETURN slugus;
    END;
END;

-- ElitaT Table
CREATE TABLE ElitaT OF ElitaO(
    pseudo CONSTRAINT elitao_pseudo_pk PRIMARY KEY,
    kot SCOPE IS KocuryT CONSTRAINT elitao_kot_nn NOT NULL,
    slugus SCOPE IS PlebsT
);

-- KontoO Object
CREATE OR REPLACE TYPE KontoO AS OBJECT
(
    nr_myszy NUMBER(5),
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    kot REF ElitaO,
    MEMBER PROCEDURE wyprowadz_mysz(dat DATE),
    MAP MEMBER FUNCTION GET_INFO RETURN VARCHAR2
);
-- KontoO Body
CREATE OR REPLACE TYPE BODY KontoO AS
MAP MEMBER FUNCTION GET_INFO RETURN VARCHAR2 IS
    wl ElitaO;
    kocur KocuryO;
    BEGIN
        SELECT DEREF(kot) INTO wl FROM DUAL;
        SELECT DEREF(wl.kot) INTO kocur FROM DUAL;
        RETURN TO_CHAR(data_wprowadzenia) || ' ' || kocur.PSEUDO || TO_CHAR(data_usuniecia);
    END;
    MEMBER PROCEDURE wyprowadz_mysz(dat DATE) IS
    BEGIN
      data_usuniecia := dat;
    END;
END;
-- KontoT Table

CREATE TABLE KontoT OF KontoO (
    nr_myszy CONSTRAINT kontao_n_pk PRIMARY KEY,
    kot SCOPE IS ElitaT CONSTRAINT ko_w_nn NOT NULL,
    data_wprowadzenia CONSTRAINT ko_dw_nn NOT NULL,
    CONSTRAINT ko_dw_du_ch CHECK(data_wprowadzenia <= data_usuniecia)
);
-- Incydenty Object

CREATE OR REPLACE TYPE IncydentO AS OBJECT
(
    pseudo VARCHAR2(15),
    kot REF KocuryO,
    imie_wroga VARCHAR2(15),
    data_incydentu DATE,
    opis_incydentu VARCHAR2(100),
    MEMBER FUNCTION czy_aktualny RETURN BOOLEAN,
    MEMBER FUNCTION czy_ma_opis RETURN BOOLEAN
);
-- IncydentyO Body
CREATE OR REPLACE TYPE BODY IncydentO
AS
    MEMBER FUNCTION czy_ma_opis RETURN BOOLEAN
    IS
    BEGIN
        RETURN opis_incydentu IS NOT NULL;
    END;

    MEMBER FUNCTION czy_aktualny RETURN BOOLEAN
    IS
    BEGIN
        RETURN data_incydentu >= '2010-01-01';
    END;
END;
-- IncydentyT Table

CREATE TABLE IncydentyT OF IncydentO (
    CONSTRAINT incydento_pk PRIMARY KEY(pseudo, imie_wroga),
    kot SCOPE IS KocuryT CONSTRAINT incydentyo_kot_nn NOT NULL,
    pseudo CONSTRAINT incydentyo_pseudo_fk REFERENCES KocuryT(pseudo),
    imie_wroga CONSTRAINT incydento_imie_wroga_fk REFERENCES Wrogowie(imie_wroga),
    data_incydentu CONSTRAINT incydentyo_data_nn NOT NULL
);

--napisac triggery wykluczajace sie
-- sprawdzenie czy dodawany kot w elicie nie jest w plebsie
-- funkcja lub pseudokolumna "COUNT" może występować tylko wewnątrz instrukcji SQL
CREATE OR REPLACE TRIGGER elita_trg
    BEFORE INSERT OR UPDATE
    ON ElitaT
    FOR EACH ROW
DECLARE
    countElita INTEGER;
BEGIN
    SELECT COUNT(PSEUDO) INTO countElita FROM PlebsT P WHERE P.kot = :NEW.kot;
    IF countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Kot należy już do plebsu.');
    END IF;

    SELECT COUNT(PSEUDO) INTO countElita FROM ElitaT E WHERE E.kot = :NEW.kot;
    IF countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot należy już do elity.');
    END IF;
END;
DROP TRIGGER elita_trg;
DROP TRIGGER plebs_trg;

CREATE OR REPLACE TRIGGER plebs_trg
    BEFORE INSERT OR UPDATE
    ON PlebsT
    FOR EACH ROW
DECLARE
    countPlebs NUMBER;
BEGIN
    SELECT COUNT(PSEUDO) INTO countPlebs FROM ElitaT E WHERE E.kot = :NEW.kot;
    IF countPlebs > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Kot należy już do elity.');
    END IF;

    SELECT COUNT(PSEUDO) INTO countPlebs FROM PlebsT P WHERE P.kot = :NEW.kot;
    IF countPlebs > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Kot należy już do plebsu.');
    END IF;
END;


--dane wprowadzenia myszy
DECLARE
    CURSOR koty IS SELECT * FROM KOCURY
        CONNECT BY PRIOR PSEUDO=SZEF
        START WITH SZEF IS NULL;
    sql_string VARCHAR2(1000);
BEGIN
    FOR kot in koty
    LOOP
        sql_string:='DECLARE
            szef REF KocuryO;
            counter NUMBER(2);
        BEGIN
            szef:=NULL;
            SELECT COUNT(*) INTO counter FROM KocuryT T WHERE T.pseudo='''|| kot.szef||''';
            IF (counter>0) THEN
                SELECT REF(T) INTO szef FROM KocuryT T WHERE T.pseudo='''|| kot.szef||''';
            END IF;
            INSERT INTO KocuryT VALUES
                    (KocuryO(''' || kot.imie || ''', ''' || kot.plec || ''', ''' || kot.pseudo || ''', ''' || kot.funkcja
                    || ''','''||kot.w_stadku_od || ''', ''' || kot.przydzial_myszy ||''', ''' || kot.myszy_extra ||
                        ''',''' || kot.nr_bandy ||''',' || 'szef' || '));
            END;';
        DBMS_OUTPUT.PUT_LINE(sql_string);
        EXECUTE IMMEDIATE sql_string;
        END LOOP;
END;

SELECT * FROM KocuryT;
COMMIT;


DECLARE
CURSOR zdarzenia IS SELECT * FROM Wrogowie_kocurow;
dyn_sql VARCHAR2(1000);
BEGIN
    FOR zdarzenie IN zdarzenia
    LOOP
      dyn_sql:='DECLARE
            kot REF KocuryO;
        BEGIN
            SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo='''|| zdarzenie.pseudo||''';
            INSERT INTO IncydentyT VALUES
                    (IncydentO(''' || zdarzenie.pseudo || ''',  kot , ''' || zdarzenie.imie_wroga || ''', ''' || zdarzenie.data_incydentu
                    || ''',''' || zdarzenie.opis_incydentu|| '''));
            END;';
       DBMS_OUTPUT.PUT_LINE(dyn_sql);
       EXECUTE IMMEDIATE  dyn_sql;
    END LOOP;
END;

SELECT * FROM IncydentyT;

--plebs
DECLARE
CURSOR koty IS SELECT  pseudo
                    FROM (SELECT K.pseudo pseudo FROM KocuryT K ORDER BY K.caly_przydzial() ASC)
                    WHERE ROWNUM<= (SELECT COUNT(*) FROM KocuryT)/2;
dyn_sql VARCHAR2(1000);
BEGIN
    FOR plebs IN koty
    LOOP
      dyn_sql:='DECLARE
            kot REF KocuryO;
        BEGIN
            SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo='''|| plebs.pseudo||''';
            INSERT INTO PlebsT VALUES
                    (PlebsO('''|| plebs.pseudo ||''',' || 'kot' || '));
            END;';
       EXECUTE IMMEDIATE  dyn_sql;
    END LOOP;
END;

SELECT P.pseudo, P.kot.info() FROM PlebsT P;
ROLLBACK;

DECLARE
CURSOR koty IS SELECT PSEUDO FROM (SELECT K.pseudo pseudo FROM KocuryT K ORDER BY K.caly_przydzial() DESC)
    WHERE ROWNUM <= (SELECT COUNT(*) FROM KocuryT)/2;
sql_string VARCHAR2(1000);
num NUMBER:=1;
BEGIN
    FOR elita in koty
    LOOP
        sql_string:='DECLARE
                        kot REF KocuryO;
                        sluga REF PlebsO;
                    BEGIN
                        SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo=''' || elita.pseudo || ''';' ||
                       'SELECT plebs INTO sluga FROM (SELECT REF(P) plebs, rownum num FROM PlebsT P) WHERE NUM=' || num ||';'||
                    'INSERT INTO ElitaT VALUES (ElitaO(''' || elita.pseudo ||''', kot, sluga)); END;';
        EXECUTE IMMEDIATE  sql_string;
        num:=num+1;
        END LOOP;
END;

SELECT E.kot.pseudo, E.slugus.pseudo, E.pseudo, E.kot.caly_przydzial() FROM ElitaT E;

--konto
CREATE SEQUENCE nr_myszy;

DECLARE
CURSOR koty IS SELECT pseudo FROM ElitaT;
sql_string VARCHAR2(1000);
BEGIN
    FOR elita IN koty
    LOOP
      sql_string:='DECLARE
            kot REF ElitaO;
            dataw DATE:=SYSDATE;
        BEGIN
            SELECT REF(E) INTO kot FROM ElitaT E WHERE E.pseudo='''|| elita.pseudo||''';
            INSERT INTO KontoT VALUES
                    (KontoO(nr_myszy.NEXTVAL, dataw, NULL, kot));
        END;';
       DBMS_OUTPUT.PUT_LINE(sql_string);
       EXECUTE IMMEDIATE  sql_string;
    END LOOP;
END;

SELECT * FROM KontoT;

--METODY:
SELECT DEREF(kot).info() FROM PLEBST;
SELECT DEREF(kot).info(), DEREF(slugus).get_details() FROM ELitaT;
SELECT data_usuniecia, data_wprowadzenia, DEREF(kot).pseudo, DEREF(kot).get_sluga().get_details() FROM KONTOT;
SELECT K.IMIE, K.PLEC, K.caly_przydzial() FROM KocuryT K WHERE K.caly_przydzial() > 90;
--PODZAPYTANIE

SELECT pseudo, plec FROM (SELECT K.pseudo pseudo, K.plec plec FROM KocuryT K WHERE K.PLEC = 'D');

SELECT K.info() FROM KocuryT K WHERE K.caly_przydzial() <= (
    SELECT AVG(K1.caly_przydzial())
    FROM KocuryT K1
    );

--GRUPOWANIE
SELECT K.funkcja, COUNT(K.pseudo) as koty_w_funkcji FROM KocuryT K GROUP BY K.funkcja;

SELECT DEREF(kot).pseudo "Kot", count(slugus) "Sługa"
FROM ElitaT E
GROUP BY DEREF(kot).pseudo;

SELECT E.kot.pseudo, E.kot.caly_przydzial()
FROM KocuryT K JOIN ElitaT E  ON E.kot = REF(K);

SELECT REF(T). FROM PlebsT T WHERE T.kot.plec = 'M';

SELECT K.pseudo, data_wprowadzenia, data_usuniecia
FROM KocuryT K JOIN ElitaT E ON REF(K) = E.kot LEFT JOIN KontoT ON REF(E) = KontoT.kot;

--lista2 zad 18
SELECT K2.imie, K2.w_stadku_od "POLUJE OD"
FROM KocuryT K1
         JOIN KocuryT K2
              ON K1.imie = 'JACEK'
WHERE K1.w_stadku_od > K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;

--lista2 zad 19a
SELECT K.imie                                     "Imie",
       K.funkcja                                  "Funkcja",
       DEREF(K.szef).imie                         "Szef 1",
       DEREF(DEREF(K.szef).szef).imie             "Szef 2",
       DEREF(DEREF(DEREF(K.szef).szef).szef).imie "Szef 3"
FROM KocuryT K
WHERE K.funkcja IN ('KOT', 'MILUSIA');


--lista2 zad 19c
SELECT imie, funkcja, MAX(szefowie) "Imiona kolejnych szefow"
FROM (SELECT CONNECT_BY_ROOT (imie)                          imie,
             CONNECT_BY_ROOT (funkcja)                       funkcja,
             REPLACE(SYS_CONNECT_BY_PATH(imie, ' | '), ' | ' || CONNECT_BY_ROOT IMIE || ' ' , '') szefowie
      FROM KocuryT
      CONNECT BY prior DEREF(szef).pseudo = pseudo
      START WITH funkcja in ('KOT', 'MILUSIA'))
GROUP BY imie, funkcja;

--lista2 zad 22 --natural join laczy tabele wspolna kolumna ale zostawia tylko jedną, drugą pomija
SELECT MIN(funkcja) "Funkcja", pseudo, COUNT(pseudo) "Liczba wrogow"
FROM KocuryT
         NATURAL JOIN INCYDENTYT
GROUP BY pseudo
HAVING COUNT(pseudo) > 1;

--lista 2 zad 23
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() > 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", '864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() = 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() < 864
  AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;

--lista 3 zad 34
DECLARE
    funkcja_kocura KocuryT.funkcja%TYPE;
BEGIN
    SELECT FUNKCJA INTO funkcja_kocura
    FROM KocuryT
    WHERE FUNKCJA = UPPER('mui');
--     DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || funkcja_kocura);
EXCEPTION
    WHEN TOO_MANY_ROWS
        THEN DBMS_OUTPUT.PUT_LINE('znaleziono '|| funkcja_kocura);
    WHEN NO_DATA_FOUND
        THEN DBMS_OUTPUT.PUT_LINE('NIE znaleziono' || funkcja_kocura);
END;

--lista 3 zad37
DECLARE
    CURSOR topC IS
        SELECT K.pseudo, K.caly_przydzial() "zjada"
        FROM KocuryT K
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

--lista 3 zad 38
--TODO
DECLARE
    liczba_przelozonych     NUMBER := :liczba_przelozonych;
    max_liczba_przelozonych NUMBER;
    szerokosc_kol           NUMBER := 15;
    pseudo_aktualny         KocuryT.PSEUDO%TYPE;
    imie_aktualny           KocuryT.IMIE%TYPE;
    pseudo_nastepny         DEREF(KocuryT.SZEF).pseudo%TYPE;
    CURSOR podwladni IS SELECT PSEUDO, IMIE
                        FROM KocuryT
                        WHERE FUNKCJA IN ('MILUSIA', 'KOT');
BEGIN
    SELECT MAX(LEVEL) - 1
    INTO max_liczba_przelozonych
    FROM KocuryT
    CONNECT BY PRIOR DEREF(szef).pseudo = pseudo
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
            SELECT SZEF INTO pseudo_nastepny FROM KocuryT WHERE PSEUDO = kot.PSEUDO;
            FOR COUNTER IN 1..liczba_przelozonych
                LOOP
                    IF pseudo_nastepny IS NULL THEN
                        DBMS_OUTPUT.PUT(RPAD('|  ', szerokosc_kol));

                    ELSE
                        SELECT K.IMIE, K.PSEUDO, K.SZEF
                        INTO imie_aktualny, pseudo_aktualny, pseudo_nastepny
                        FROM KocuryT K
                        WHERE K.PSEUDO = pseudo_nastepny;
                        DBMS_OUTPUT.PUT(RPAD('|  ' || imie_aktualny, szerokosc_kol));
                    END IF;
                END LOOP;
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;
END;




--ZADANIE 49
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE MYSZY(
    nr_myszy NUMBER(7) CONSTRAINT myszy_pk PRIMARY KEY,
    lowca VARCHAR2(15) CONSTRAINT m_lowca_fk REFERENCES Kocury(pseudo),
    zjadacz VARCHAR2(15) CONSTRAINT m_zjadacz_fk REFERENCES Kocury(pseudo),
    waga_myszy NUMBER(3) CONSTRAINT waga_myszy_ogr CHECK (waga_myszy BETWEEN 10 AND 85),
    data_zlowienia DATE CONSTRAINT dat_nn NOT NULL,
    data_wydania DATE,
    CONSTRAINT daty_popr CHECK (data_zlowienia <= data_wydania))';
END;



SELECT * FROM MYSZY;

DROP TABLE Myszy;
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY-MM-DD'

CREATE SEQUENCE myszy_seq;
DROP SEQUENCE myszy_seq;

DECLARE
    data_start           DATE           := '2004-01-01';
    data_ostatniej_srody DATE           := NEXT_DAY(LAST_DAY(data_start) - 7, 'ŚRODA');
    data_koncowa         DATE           := '2023-01-18';
    myszy_mies           NUMBER(5);

    TYPE tp IS TABLE OF Kocury.pseudo%TYPE;
    tab_pseudo           tp             := tp();

    TYPE tm IS TABLE OF NUMBER(4);
    tab_myszy            tm             := tm();

    TYPE myszy_rek IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    myszki               myszy_rek;
    nr_myszy             BINARY_INTEGER := 0;
    indeks_zjadacza      NUMBER(2);

BEGIN
    LOOP
        EXIT WHEN data_start >= data_koncowa;
            IF data_start < NEXT_DAY(LAST_DAY(data_start), 'ŚRODA') - 7 THEN
                data_ostatniej_srody := LEAST(NEXT_DAY(LAST_DAY(data_start), 'ŚRODA') - 7, data_koncowa);
            ELSE
                data_ostatniej_srody :=
                        LEAST(NEXT_DAY(LAST_DAY(ADD_MONTHS(data_start, 1)), 'ŚRODA') - 7, data_koncowa);
            END IF;

            --pobranie danych w miesiacu
            SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
            INTO myszy_mies
            FROM KOCURY
            WHERE W_STADKU_OD < data_ostatniej_srody;

            --
            SELECT pseudo,
                   NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0) BULK COLLECT
            INTO tab_pseudo, tab_myszy
            FROM KOCURY
            WHERE W_STADKU_OD < data_ostatniej_srody;

            indeks_zjadacza := 1;
            myszy_mies := CEIL(myszy_mies / tab_pseudo.COUNT);

            FOR i IN 1..(myszy_mies * tab_pseudo.COUNT)
                LOOP
                    nr_myszy := nr_myszy + 1;
                    myszki(nr_myszy).NR_MYSZY := nr_myszy;
                    myszki(nr_myszy).LOWCA := tab_pseudo(MOD(i, tab_pseudo.COUNT) + 1);

                    IF data_ostatniej_srody != data_koncowa THEN
                        myszki(nr_myszy).DATA_WYDANIA := data_ostatniej_srody;

                        IF tab_myszy(indeks_zjadacza) = 0 THEN
                            indeks_zjadacza := indeks_zjadacza + 1;
                        ELSE
                            tab_myszy(indeks_zjadacza) := tab_myszy(indeks_zjadacza) - 1;
                        end if;

                        --nadwyzki
                        IF indeks_zjadacza > tab_myszy.COUNT THEN
                            indeks_zjadacza := DBMS_RANDOM.VALUE(1, tab_myszy.COUNT);
                        end if;
                        myszki(nr_myszy).zjadacz := tab_pseudo(indeks_zjadacza);
                    end if;
                    myszki(nr_myszy).waga_myszy := DBMS_RANDOM.VALUE(10,85);
                    myszki(nr_myszy).data_zlowienia := data_start + MOD(nr_myszy, TRUNC(data_ostatniej_srody) - TRUNC(data_start));
                end loop;
                data_start := data_ostatniej_srody + 1;
                data_ostatniej_srody := NEXT_DAY(LAST_DAY(ADD_MONTHS(data_start, 1)) - 7, 'ŚRODA');
            IF data_ostatniej_srody > data_koncowa THEN
                data_ostatniej_srody := data_koncowa;
            end if;
    END LOOP;

    FORALL i in 1..myszki.COUNT
        INSERT INTO Myszy(nr_myszy, lowca, zjadacz, waga_myszy, data_zlowienia, data_wydania)
        VALUES (myszy_seq.NEXTVAL, myszki(i).LOWCA, myszki(i).ZJADACZ, myszki(i).WAGA_MYSZY, myszki(i).DATA_ZLOWIENIA,
                myszki(i).DATA_WYDANIA);
END;


SELECT * FROM MYSZY;
SELECT COUNT(nr_myszy) FROM Myszy; --200k
--ostatnia środa miesiaca
SELECT  * FROM Myszy WHERE EXTRACT(MONTH FROM Data_Zlowienia)=11 AND EXTRACT(YEAR FROM DATA_ZLOWIENIA)=2021;
TRUNCATE TABLE MYSZY;

BEGIN
   FOR kot in (SELECT pseudo FROM Kocury)
    LOOP
       EXECUTE IMMEDIATE 'CREATE TABLE Myszy_kota_' || kot.pseudo || '(' ||
           'nr_myszy NUMBER(7) CONSTRAINT myszy_kota_pk_' || kot.pseudo || ' PRIMARY KEY,' ||
           'waga_myszy NUMBER(3) CONSTRAINT waga_myszy_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 10 AND 85),' ||
           'data_zlowienia DATE CONSTRAINT data_zlowienia_nn_' || kot.pseudo ||' NOT NULL)' ;
       END LOOP;
END;

BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury)
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE Myszy_kota_' || kot.pseudo;
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE przyjmij_na_stan(kotPseudo Kocury.pseudo%TYPE, data_zlowienia DATE)
AS
    TYPE tw IS TABLE OF NUMBER(3);
        tab_wagi tw := tw();
    TYPE tn IS TABLE OF NUMBER(7);
        tab_nr tn := tn();
    ile_kotow NUMBER(2);
    nie_ma_kota EXCEPTION;
    zla_data EXCEPTION;
BEGIN
    IF data_zlowienia > SYSDATE THEN RAISE zla_data; END IF;

    SELECT COUNT(K.pseudo) INTO ile_kotow FROM KOCURY K  WHERE K.pseudo = UPPER(kotPseudo);
    IF ile_kotow = 0 THEN RAISE nie_ma_kota; END IF;

    DBMS_OUTPUT.PUT_LINE('test1');
    EXECUTE IMMEDIATE 'SELECT nr_myszy, waga_myszy FROM Myszy_kota_'|| kotPseudo || ' WHERE data_zlowienia= ''' || data_zlowienia || ''''
        BULK COLLECT INTO tab_nr, tab_wagi;

    DBMS_OUTPUT.PUT_LINE('test2');
    FORALL i in 1..tab_nr.COUNT
        INSERT INTO Myszy VALUES (tab_nr(i), UPPER(kotPseudo), NULL, tab_wagi(i),DATA_ZLOWIENIA, NULL);

    DBMS_OUTPUT.PUT_LINE('test3');
    EXECUTE IMMEDIATE 'DELETE FROM Myszy_kota_' || kotPseudo || ' WHERE data_zlowienia= ''' || data_zlowienia || '''';
    DBMS_OUTPUT.PUT_LINE('test4');
    EXCEPTION
        WHEN nie_ma_kota THEN DBMS_OUTPUT.PUT_LINE('BRAK KOTA O PSEUDONIMIE Myszy_kota_'|| UPPER(kotPseudo));
        WHEN zla_data THEN DBMS_OUTPUT.PUT_LINE('ZLA DATA');
END;

CREATE OR REPLACE PROCEDURE Wyplata
AS
    TYPE tp IS TABLE OF Kocury.pseudo%TYPE;
        tab_pseudo tp := tp();
    TYPE tm is TABLE OF NUMBER(4);
        tab_myszy tm := tm();
    TYPE tn IS TABLE OF NUMBER(7);
        tab_nr tn := tn();
    data_wyplaty DATE := NEXT_DAY(LAST_DAY(SYSDATE)-7, 'ŚRODA');
    TYPE tz IS TABLE OF Kocury.pseudo%TYPE INDEX BY BINARY_INTEGER;
        tab_zjadaczy tz;
    TYPE tw IS TABLE OF Myszy%ROWTYPE;
        tab_wierszy tw;
    liczba_najedzonych NUMBER(2) := 0;
    indeks_zjadacza NUMBER(2) := 1;
BEGIN
    --wedlug hierarchi
    SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO tab_pseudo, tab_myszy
    FROM Kocury CONNECT BY PRIOR pseudo = szef
    START WITH SZEF IS NULL
    ORDER BY level;

    SELECT nr_myszy
        BULK COLLECT INTO tab_nr
    FROM Myszy
    WHERE DATA_WYDANIA IS NULL;

    FOR i IN 1..tab_nr.COUNT
        LOOP
            WHILE tab_myszy(indeks_zjadacza) = 0 AND liczba_najedzonych < tab_pseudo.COUNT
                LOOP
                    liczba_najedzonych := liczba_najedzonych + 1;
                    indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                END LOOP;
            --jezeli wszyscy juz dostali to daj szefowi nad szefami
            IF liczba_najedzonych = tab_pseudo.COUNT THEN
                tab_zjadaczy(i) := 'TYGRYS';
            ELSE
                indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                tab_zjadaczy(i) := tab_pseudo(indeks_zjadacza);
                tab_myszy(indeks_zjadacza) := tab_myszy(indeks_zjadacza) - 1;
            end if;
        END LOOP;
    FORALL i IN 1..tab_nr.COUNT
        EXECUTE IMMEDIATE 'UPDATE Myszy SET data_wydania=''' || data_wyplaty || ''', zjadacz=:ps
        WHERE nr_myszy=:nr'
        USING tab_zjadaczy(i), tab_nr(i);
END;

-- wow this works
CREATE OR REPLACE PROCEDURE Wyplata2
AS
    TYPE tp IS TABLE OF Kocury.pseudo%TYPE;
        tab_pseudo tp := tp();
    TYPE tm is TABLE OF NUMBER(4);
        tab_myszy tm := tm();
    TYPE tn IS TABLE OF NUMBER(7);
        tab_nr tn := tn();
    TYPE tz IS TABLE OF Kocury.pseudo%TYPE INDEX BY BINARY_INTEGER;
        tab_zjadaczy tz;
    TYPE tw IS TABLE OF Myszy%ROWTYPE;
        tab_wierszy tw;
    liczba_najedzonych NUMBER(2) := 0;
    indeks_zjadacza NUMBER(2) := 1;
BEGIN
    --wedlug hierarchi
    SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO tab_pseudo, tab_myszy
    FROM Kocury CONNECT BY PRIOR pseudo = szef
    START WITH SZEF IS NULL
    ORDER BY level;

    SELECT *
        BULK COLLECT INTO tab_wierszy
    FROM Myszy
    WHERE DATA_WYDANIA IS NULL;

    FOR i IN 1..tab_wierszy.COUNT
        LOOP
            WHILE tab_myszy(indeks_zjadacza) = 0 AND liczba_najedzonych < tab_pseudo.COUNT
                LOOP
                    liczba_najedzonych := liczba_najedzonych + 1;
                    indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                END LOOP;
            --jezeli wszyscy juz dostali to daj szefowi nad szefami
            IF liczba_najedzonych = tab_pseudo.COUNT THEN
                tab_zjadaczy(i) := 'TYGRYS';
            ELSE
                indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                tab_zjadaczy(i) := tab_pseudo(indeks_zjadacza);
                tab_myszy(indeks_zjadacza) := tab_myszy(indeks_zjadacza) - 1;
            end if;
        END LOOP;
    FORALL i IN 1..tab_wierszy.COUNT
            UPDATE Myszy SET data_wydania=NEXT_DAY(LAST_DAY(tab_wierszy(i).DATA_ZLOWIENIA)-7, 'ŚRODA'), zjadacz=tab_zjadaczy(i)
            WHERE nr_myszy=tab_wierszy(i).NR_MYSZY;
END;


BEGIN
    Wyplata();
END;

BEGIN
    Wyplata2();
END;

INSERT INTO Myszy_kota_DAMA VALUES(myszy_seq.nextval, 60, '2022-12-19');

INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 69, '2022-12-27');
BEGIN
    przyjmij_na_stan('Dama', '2022-12-19');
end;

BEGIN
    przyjmij_na_stan('TYGRYS', '2022-12-27');
end;

SELECT * FROM MYSZY_KOTA_TYGRYS;

SELECT * FROM Myszy_kota_Dama;
SELECT COUNT(*) FROM Myszy WHERE EXTRACT(YEAR FROM data_wydania)=2022 AND zjadacz!='TYGRYS';

SELECT * FROM Myszy WHERE data_wydania IS NULL;
SELECT * FROM MYSZY WHERE NR_MYSZY = 216321;

SELECT * FROM MYSZY WHERE NR_MYSZY = 216361;
SELECT * FROM MYSZY_KOTA_TYGRYS;





--TODO znajdz ostatnią srode miesiaca w miesiacy zlowienia myszy i w wyplacie trzymaj sie tej daty ostatniej srody.

-- koty podzielone na dwie czesci, blokady trigger done
-- nie wszystkie koty poluja od 2004 i nie mogą brac udziału przed 2004
-- wypłata w ostatnioą środę (uniemożliwić wypłatę)
-- wybierec te zadania które mają złączenia (ref) i metody w typach
-- zapytania o dodatkowe relacje

--zadanie 3 wydajnosc kiladziesiat tysiecy krotek w 2 sekundy 5-7 sekund tez okey.
-- bulk przygotowac i raz wysłać do serwera

