-- US_Manufacturing COA
-- modify as needed
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','CURRENT ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Checking Account','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Petty Cash','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Accounts Receivables','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Allowance for doubtful accounts','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTORY ASSETS','H','','A','');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Inventory / General','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','Inventory / Raw Materials','A','1126','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1540','Inventory / Work in process','A','1125','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1550','Inventory / Finished Goods','A','1121','A','IC');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','CAPITAL ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Office Furniture & Equipment','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1825','Accum. Amort. -Furn. & Equip.','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Vehicle','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1845','Accum. Amort. -Vehicle','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','CURRENT LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Accounts Payable','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','LONG TERM LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Bank Loans','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Loans from Shareholders','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','SHARE CAPITAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Common Shares','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','RETAINED EARNINGS','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','Retained Earnings - prior years','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','SALES REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','Sales / General','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','Sales / Manufactured Goods','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4040','Sales / Aftermarket Parts','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','OTHER REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Shipping & Handling','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Interest','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Foreign Exchange Gain','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','COST OF GOODS SOLD','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Purchases','A','','E','AP_amount:IC_cogs:IC_expense');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','COGS / General','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5030','COGS / Raw Materials','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5040','COGS / Direct Labor','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5050','COGS / Overhead','A','','E','AP_amount:IC_cogs');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Freight','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','PAYROLL EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Wages & Salaries','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Accounting & Legal','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Advertising & Promotions','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','Bad Debts','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Amortization Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Insurance','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Interest & Bank Charges','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Office Supplies','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Rent','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Repair & Maintenance','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Telephone','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Travel & Entertainment','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Utilities','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','Registrations','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','Licenses','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Foreign Exchange Loss','A','','E','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2110','Accrued Income Tax - Federal','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2120','Accrued Income Tax - State','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2130','Accrued Franchise Tax','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2140','Accrued Real & Personal Prop Tax','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2150','Sales Tax','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice:CT_tax');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2210','Accrued Wages','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5510','Inc Tax Exp - Federal','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5520','Inc Tax Exp - State','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5530','Taxes - Real Estate','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5540','Taxes - Personal Property','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5550','Taxes - Franchise','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5560','Taxes - Foreign Withholding','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2150'),0.05);
--
update defaults set inventory_accno_id = (select id from chart where accno = '1520'), income_accno_id = (select id from chart where accno = '4020'), expense_accno_id = (select id from chart where accno = '5020'), fxgain_accno_id = (select id from chart where accno = '4450'), fxloss_accno_id = (select id from chart where accno = '5810'), curr = 'USD:CAD:EUR', weightunit = 'lbs';

