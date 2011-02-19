--Hungarian chart of accounts 
-- Magyar f�k�nyvi sz�ml�k, amelyek csak p�ldak�nt szolg�lnak
--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1140','Irodai eszk�z�k','A','A','','114');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1199','Irodai eszk�z�k �CS','A','A','','119');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2610','�ruk ','A','A','IC','261');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3110','Vev�k �tutal�sos','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3111','Vev�k K�szp�nzes','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3810','P�nzt�r 1','A','A','AR_paid:AP_paid','381','pcash');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3811','P�nzt�r 2','A','A','AR_paid:AP_paid','381','pcash');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3840','Bank 1','A','A','AR_paid:AP_paid','384','bank');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,ptype) VALUES ('3841','Bank 2','A','A','AR_paid:AP_paid','384','bank');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4540','Sz�ll�t�k �tutal�sos','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4541','Sz�ll�t�k K�szp�nzes','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validto) VALUES ('4660','Visszaig�nyelhet� �FA 20%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-06-30');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4661','Visszaig�nyelhet� �FA 25%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4662','Visszaig�nyelhet� �FA 5%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4663','Visszaig�nyelhet� �FA ad�mentes','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4664','Visszaig�nyelhet� �FA 18%','A','L','AP_tax:IC_taxpart:IC_taxservice:CT_tax','466', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validto) VALUES ('4670','Fizetend� �FA 20%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-06-30');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4671','Fizetend� �FA 25%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4672','Fizetend� �FA 5%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4673','Fizetend� �FA ad�mentes','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno, validfrom) VALUES ('4674','Fizetend� �FA 18%','A','L','AR_tax:IC_taxpart:IC_taxservice:CT_tax','467', '2009-07-01');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5200','B�rleti d�j','A','E','AP_amount','520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5210','Telefon','A','E','AP_amount','521');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5990','K�lts�gek','A','E','IC_expense','599');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8140','Eladott �ruk beszerz�si �rt�ke','A','E','IC_cogs','814');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8610','Egy�b k�lts�gek','A','E','AR_paid:AP_paid','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8700','�rfolyamvesztes�g','A','E','','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9110','Belf�ldi �rbev�tel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9610','Egy�b �rbev�tel','A','I','AR_paid:AP_paid','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9700','�rfolyamnyeres�g','A','I','','970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1','BEFEKTETETT ESZK�Z�K','H','A','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2','K�SZLETEK','H','A','','2');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3','K�VETEL�SEK','H','A','','3');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4','K�TELEZETTS�GEK','H','L','','4');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5','K�LTS�GEK','H','E','','5');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8','R�FORD�T�SOK','H','E','','8');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9','BEV�TELEK','H','I','','9');
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

