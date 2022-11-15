--34
DECLARE
    funkcja_kocura KOCURY.funkcja%TYPE;
    ile_przetworzono NUMBER;
BEGIN
    SELECT COUNT(PSEUDO), MIN(FUNKCJA) INTO ile_przetworzono, funkcja_kocura
    FROM KOCURY
    WHERE FUNKCJA = UPPER('&nazwa_funkcji');
    IF ile_przetworzono > 0 THEN DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || funkcja_kocura);
    ELSE DBMS_OUTPUT.PUT_LINE('Nie znaleziono');
    END IF;
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
    
    IF pzydzial_kocura > 700 THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
        znaleziony:=TRUE;
    END IF;
    
    IF imie_kocura LIKE '%A%'THEN DBMS_OUTPUT.PUT_LINE('imiê zawiera litere A');
        znaleziony:=TRUE;
    END IF;
    IF miesiac_kocura = 11 THEN DBMS_OUTPUT.PUT_LINE('listopad jest miesiacem przystapienia do stada');
        znaleziony:=TRUE;
    END IF;
    IF NOT znaleziony THEN DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('BRAK TAKIEGO KOTA');
END;

--zad36 TODO


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


