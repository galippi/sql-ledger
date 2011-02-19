--vatlist
ALTER TABLE ap ADD COLUMN eva boolean;
ALTER TABLE ap ALTER COLUMN eva SET DEFAULT false;
--datelimit
ALTER TABLE defaults ADD COLUMN taxreturn date;
--selectap
ALTER TABLE chart ADD COLUMN notes text;
--register numbers
CREATE TABLE regnumber (
  code text,
  regnumber int default 0,
  description text
);
CREATE UNIQUE INDEX regnumber_key ON regnumber (code);
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
--
UPDATE defaults SET version = '2.4.36';

