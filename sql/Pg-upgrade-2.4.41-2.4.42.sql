ALTER TABLE ar ADD COLUMN footer TEXT;
--
UPDATE defaults SET version = '2.4.42';
