ALTER TABLE defaults ADD COLUMN cash_accno_id INT;
ALTER TABLE regnumber ADD COLUMN aparcheck boolean;
UPDATE regnumber SET aparcheck = 'f';
--
UPDATE defaults SET version = '2.4.44';
