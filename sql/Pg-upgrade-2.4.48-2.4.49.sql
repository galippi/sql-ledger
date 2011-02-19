CREATE TABLE armod (
  parts_id int,
  typ character (1) default '0',
  oldprice double precision,
  newprice double precision,
  moddate date,
  notes text,
  employee_id int
);
create index armod_moddate_key on armod (moddate);
create index armod_parts_id_key on armod (parts_id);
--
UPDATE defaults SET version = '2.4.49';
