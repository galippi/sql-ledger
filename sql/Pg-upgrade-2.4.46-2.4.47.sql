--base vat
ALTER TABLE tax ADD COLUMN base boolean;
ALTER TABLE tax ALTER COLUMN base SET DEFAULT false;
--
UPDATE defaults SET version = '2.4.47';

