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
CREATE INDEX szl_id_key on szl (id);
CREATE INDEX szl_transdate_key on szl (transdate);
CREATE INDEX szl_szlnumber_key on szl (lower(szlnumber));
CREATE INDEX szl_employee_id_key on szl (employee_id);
	    
CREATE TABLE szlitems (
 id integer default nextval('orderitemsid'),
 trans_id int,
 parts_id int,
 description text,
 ship float4
)WITH OIDS;
CREATE INDEX szlitems_trans_id_key on szlitems (trans_id);
ALTER TABLE defaults ADD transnumber TEXT;
UPDATE defaults SET transnumber='TR0000';
--
UPDATE defaults SET version = '2.4.45';
