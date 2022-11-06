INSERT ALL
INTO Funkcje VALUES('SZEFUNIO',90,110)
INTO Funkcje VALUES('BANDZIOR',70,90)
INTO Funkcje VALUES('LOWCZY',60,70)
INTO Funkcje VALUES('LAPACZ',50,60)
INTO Funkcje VALUES('KOT',40,50)
INTO Funkcje VALUES('MILUSIA',20,30)
INTO Funkcje VALUES('DZIELCZY',45,55)
INTO Funkcje VALUES('HONOROWA',6,25)
SELECT * FROM Dual;

COMMIT;

ALTER TABLE Kocury DISABLE CONSTRAINT ko_nr_ba_fk;
ALTER TABLE Kocury DISABLE CONSTRAINT ko_sz_fk;

INSERT ALL
INTO Kocury VALUES ('JACEK','M','PLACEK','LOWCZY','LYSY','2008-12-01',67,NULL,2)
INTO Kocury VALUES ('BARI','M','RURA','LAPACZ','LYSY','2009-09-01',56,NULL,2)
INTO Kocury VALUES ('MICKA','D','LOLA','MILUSIA','TYGRYS','2009-10-14',25,47,1)
INTO Kocury VALUES ('LUCEK','M','ZERO','KOT','KURKA','2010-03-01',43,NULL,3)
INTO Kocury VALUES ('SONIA','D','PUSZYSTA','MILUSIA','ZOMBI','2010-11-18',20,35,3)
INTO Kocury VALUES ('LATKA','D','UCHO','KOT','RAFA','2011-01-01',40,NULL,4)
INTO Kocury VALUES ('DUDEK','M','MALY','KOT','RAFA','2011-05-15',40,NULL,4)
INTO Kocury VALUES ('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1)
INTO Kocury VALUES ('CHYTRY','M','BOLEK','DZIELCZY','TYGRYS','2002-05-05',50,NULL,1)
INTO Kocury VALUES ('KOREK','M','ZOMBI','BANDZIOR','TYGRYS','2004-03-16',75,13,3)
INTO Kocury VALUES ('BOLEK','M','LYSY','BANDZIOR','TYGRYS','2006-08-15',72,21,2)
INTO Kocury VALUES ('ZUZIA','D','SZYBKA','LOWCZY','LYSY','2006-07-21',65,NULL,2)
INTO Kocury VALUES ('RUDA','D','MALA','MILUSIA','TYGRYS','2006-09-17',22,42,1)
INTO Kocury VALUES ('PUCEK','M','RAFA','LOWCZY','TYGRYS','2006-10-15',65,NULL,4)
INTO Kocury VALUES ('PUNIA','D','KURKA','LOWCZY','ZOMBI','2008-01-01',61,NULL,3)
INTO Kocury VALUES ('BELA','D','LASKA','MILUSIA','LYSY','2008-02-01',24,28,2)
INTO Kocury VALUES ('KSAWERY','M','MAN','LAPACZ','RAFA','2008-07-12',51,NULL,4)
INTO Kocury VALUES ('MELA','D','DAMA','LAPACZ','RAFA','2008-11-01',51,NULL,4)
SELECT * FROM dual;

ALTER TABLE Kocury ENABLE CONSTRAINT ko_sz_fk;

ALTER TABLE Bandy DISABLE CONSTRAINT ba_sz_fk;

INSERT ALL
INTO Bandy VALUES (1,'SZEFOSTWO','CALOSC','TYGRYS')
INTO Bandy VALUES (2,'CZARNI RYCERZE','POLE','LYSY')
INTO Bandy VALUES (3,'BIALI LOWCY','SAD','ZOMBI')
INTO Bandy VALUES (4,'LACIACI MYSLIWI','GORKA','RAFA')
INTO Bandy VALUES (5,'ROCKERSI','ZAGRODA',NULL)
SELECT * FROM dual;

ALTER TABLE Bandy ENABLE CONSTRAINT ba_sz_fk;
ALTER TABLE Kocury ENABLE CONSTRAINT ko_nr_ba_fk;

COMMIT;

INSERT ALL
INTO Wrogowie VALUES('KAZIO',10,'CZLOWIEK','FLASZKA')
INTO Wrogowie VALUES('GLUPIA ZOSKA',1,'CZLOWIEK','KORALIK')
INTO Wrogowie VALUES('SWAWOLNY DYZIO',7,'CZLOWIEK','GUMA DO ZUCIA')
INTO Wrogowie VALUES('BUREK',4,'PIES','KOSC')
INTO Wrogowie VALUES('DZIKI BILL',10,'PIES',NULL)
INTO Wrogowie VALUES('REKSIO',2,'PIES','KOSC')
INTO Wrogowie VALUES('BETHOVEN',1,'PIES','PEDIGRIPALL')
INTO Wrogowie VALUES('CHYTRUSEK',5,'LIS','KURCZAK')
INTO Wrogowie VALUES('SMUKLA',1,'SOSNA',NULL)
INTO Wrogowie VALUES('BAZYLI',3,'KOGUT','KURA DO STADA')
SELECT * FROM dual;

COMMIT;


INSERT ALL
INTO Wrogowie_kocurow VALUES('TYGRYS','KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY')
INTO Wrogowie_kocurow VALUES('ZOMBI','SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY')
INTO Wrogowie_kocurow VALUES('BOLEK','KAZIO','2005-03-29','POSZCZUL BURKIEM')
INTO Wrogowie_kocurow VALUES('SZYBKA','GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI')
INTO Wrogowie_kocurow VALUES('MALA','CHYTRUSEK','2007-03-07','ZALECAL SIE')
INTO Wrogowie_kocurow VALUES('TYGRYS','DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA')
INTO Wrogowie_kocurow VALUES('BOLEK','DZIKI BILL','2007-11-10','ODGRYZL UCHO')
INTO Wrogowie_kocurow VALUES('LASKA','DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA')
INTO Wrogowie_kocurow VALUES('LASKA','KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK')
INTO Wrogowie_kocurow VALUES('DAMA','KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY')
INTO Wrogowie_kocurow VALUES('MAN','REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL')
INTO Wrogowie_kocurow VALUES('LYSY','BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA')
INTO Wrogowie_kocurow VALUES('RURA','DZIKI BILL','2009-09-03','ODGRYZL OGON')
INTO Wrogowie_kocurow VALUES('PLACEK','BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA')
INTO Wrogowie_kocurow VALUES('PUSZYSTA','SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI')
INTO Wrogowie_kocurow VALUES('KURKA','BUREK','2010-12-14','POGONIL')
INTO Wrogowie_kocurow VALUES('MALY','CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA')
INTO Wrogowie_kocurow VALUES('UCHO','SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI')
SELECT * FROM dual;

COMMIT;


ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

COMMIT;
