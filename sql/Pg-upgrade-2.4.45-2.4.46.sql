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
--
UPDATE defaults SET version = '2.4.46';
