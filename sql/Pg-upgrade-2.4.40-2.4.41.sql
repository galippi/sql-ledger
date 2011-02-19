ALTER TABLE defaults ADD COLUMN rincome_accno_id INT;
ALTER TABLE defaults ADD COLUMN rcost_accno_id INT;
--
UPDATE defaults SET version = '2.4.41';
