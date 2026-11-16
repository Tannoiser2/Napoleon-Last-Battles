# Napoleon at War: ordini di battaglia, schieramenti e rinforzi dei quattro giochi (dalle regole esclusive SPI 1975)
# -> assets/dati/naw.json (catalogo + scenari) e assets/naw/pedine/<id>.webp (pedine disegnate nello stile del modulo)
import json,os,re,numpy as np
from PIL import Image,ImageDraw,ImageFont
R='/home/claude/napoleon-last-battles'
# voce: (esercito, sigla, nome, "forza-mov[c|a]", posto)
# posto: "0608" esagono iniziale | ("T",turno,"esagono"[,extra]) rinforzo | ("Z","area") schieramento libero
MARENGO=[
 ('FR','44','44a mezza brigata','4-4','1111'),('FR','101','101a mezza brigata','2-4','1110'),
 ('FR','24','24a leggera','5-5','1312'),('FR','43','43a mezza brigata','5-4','1412'),('FR','96','96a mezza brigata','4-4','1411'),
 ('FR','69','6a leggera (Watrin)','4-5','2310'),('FR','28','28a mezza brigata','2-4','2311'),('FR','22','22a mezza brigata','3-4','2409'),
 ('FR','40','40a mezza brigata','4-4','2410'),('FR','Cham','Champeaux','2-6c','1808'),('FR','Kell','Kellermann','2-7c','1215'),
 ('FR','DuVi','Du Vigneau','2-6c','1115'),('FR','AdGd','Art. avanguardia','2-4a','2211'),('FR','Vict','Art. Victor','2-4a','1513'),
 ('FR','Res','Art. riserva','2-4a','2715'),('FR','Gd','Cav. Guardia consolare','2-7c','3213'),
 ('FR','CnGd','Guardia consolare','3-4',('T',2,'3912')),
 ('FR','19','19a leggera (Monnier)','4-5',('T',4,'3912')),('FR','70','70a mezza brigata','3-4',('T',4,'3912')),('FR','72','72a mezza brigata','4-4',('T',4,'3912')),
 ('FR','DeSa','Art. Desaix','2-4a',('T',5,'3912')),
 ('FR','9','9a leggera (Boudet)','5-5',('T',6,'3925')),('FR','30','30a mezza brigata','2-4',('T',6,'3925')),('FR','59','59a mezza brigata','4-4',('T',6,'3925')),
 ('FR','Mura','Murat','2-7c',('T',8,'2401')),('FR','DuMo','Dumoulin','1-7c',('T',8,'2501')),('FR','Cav','Art. a cavallo','2-6a',('T',8,'2301')),
 ('FR','Riva','Rivaud','2-6c',('T',9,'3301')),
 ('AU','Rous','Rousseau','6-3','0608'),('AU','Frim','Frimont','3-5','0708'),('AU','Bell','Bellegarde','3-3','0508'),('AU','StJu','St. Julien','5-3','0507'),
 ('AU','Knes','Knesevich','5-3','0406'),('AU','Lama','La Marsaille','2-3','0407'),('AU','DeBe','De Briey','4-3','0408'),('AU','Latt','Lattermann','7-3','0308'),
 ('AU','Weie','Weidenfeld','7-3','0307'),('AU','Gott','Gottesheim','2-3','0404'),('AU','Stic','Sticker','4-3','0206'),('AU','Retz','Retz','4-3','0105'),
 ('AU','Ulm','Ulm','5-3','0106'),('AU','Pion','Pionieri','1-3','0906'),('AU','ORei',"O'Reilly",'2-5c','0509'),('AU','AvGd','Cav. avanguardia','1-5c','0607'),
 ('AU','Pila','Pilati','4-7c','0606'),('AU','Nobl','Nobili','4-5c','0506'),('AU','Nimp','Nimptsch','5-5c','0505'),('AU','Voge','Vogelsang','1-5c','0405'),
 ('AU','Sche','Schellenberg','1-5c','0207'),('AU','AdGd','Art. avanguardia','2-3a','0707'),('AU','Main','Art. corpo principale','3-3a','0309'),
 ('AU','LCol','Art. colonna sinistra','4-3a','0205'),('AU','RCol','Art. colonna destra','3-3a','0305'),
]
WAGRAM=[
 ('FR','Mora','Morand','6-4',('Z','0524',3)),('FR','Fria','Friant','6-4',('Z','0524',3)),('FR','Gudi','Gudin','6-4',('Z','0524',3)),
 ('FR','Gran','Grandjean','6-4',('Z','0524',3)),('FR','Demo','Demont','6-4',('Z','0524',3)),('FR','Grou','Grouchy','2-6c',('Z','0524',3)),
 ('FR','Mont','Montbrun','2-6c',('Z','0524',3)),('FR','Pull','Pully','1-6c',('Z','0524',3)),('FR','1/III','Art. III corpo','6-4a',('Z','0524',3)),
 ('FR','2/III','Art. III corpo','6-4a',('Z','0524',3)),
 ('FR','Clap','Claparède','9-4',('Z','1320',1)),('FR','Thar','Tharreau','9-4',('Z','1320',1)),('FR','Colb','Colbert','1-6c',('Z','1320',1)),('FR','II','Art. II corpo','8-4a',('Z','1320',1)),
 ('FR','DHil',"D'Hilliers",'8-4',('Z','1417',2)),('FR','Brou','Broussier','4-4',('Z','1417',2)),('FR','Lecc','Lecchi','4-4',('Z','1417',2)),
 ('FR','Pact','Pacthod','4-4',('Z','1417',2)),('FR','1/Ital','Art. Armata d\'Italia','6-4a',('Z','1417',2)),('FR','2/Ital','Art. Armata d\'Italia','6-4a',('Z','1417',2)),
 ('FR','Gera','Gérard','1-6c',('Z','1417',2)),
 ('FR','OlGd','Vecchia Guardia','5-4',('Z','0517',1)),('FR','YoGd','Giovane Guardia','3-4',('Z','0517',1)),('FR','Gd','Cav. Guardia','4-6c',('Z','0517',1)),
 ('FR','GdA','Art. Guardia','10-4a',('Z','0517',1)),
 ('FR','Dupa','Dupas','8-4',('Z','0514',1)),('FR','Sax','Sassoni','8-4',('Z','0514',1)),('FR','IX','Cav. IX corpo','2-6c',('Z','0514',1)),('FR','IXA','Art. IX corpo','6-4a',('Z','0514',1)),
 ('FR','Legr','Legrand','6-4',('Z','0714',2)),('FR','Boud','Boudet','6-4',('Z','0714',2)),('FR','StCy','St. Cyr','6-4',('Z','0714',2)),('FR','Moli','Molitor','6-4',('Z','0714',2)),
 ('FR','LaSa','Lasalle','3-6c',('Z','0714',2)),('FR','1/IV','Art. IV corpo','8-4a',('Z','0714',2)),('FR','2/IV','Art. IV corpo','8-4a',('Z','0714',2)),
 ('FR','Marm','Marmont','9-4',('Z','lobau',0)),('FR','Reyn','Reynier','6-4',('Z','lobau',0)),('FR','Wred','Wrede','5-4',('Z','lobau',0)),
 ('FR','Res','Cav. riserva','6-6c',('Z','lobau',0)),('FR','1/Res','Art. di Lobau','10-1a',('Z','lobau',0)),('FR','2/Res','Art. di Lobau','10-1a',('Z','lobau',0)),
 ('FR','3/Res','Art. di Lobau','10-1a',('Z','lobau',0)),
 ('AU','1/AG','Avanguardia (1a div.)','6-4','1926'),('AU','2/AG','Avanguardia (2a div.)','6-4','2025'),('AU','1/AGc','Cav. avanguardia','1-6c','1233'),
 ('AU','2/AGc','Cav. avanguardia','2-6c','1628'),('AU','AG','Art. avanguardia','6-4a','2026'),
 ('AU','1/II','II corpo (1a div.)','9-4','2220'),('AU','2/II','II corpo (2a div.)','8-4','2123'),('AU','3/II','II corpo (3a div.)','8-4','2124'),
 ('AU','IIc','Cav. II corpo','1-6c','2323'),('AU','IIa','Art. II corpo','9-4a','2322'),
 ('AU','1/I','I corpo (1a div.)','7-4','2417'),('AU','2/I','I corpo (2a div.)','7-4','2517'),('AU','3/I','I corpo (3a div.)','6-4','2319'),('AU','Ia','Art. I corpo','9-4a','2519'),
 ('AU','1/IV','IV corpo (1a div.)','6-4','2223'),('AU','2/IV','IV corpo (2a div.)','6-4','2224'),('AU','3/IV','IV corpo (3a div.)','6-4','2225'),
 ('AU','IVc','Cav. IV corpo','1-6c','2325'),('AU','IVa','Art. IV corpo','9-4a','2326'),
 ('AU','1/VI','VI corpo (1a div.)','6-4','2301'),('AU','2/VI','VI corpo (2a div.)','6-4','2202'),('AU','3/VI','VI corpo (3a div.)','5-4','2201'),
 ('AU','VIc','Cav. VI corpo','2-6c','2302'),('AU','VIa','Art. VI corpo','9-4a','2401'),
 ('AU','1/Res','Riserva (1a div.)','6-4','2908'),('AU','2/Res','Riserva (2a div.)','6-4','2407'),('AU','1/Resc','Cav. riserva (1a)','3-6c','2710'),
 ('AU','2/Resc','Cav. riserva (2a)','3-6c','2712'),('AU','3/Resc','Cav. riserva (3a)','3-6c','2913'),('AU','ResA','Art. riserva','6-4a','2405'),
 ('AU','1/III','III corpo (1a div.)','6-4',('T',3,'ovest')),('AU','2/III','III corpo (2a div.)','6-4',('T',3,'ovest')),
 ('AU','3/III','III corpo (3a div.)','5-4',('T',3,'ovest')),('AU','IIIa','Art. III corpo','8-4a',('T',3,'ovest')),
 ('AU','1/SR','Arciduca Giovanni (1a div.)','6-4',('T',99,'giovanni')),('AU','2/SR','Arciduca Giovanni (2a div.)','6-4',('T',99,'giovanni')),
 ('AU','3/SR','Arciduca Giovanni (3a div.)','6-4',('T',99,'giovanni')),('AU','SRc','Cav. Arciduca Giovanni','5-6c',('T',99,'giovanni')),
 ('AU','SRa','Art. Arciduca Giovanni','7-4a',('T',99,'giovanni')),
]
# Battle of Nations: (esercito, sigla, nome, forza, primo giorno, terzo giorno)
NAZIONI=[
 ('FR','4','4a div. (II, Victor)','8-4','2315','1914'),('FR','5','5a div. (II)','8-4','2314','2015'),('FR','6','6a div. (II)','8-4','2313','2016'),
 ('FR','8','8a div. (III, Ney)','8-4','0518','1214'),('FR','11','11a div. (III)','7-4','0614','1315'),('FR','12','12a div. (IV, Bertrand)','4-4','0917','1726'),
 ('FR','15','15a div. (IV)','5-4','0817','1725'),('FR','38','38a div. (IV)','4-4','0717','1624'),('FR','10','10a div. (V, Lauriston)','7-4','2312','1812'),
 ('FR','16','16a div. (V)','7-4','2311','1813'),('FR','19','19a div. (V)','7-4','2210','1814'),('FR','20','20a div. (VI, Marmont)','11-4','0819','1013'),
 ('FR','21','21a div. (VI)','11-4','0921','x'),('FR','22','22a div. (VI)','11-4','1018','1014'),('FR','26','26a div. (VIII, Poniatowski)','8-4','2316','x'),
 ('FR','27','27a div. (VIII)','6-4','0310','1918'),('FR','51','51a div. (IX, Augereau)','5-4','1712','1716'),('FR','52','52a div. (IX)','5-4','1811','1816'),
 ('FR','53','53a div. (IX)','5-4','1810','1817'),('FR','31','31a div. (XI, Macdonald)','8-4','0809','1609'),('FR','35','35a div. (XI)','8-4','0709','1610'),
 ('FR','36','36a div. (XI)','7-4','0708','1710'),('FR','39','39a div. (XI)','7-4','0607','1811'),('FR','Prov1','Div. provvisoria','6-4','1522','1125'),
 ('FR','Prov2','Div. provvisoria','4-4','1918','x'),('FR','1Gd','1a div. Vecchia Guardia','15-4','1715','1615'),('FR','2Gd','2a div. Vecchia Guardia','15-4','1714','1715'),
 ('FR','1YGd','1a div. Giovane Guardia','16-4','1913','1421'),('FR','2YGd','2a div. Giovane Guardia','15-4','1813','1714'),('FR','3YGd','3a div. Giovane Guardia','15-4','1914','1521'),
 ('FR','4YGd','4a div. Giovane Guardia','16-4','1814','1614'),('FR','Gd','Cav. della Guardia','8-6c','1713','1713'),('FR','I','I corpo di cavalleria','6-6c','1915','1613'),
 ('FR','II','II corpo di cavalleria','4-6c','0507','1410'),('FR','III','III corpo di cavalleria','5-6c','1322','1216'),('FR','IV','IV corpo di cavalleria','3-6c','2115','1717'),
 ('FR','V','V corpo di cavalleria','5-6c','2012','x'),
 ('FR','9','9a div. (III)','8-4',('T',5,'0117'),'1215'),('FR','32','32a div. (VII, Reynier)','8-4',('T',7,'0117'),'1217'),
 ('FR','24','24a div. (VII)','7-4',('T',7,'0117'),'1113'),('FR','14','14a div. (VII)','7-4',('T',7,'0117'),'1212'),
 ('PR','AvGd','Avanguardia (Yorck)','8-4','0529','x'),('PR','1','1a brig. (Yorck)','8-4','0429','0918'),('PR','2','2a brig. (Yorck)','5-4','0330','0817'),
 ('PR','7','7a brig. (Yorck)','8-4','0230','0919'),('PR','8','8a brig. (Yorck)','6-4','0131','0921'),('PR','9','9a brig. (Kleist)','10-4','2516','2612'),
 ('PR','10','10a brig. (Kleist)','10-4','2515','2613'),('PR','11','11a brig. (Kleist)','10-4','2615','2614'),('PR','12','12a brig. (Kleist)','10-4','2614','2615'),
 ('PR','3','3a brig. (Bülow)','12-4',('T',12,'0103'),'0607'),('PR','4','4a brig. (Bülow)','11-4',('T',12,'0103'),'0507'),
 ('PR','5','5a brig. (Bülow)','12-4',('T',12,'0103'),'0406'),('PR','6','6a brig. (Bülow)','11-4',('T',12,'0103'),'0405'),
 ('PR','1c','Cav. (Bülow)','4-6c',('T',12,'0103'),'0809'),('PR','1Gd','Guardia prussiana','8-4',('T',3,'2915'),'2611'),
 ('AU','1/II','II corpo (Merveldt)','8-4','2720','2317'),('AU','2/II','II corpo (Merveldt)','12-4','2619','x'),('AU','2/III','III corpo (Gyulai)','9-4','2029','2422'),
 ('AU','3/III','III corpo (Gyulai)','9-4','2030','2424'),('AU','2/IV','IV corpo (Klenau)','12-4','2605','2306'),('AU','3/IV','IV corpo (Klenau)','12-4','2504','2406'),
 ('AU','Gren','Granatieri (Hessen-Homburg)','12-4','2820','2318'),('AU','DioB','Div. Bianchi','12-4','2920','2319'),('AU','Res','Cav. di riserva','5-6c','2303','2003'),
 ('AU','1Gr','1a div. granatieri','12-4','2912','2510'),('AU','2Gr','2a div. granatieri','12-4','2913','2509'),('AU','Pahl','Pahlen','6-6c','2511','2609'),
 ('AU','2/I','I corpo (Colloredo)','10-4',('T',11,'2901'),'2105'),('AU','3/I','I corpo (Colloredo)','10-4',('T',11,'2901'),'2205'),
 ('RU','5','5a div. (Gortschakov)','6-4','2710','2507'),('RU','14','14a div. (Gortschakov)','5-4','2709','x'),('RU','3','3a div. (Eugenio)','6-4','2514','2508'),
 ('RU','4','4a div. (Eugenio)','6-4','2513','x'),
 ('RU','10','10a div. (Sacken)','7-4',('T',1,'0131'),'1119'),('RU','25','25a div. (Sacken)','7-4',('T',1,'0131'),'1018'),('RU','Sack','Cav. Sacken','6-6c',('T',1,'0131'),'1019'),
 ('RU','7','7a div. (Langeron)','7-4',('T',3,'0125'),'0717'),('RU','18','18a div. (Langeron)','5-4',('T',3,'0125'),'x'),('RU','9','9a div. (Langeron)','5-4',('T',3,'0125'),'0715'),
 ('RU','15','15a div. (Langeron)','6-4',('T',3,'0125'),'0716'),('RU','8','8a div. (Langeron)','6-4',('T',3,'0125'),'0615'),('RU','22','22a div. (Langeron)','7-4',('T',3,'0125'),'0616'),
 ('RU','11','11a div. (St. Priest)','8-4',('T',3,'0125'),'0718'),('RU','17','17a div. (St. Priest)','9-4',('T',3,'0125'),'0617'),('RU','StPr','Cav. St. Priest','6-6c',('T',3,'0125'),'0518'),
 ('RU','1Gd','1a div. Guardia russa','11-4',('T',3,'2915'),'2511'),('RU','2Gd','2a div. Guardia russa','11-4',('T',3,'2915'),'2512'),
 ('RU','16','16a div. (Bennigsen)','12-4',('T',12,'2901'),'2506'),('RU','13','13a div. (Bennigsen)','9-4',('T',12,'2901'),'2505'),
 ('RU','12','12a div. (Dochtorov)','14-4',('T',12,'2901'),'2604'),('RU','6','6a div. (Dochtorov)','14-4',('T',12,'2901'),'2603'),
 ('RU','21','21a div. (Winzingerode)','8-4',('T',12,'0103'),'0409'),('RU','24','24a div. (Winzingerode)','7-4',('T',12,'0103'),'0309'),
 ('RU','26','26a div. (Winzingerode)','7-4',('T',12,'0103'),'0308'),('RU','27','27a div. (Winzingerode)','7-4',('T',12,'0103'),'0207'),
 ('SV','1','1a div. svedese','9-4',('T',12,'0117'),'0314'),('SV','2','2a div. svedese','8-4',('T',12,'0117'),'0315'),('SV','3','3a div. svedese','8-4',('T',12,'0117'),'0215'),
]
# Jena-Auerstadt: posto anche ("A"/"B", turno, esagono) per i rinforzi prussiani che dipendono dall'opzione
JENA=[
 ('PR','1/Tau','Tauentzien (1a)','6-3','0610'),('PR','2/Tau','Tauentzien (2a)','6-3','0808'),('PR','Tau','Cav. Tauentzien','2-4c','0905'),('PR','TauA','Art. Tauentzien','3-3a','0811'),
 ('PR','1/Gra','Grawert (1a)','6-3','1910'),('PR','2/Gra','Grawert (2a)','6-3','1908'),('PR','Gra','Cav. Grawert','2-4c','2006'),('PR','GraA','Art. Grawert','3-3a','2009'),
 ('PR','1/Sax','Sassoni (1a)','5-3','1408'),('PR','2/Sax','Sassoni (2a)','5-3','1805'),('PR','Sax','Cav. sassone','2-4c','1705'),('PR','SaxA','Art. sassone','2-3a','1605'),
 ('PR','Dhy','Dyherrn','3-3','1804'),
 ('PR','1/1','1a div. (Schmettau)','6-3',('O',2,1)),('PR','2/1','1a div. (Schmettau)','6-3',('O',2,1)),('PR','1','Cav. 1a div.','2-4c',('O',2,1)),
 ('PR','1/2','2a div. (Wartensleben)','6-3',('O',2,1)),('PR','2/2','2a div. (Wartensleben)','6-3',('O',2,1)),('PR','2','Cav. 2a div.','2-4c',('O',2,1)),
 ('PR','1/3','3a div. (Orange)','6-3',('O',2,1)),('PR','2/3','3a div. (Orange)','6-3',('O',2,1)),('PR','3','Cav. 3a div.','2-4c',('O',2,1)),
 ('PR','Blu','Blücher','3-4c',('O',2,1)),('PR','1A','Art. di Brunswick','7-3a',('O',2,1)),
 ('PR','1/1R','1a div. riserva (Kunheim)','5-3',('O',3,2)),('PR','2/1R','1a div. riserva (Kunheim)','5-3',('O',3,2)),('PR','1R','Cav. 1a riserva','3-4c',('O',3,2)),
 ('PR','1/2R','2a div. riserva (Arnim)','5-3',('O',3,2)),('PR','2/2R','2a div. riserva (Arnim)','5-3',('O',3,2)),('PR','2R','Cav. 2a riserva','4-4c',('O',3,2)),
 ('PR','ResA','Art. di riserva','5-3a',('O',3,2)),
 ('PR','Holz','Holtzendorff','4-3',('T',5,'0120')),('PR','HolzC','Cav. Holtzendorff','2-4c',('T',5,'0120')),
 ('PR','1/Ruch','Rüchel (1a)','7-3',('T',10,'2901')),('PR','2/Ruch','Rüchel (2a)','7-3',('T',10,'2901')),
 ('PR','1/Lou','Luigi Ferdinando (1a)','6-3',('L',3,2)),('PR','2/Lou','Luigi Ferdinando (2a)','6-3',('L',3,2)),('PR','Lou','Cav. Luigi Ferdinando','2-4c',('L',3,2)),
 ('PR','LouA','Art. Luigi Ferdinando','3-3a',('L',3,2)),
 ('FR','1/Gaz','Gazan (1a)','8-4','0606'),('FR','2/Gaz','Gazan (2a)','8-4','0607'),('FR','1/Suc','Suchet (1a)','8-4','0508'),('FR','2/Suc','Suchet (2a)','8-4','0408'),
 ('FR','V','Cav. V corpo','2-5c','0407'),
 ('FR','Gd','Guardia imperiale','11-4',('T',1,'0104')),('FR','VA','Art. V corpo','5-3a',('T',1,'0104')),
 ('FR','1/De','Desjardin (1a)','4-4',('T',2,'0104')),('FR','2/De','Desjardin (2a)','4-4',('T',2,'0104')),('FR','1/He','Heudelet (1a)','4-4',('T',2,'0104')),
 ('FR','2/He','Heudelet (2a)','4-4',('T',2,'0104')),('FR','VII','Cav. VII corpo','2-5c',('T',2,'0104')),
 ('FR','GdA','Art. Guardia','10-3a',('T',3,'0104')),('FR','VIIA','Art. VII corpo','5-3a',('T',3,'0104')),
 ('FR','Van','Avanguardia (Ney)','4-4',('T',4,'0104')),('FR','VI','Cav. VI corpo','2-5c',('T',4,'0104')),
 ('FR','1/Gud','Gudin (1a)','7-4',('D',4,'0128')),('FR','2/Gud','Gudin (2a)','7-4',('D',4,'0128')),('FR','Gud','Art. Gudin','3-3a',('D',4,'0128')),
 ('FR','1/Hil','St. Hilaire (1a)','5-4',('T',5,'0112')),('FR','2/Hil','St. Hilaire (2a)','5-4',('T',5,'0112')),('FR','IV','Cav. IV corpo','2-5c',('T',5,'0112')),
 ('FR','1/Fri','Friant (1a)','7-4',('D',6,'0128')),('FR','2/Fri','Friant (2a)','6-4',('D',6,'0128')),('FR','Fri','Art. Friant','3-3a',('D',6,'0128')),
 ('FR','III','Cav. III corpo','2-5c',('D',6,'0128')),
 ('FR','1/Mor','Morand (1a)','8-4',('D',7,'0128')),('FR','2/Mor','Morand (2a)','7-4',('D',7,'0128')),('FR','Mor','Art. Morand','4-3a',('D',7,'0128')),
 ('FR','1/Mar','Marchand (1a)','4-4',('T',8,'0104')),('FR','2/Mar','Marchand (2a)','4-4',('T',8,'0104')),('FR','1/Mah','Maher (1a)','4-4',('T',8,'0104')),
 ('FR','2/Mah','Maher (2a)','4-4',('T',8,'0104')),('FR','VIA','Art. VI corpo','5-3a',('T',8,'0104')),
 ('FR','1/Lev','Leval (1a)','5-4',('T',9,'0104')),('FR','2/Lev','Leval (2a)','5-4',('T',9,'0104')),('FR','1/Leg','Legrand (1a)','5-4',('T',9,'0104')),
 ('FR','2/Leg','Legrand (2a)','5-4',('T',9,'0104')),('FR','IVA','Art. IV corpo','5-3a',('T',9,'0104')),
 ('FR','Kle','Klein','4-5c',('T',10,'0104')),('FR','Nan','Nansouty','4-5c',('T',10,'0104')),('FR','Haut','Hautpoul','4-5c',('T',10,'0104')),
 ('FR','1/Riv','Rivaud (1a)','4-4',('B',10,'0820')),('FR','2/Riv','Rivaud (2a)','4-4',('B',10,'0820')),('FR','I','Cav. I corpo','2-5c',('B',10,'0820')),
 ('FR','Sah','Sahuc','4-5c',('B',10,'0820')),
 ('FR','1/Dro','Drouet (1a)','4-4',('B',12,'0820')),('FR','2/Dro','Drouet (2a)','4-4',('B',12,'0820')),('FR','IA','Art. I corpo','5-3a',('B',12,'0820')),
]
COLORI={'FR':(130,202,255),'AU':(234,229,120),'PR':(100,153,44),'RU':(238,220,12),'SV':(198,165,64)}
GIOCHI={'marengo':('M',MARENGO),'wagram':('W',WAGRAM),'nazioni':('N',NAZIONI),'jena':('J',JENA)}
def pulisci(s): return re.sub(r'[^A-Za-z0-9]','',s)
catalogo={}; per_gioco={}
F=ImageFont.truetype(R+'/assets/font/OldStandard-Bold.ttf',62); FD=ImageFont.truetype(R+'/assets/font/OldStandard-Bold.ttf',26)
SIL={k:Image.open(f'/tmp/nawt/sil_{k}.png') for k in ('inf','cav','art')}
SIGLE={'VA':'V','VIA':'VI','IVA':'IV','IA':'I','GdA':'Gd','TauA':'Tau','GraA':'Gra','SaxA':'Sax','LouA':'Lou','ResA':'Res','VIIA':'VII','IXA':'IX','IIa':'II','IVa':'IV','VIa':'VI','Ia':'I','IIIa':'III','SRa':'SR','SRc':'SR','1R':'1 Res','2R':'2 Res','1A':'I','HolzC':'Holz','IIc':'1/II','IVc':'IV','VIc':'VI','1/AGc':'1/AG','2/AGc':'2/AG','1/Resc':'1/Res','2/Resc':'2/Res','3/Resc':'3/Res','1c':'1','Prov1':'Prov','Prov2':'Prov','1/1R':'1/1 Res','2/1R':'2/1 Res','1/2R':'1/2 Res','2/2R':'2/2 Res'}
def sigla_stampata(des): return SIGLE.get(des,des)
def disegna(path,es,des,f,ma,t):
  S=180; im=Image.new('RGB',(S,S),COLORI[es]); d=ImageDraw.Draw(im)
  sil=SIL[{'I':'inf','C':'cav','A':'art'}[t]]
  sc=min(100/sil.height,105/sil.width); s2=sil.resize((int(sil.width*sc),int(sil.height*sc)),Image.LANCZOS)
  im.paste((0,0,0),(S//2-s2.width//2+12,8),s2)
  d.text((7,4),des,font=FD,fill=(0,0,0))
  txt=f'{f}-{ma}'; w=d.textlength(txt,font=F); d.text(((S-w)/2,108),txt,font=F,fill=(0,0,0))
  im.resize((128,128),Image.LANCZOS).save(path,quality=90)
for g,(L,dati) in GIOCHI.items():
  per_gioco[g]=[]
  for n,v in enumerate(dati,1):
    es,des,nome,fm=v[0],v[1],v[2],v[3]
    t='C' if fm.endswith('c') else ('A' if fm.endswith('a') else 'I')
    f,ma=map(int,fm.rstrip('ca').split('-'))
    id=f'u{L}{n}'
    sd=sigla_stampata(des)
    catalogo[id]={'n':nome,'naz':es,'es':es,'t':t,'f':f,'r':0,'ma':ma,'des':sd,'c':sd,'gioco':g}
    per_gioco[g].append((id,)+tuple(v[4:]))
    disegna(f'{R}/assets/naw/pedine/{id}.webp',es,sd,f,ma,t)
json.dump({'unita':catalogo,'per_gioco':per_gioco},open('/tmp/nawm/oob.json','w'),ensure_ascii=False,indent=0)
print({g:len(v) for g,v in per_gioco.items()},len(catalogo))
