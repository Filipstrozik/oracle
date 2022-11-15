--zad34

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

DECLARE
    funkcja_kocura KOCURY.funkcja%TYPE;
    ile_przetworzono NUMBER;
BEGIN
    SELECT COUNT(PSEUDO), MIN(FUNKCJA) INTO ile_przetworzono, funkcja_kocura
    FROM KOCURY
    WHERE FUNKCJA = UPPER($(nazwa_funkcji));
    IF ile_przetworzono > 0 THEN DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || funkcja_kocura);
    ELSE DBMS_OUTPUT.PUT_LINE('Nie znaleziono');
    END IF;
END;

SELECT * FROM Kocury;


begin
  dbms_output.put_line('test');
end;