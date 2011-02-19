--Scanned docs
ALTER TABLE ap ADD COLUMN scanned TEXT;
--
UPDATE defaults SET version = '2.4.32';
