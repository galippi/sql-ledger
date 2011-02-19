--
CREATE SEQUENCE id start 10000;
SELECT nextval ('id');
--
CREATE SEQUENCE invoiceid;
SELECT nextval ('invoiceid');
--
CREATE SEQUENCE orderitemsid MAXVALUE 100000 CYCLE;
SELECT nextval ('orderitemsid');
--
CREATE TABLE makemodel (
  parts_id int,
  make text,
  model text
);
--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  employee_id int,
  notes text,
  department_id int default 0,
  cash boolean
);
--
CREATE TABLE chart (
  id int DEFAULT nextval ( 'id' ),
  accno text NOT NULL,
  description text,
  charttype char(1) DEFAULT 'A',
  category char(1),
  link text,
  gifi_accno text,
  ptype text,
  validfrom date DEFAULT '2000-01-01',
  validto date DEFAULT '2020-12-31',
  notes text  
);
--
CREATE TABLE gifi (
  accno text,
  description text
);
--
CREATE TABLE defaults (
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  fxgain_accno_id int,
  fxloss_accno_id int,
  invnumber text,
  sonumber text,
  yearend varchar(5),
  weightunit varchar(5),
  businessnumber text,
  version varchar(8),
  curr text,
  closedto date,
  revtrans bool DEFAULT 'f',
  ponumber text,
  sqnumber text,
  rfqnumber text,
  audittrail bool default 'f',
  ar_accno_id int,
  ap_accno_id int,
  promptshipreceive bool,
  prefix text,
  suffix text,
  last_oscorder int,
  taxreturn date,
  invnumber_st text,
  rincome_accno_id int,
  rcost_accno_id int,
  cash_accno_id int,
  transnumber text
);
INSERT INTO defaults (version) VALUES ('2.4.52');
--
CREATE TABLE acc_trans (
  trans_id int,
  chart_id int,
  amount float,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  taxbase character varying(6)
);
--
CREATE TABLE invoice (
  id int DEFAULT nextval ( 'invoiceid' ),
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  allocated float4,
  sellprice float,
  fxsellprice float,
  discount float4,
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  ship real
);
--
CREATE TABLE customer (
  id int default nextval('id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  discount float4,
  taxincluded bool default 'f',
  creditlimit float default 0,
  terms int2 default 0,
  customernumber varchar(32),
  cc text,
  bcc text,
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  iban varchar(34),
  bic varchar(11),
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  shipvia text,
  shippingpoint text,
  startdate date,
  enddate date,
  duebase text,
  intnotes text
);
--
--
CREATE TABLE parts (
  id int DEFAULT nextval ( 'id' ),
  partnumber text,
  description text,
  unit varchar(5),
  listprice float,
  sellprice float,
  lastcost float,
  priceupdate date DEFAULT current_date,
  weight float4,
  onhand float4 DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop float4,
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
  tdij bool DEFAULT 'f',
  tdij2 bool DEFAULT 'f',
  project_id int,
  avprice float
);
--
CREATE TABLE assembly (
  id int,
  parts_id int,
  qty float,
  bom bool,
  adj bool
) WITH OIDS;
--
CREATE TABLE ar (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  customer_id int,
  taxincluded bool,
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  shippingpoint text,
  terms int2 DEFAULT 0,
  notes text,
  curr char(3),
  ordnumber text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  crdate date,
  oe_id int,
  szeta bool,
  footer text
);
--
CREATE TABLE ap (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  vendor_id int,
  taxincluded bool DEFAULT 'f',
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  ordnumber text,
  curr char(3),
  notes text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  crdate date,
  oe_id int,
  scanned text,
  eva bool DEFAULT 'f'
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int
);
--
CREATE TABLE tax (
  chart_id int,
  rate float,
  taxnumber text,
  base bool DEFAULT 'f'
);
--
CREATE TABLE customertax (
  customer_id int,
  chart_id int
);
--
CREATE TABLE vendortax (
  vendor_id int,
  chart_id int
);
--
CREATE TABLE oe (
  id int default nextval('id'),
  ordnumber text,
  transdate date default current_date,
  vendor_id int,
  customer_id int,
  amount float8,
  netamount float8,
  reqdate date,
  taxincluded bool,
  shippingpoint text,
  notes text,
  curr char(3),
  employee_id int,
  closed bool default 'f',
  quotation bool default 'f',
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6)
);
--
CREATE TABLE orderitems (
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  sellprice float8,
  discount float4,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship float4,
  serialnumber text,
  id int default nextval('orderitemsid'),
  invoice_id int
) WITH OIDS;
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy float8,
  sell float8,
  sell_paid float8,
  buy_paid float8
);
--
create table employee (
  id int default nextval('id'),
  login text,
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  workphone varchar(20),
  homephone varchar(20),
  startdate date default current_date,
  enddate date,
  notes text,
  role varchar(20),
  sales bool default 'f',
  email text,
  sin varchar(20),
  iban varchar(34),
  bic varchar(11),
  managerid int,
  warehouse_id int
);
--
create table shipto (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
--
CREATE TABLE vendor (
  id int default nextval('id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2 default 0,
  taxincluded bool default 'f',
  vendornumber varchar(32),
  cc text,
  bcc text,
  gifi_accno varchar(30),
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  discount float4,
  creditlimit float default 0,
  iban varchar(34),
  bic varchar(11),
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  startdate date,
  enddate date,
  intnotes text
);
--
CREATE TABLE project (
  id int default nextval('id'),
  projectnumber text,
  description text
);
--
CREATE TABLE partsgroup (
  id int default nextval('id'),
  partsgroup text
);
--
CREATE TABLE status (
  trans_id int,
  formname text,
  printed bool default 'f',
  emailed bool default 'f',
  spoolfile text,
  chart_id int
);
--
CREATE TABLE department (
  id int default nextval('id'),
  description text,
  role char(1) default 'P'
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int,
  department_id int
);
--
-- business table
CREATE TABLE business (
  id int default nextval('id'),
  description text,
  discount float4,
  tdij1 real,
  tdij2 real
);
--
-- SIC
CREATE TABLE sic (
  code varchar(6),
  sictype char(1),
  description text
);
--
CREATE TABLE warehouse (
  id int default nextval('id'),
  description text
);
--
CREATE TABLE inventory (
  warehouse_id int,
  parts_id int,
  oe_id int,
  orderitems_id int,
  qty float4,
  shippingdate date,
  employee_id int,
  notes text,
  iris_id int,
  invoice_id int
) WITH OIDS;
--
CREATE TABLE yearend (
  trans_id int,
  transdate date
);
--
CREATE TABLE partsvendor (
  vendor_id int,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost float,
  curr char(3)
);
--
CREATE TABLE pricegroup (
  id int default nextval('id'),
  pricegroup text
);
--
CREATE TABLE partscustomer (
  parts_id int,
  customer_id int,
  pricegroup_id int,
  pricebreak float4,
  sellprice float,
  validfrom date,
  validto date,
  curr char(3)
);
--
CREATE TABLE language (
  code varchar(6),
  description text
);
INSERT INTO language (code,description) VALUES('export', 'export');
--INSERT INTO language (code,description) VALUES('kp', 'kp');
--
CREATE TABLE audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp default current_timestamp,
  employee_id int
);
--
CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text
);
--
CREATE TABLE serialnum (
   id INT,
   parts_id int,
   number TEXT,
   qty INT,
   warehouse_id INT
);
CREATE TABLE cogs(
  invdate date,
  parts_id int,
  allocated int,
  sellprice float,
  costprice float,
  ar_id int,
  ap_id int
);
CREATE TABLE ds (
    id int DEFAULT nextval('id'),
    usr varchar(128),
    name varchar(1024),
    query varchar(4096),
    template varchar(256)
);    
CREATE TABLE regnum (
  code text,
  number int default 0,
  description text,
  chart_id int,
  regcheck boolean,
  vcurr char(3)
);
--register numbers
CREATE TABLE regnumber (
  code text,
  regnumber int default 0,
  description text,
  aparcheck boolean
);
--betterbank
CREATE TABLE regnum_cash (
chart_id integer, 
mincash double precision, 
maxcash double precision
);
--template
 CREATE TABLE gl_template (LIKE gl);
 ALTER TABLE gl_template ADD COLUMN tempname TEXT;
 ALTER TABLE gl_template ADD COLUMN tempnum INTEGER;
 CREATE TABLE acc_trans_template (LIKE acc_trans);
 ALTER TABLE gl_template ALTER COLUMN id SET DEFAULT nextval('id'::TEXT);
 ALTER TABLE gl_template ALTER COLUMN transdate SET DEFAULT ('now'::text)::date;
 ALTER TABLE gl_template ALTER COLUMN department_id SET DEFAULT 0;
 ALTER TABLE acc_trans_template ADD COLUMN rowc INT;
 ALTER TABLE acc_trans ADD COLUMN rowc INT;
 ALTER TABLE gl_template ADD COLUMN tip INT;
 ALTER TABLE gl_template ALTER COLUMN transdate DROP default;

--transfer packing list
CREATE TABLE szl (
 id int DEFAULT nextval ( 'id' ),
 szlnumber text,
 transdate date DEFAULT current_date,
 to_warehouse_id int,
 shippingpoint text,
 notes text,
 employee_id int,
 warehouse_id int,
 intnotes text,
 department_id int default 0,
 language_code varchar(6),
 shipdate date
)WITH OIDS;

CREATE TABLE szlitems (
 id integer default nextval('orderitemsid'),
 trans_id int,
 parts_id int,
 description text,
 ship float4
)WITH OIDS;

--customer, company addresses stored
CREATE TABLE customeraddress (
  trans_id int,
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32)
);
CREATE TABLE companyaddress (
    trans_id int,
    name varchar(64),
    address text,
    phone varchar(20),
    fax varchar(20)
);
CREATE TABLE product_charge (
    id int default nextval ('id'),
    tdij1 real,
    tdij2 real,
    invoice_id int
);
CREATE TABLE armod (
  parts_id int,
  typ character (1) default '0',
  oldprice double precision,
  newprice double precision,
  moddate date,
  notes text,
  employee_id int
);