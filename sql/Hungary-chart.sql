--Hungarian chart of accounts 
-- Magyar fõkönyvi számlák, amelyek csak példaként szolgálnak
--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1140','Irodai eszközök','A','A','','114');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1199','Irodai eszközök ÉCS','A','A','','119');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2610','Áruk ','A','A','IC','261');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3110','Vevõk Átutalásos','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3111','Vevõk Készpénzes','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3810','Pénztár 1','A','A','AR_paid:AP_paid','381','pcash');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3811','Pénztár 2','A','A','AR_paid:AP_paid','381','pcash');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3840','Bank 1','A','A','AR_paid:AP_paid','384','bank');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3841','Bank 2','A','A','AR_paid:AP_paid','384','bank');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4540','Szállítók Átutalásos','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4541','Szállítók Készpénzes','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validto) VALUES ('4660','Visszaigényelhetõ ÁFA 20%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-06-30');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4661','Visszaigényelhetõ ÁFA 25%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4662','Visszaigényelhetõ ÁFA 5%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4663','Visszaigényelhetõ ÁFA adómentes','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4664','Visszaigényelhetõ ÁFA 18%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validto) VALUES ('4670','Fizetendõ ÁFA 20%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-06-30');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4671','Fizetendõ ÁFA 25%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4672','Fizetendõ ÁFA 5%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4673','Fizetendõ ÁFA adómentes','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4674','Fizetendõ ÁFA 18%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5200','Bérleti díj','A','E','AP_amount','520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5210','Telefon','A','E','AP_amount','521');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5990','Költségek','A','E','IC_expense','599');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8140','Eladott áruk beszerzési értéke','A','E','IC_cogs','814');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8610','Egyéb költségek','A','E','AR_paid:AP_paid','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8700','Árfolyamveszteség','A','E','','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9110','Belföldi árbevétel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9610','Egyéb árbevétel','A','I','AR_paid:AP_paid','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9700','Árfolyamnyereség','A','I','','970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1','BEFEKTETETT ESZKÖZÖK','H','A','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2','KÉSZLETEK','H','A','','2');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3','KÖVETELÉSEK','H','A','','3');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4','KÖTELEZETTSÉGEK','H','L','','4');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5','KÖLTSÉGEK','H','E','','5');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8','RÁFORDÍTÁSOK','H','E','','8');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9','BEVÉTELEK','H','I','','9');
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4660'),'0.20','VIS');
INSERT INTO tax (chart_id,rate,taxnumber, base) VALUES ((SELECT id FROM chart WHERE accno='4661'),'0.25','VIS','t');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4662'),'0.05','VIS');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4663'),'0','VIS');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4664'),'0.18','VIS');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4670'),'0.20','FIZ');
INSERT INTO tax (chart_id,rate,taxnumber, base) VALUES ((SELECT id FROM chart WHERE accno='4671'),'0.25','FIZ','t');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4672'),'0.05','FIZ');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4673'),'0','FIZ');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4674'),'0.18','FIZ');
--
UPDATE defaults SET inventory_accno_id = (SELECT id FROM chart WHERE accno = '2110'), income_accno_id = (SELECT id FROM chart WHERE accno = '9110'), expense_accno_id = (SELECT id FROM chart WHERE accno = '8140'), fxgain_accno_id = (SELECT id FROM chart WHERE accno = '9700'), fxloss_accno_id = (SELECT id FROM chart WHERE accno = '8700'), ar_accno_id = (SELECT id FROM chart WHERE accno = '3111'), ap_accno_id = (SELECT id FROM chart WHERE accno = '4541'),rcost_accno_id = (SELECT id FROM chart WHERE accno = '8610'), rincome_accno_id = (SELECT id FROM chart WHERE accno = '9610'), invnumber = '00000' , invnumber_st = '00000', sonumber = 'vr1000', ponumber = 'br1000', sqnumber = 'aa1000', rfqnumber = 'ak1000', transnumber = 'tr1000', curr = 'HUF:EUR:USD', weightunit = 'kg';

