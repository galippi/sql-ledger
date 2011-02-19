ALTER TABLE customer ADD COLUMN intnotes TEXT;
--
UPDATE defaults SET version = '2.4.43';
