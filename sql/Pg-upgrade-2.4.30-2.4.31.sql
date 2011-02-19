CREATE TABLE regnum (
  code text,
  number int default 0,
  description text,
  chart_id int,
  regcheck boolean,
  vcurr char(3)
);
CREATE UNIQUE INDEX regnum_key ON regnum (code);
CREATE UNIQUE INDEX regtype_key ON regnum (chart_id,regcheck);
ALTER TABLE gl ADD COLUMN cash BOOLEAN;
--
UPDATE defaults SET version = '2.4.31';
