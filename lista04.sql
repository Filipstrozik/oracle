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
--GRUPOWANIE
SELECT K.funkcja, COUNT(K.pseudo) as koty_w_funkcji FROM KocuryT K GROUP BY K.funkcja;

SELECT DEREF(kot).pseudo "Kot", count(slugus) "Sługa"
FROM ElitaT E
GROUP BY DEREF(kot).pseudo;

SELECT E.kot.pseudo, E.kot.caly_przydzial()
FROM KocuryT K JOIN ElitaT E  ON E.kot = REF(K);

SELECT REF(T). FROM PlebsT T WHERE T.kot.plec = 'M';

-- koty podzielone na dwie czesci, blokady trigger done
-- nie wszystkie koty poluja od 2004 i nie mogą brac udziału przed 2004
-- wypłata w ostatnioą środę (uniemożliwić wypłatę)
-- wybierec te zadania które mają złączenia (ref) i metody w typach
-- zapytania o dodatkowe relacje

--zadanie 3 wydajnosc kiladziesiat tysiecy krotek w 2 sekundy 5-7 sekund tez okey.
-- bulk przygotowac i raz wysłać do serwera

