--zad47
CREATE OR REPLACE TYPE KocuryO AS OBJECT (
    imie VARCHAR2(15),
    plec VARCHAR2(1),
    pseudo VARCHAR2(15),
    funkcja VARCHAR2(10),
    szef VARCHAR2(15),
    w_stadku_od DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2)
                                        --jakie przykładowe funkcje zobiektowiena kocura?
                                         );

ROLLBACK;

CREATE OR REPLACE TYPE BODY KocuryO
    AS MEMBER FUNCTION cos RETURN NUMBER
    IS
    BEGIN
        RETURN 1;
    END;
END;



CREATE TABLE KocuryT OF KocuryO (
  imie CONSTRAINT ko_i_nn NOT NULL,
  plec CONSTRAINT ko_p_ch CHECK(plec IN ('M', 'D')),
  pseudo CONSTRAINT ko_ps_pk PRIMARY KEY,
  funkcja CONSTRAINT ko_f_fk REFERENCES Funkcje(funkcja),
  szef SCOPE IS KocuryO,
  w_stadku_od DEFAULT SYSDATE,
  nr_bandy CONSTRAINT ko_nr_fk REFERENCES Bandy(nr_bandy)
);

--plebs
CREATE OR REPLACE TYPE PlebsO AS OBJECT (
    kot REF KocuryO,
    MEMBER FUNCTION get_details RETURN VARCHAR2
                                        );


CREATE OR REPLACE TYPE BODY PlebsO
    AS MEMBER FUNCTION get_details RETURN VARCHAR2
    IS
        details VARCHAR2(400);
    BEGIN
        SELECT 'IMIE: ' || DEREF(kot).imie || ' PSEUDO ' || DEREF(kot).pseudo INTO details FROM dual;
        RETURN details;
    END;
END;



--elita
CREATE OR REPLACE TYPE ElitaO AS OBJECT (
    id INTEGER,
    kocur REF KocuryO,
    slugus REF PlebsO,
    MEMBER FUNCTION get_sluga RETURN REF PlebsO
                                        );

CREATE OR REPLACE TYPE BODY ElitaO AS
  MEMBER FUNCTION get_sluga RETURN REF PlebsO IS
    BEGIN
      RETURN slugus;
    END;
END;

--incydenty

--dane wprowadzenia myszy
