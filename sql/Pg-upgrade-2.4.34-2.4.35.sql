--OsCommerce connection
ALTER TABLE defaults ADD COLUMN last_oscorder INTEGER;
UPDATE defaults SET version = '2.4.35';
