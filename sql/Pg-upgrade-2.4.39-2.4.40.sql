ALTER TABLE customer ADD COLUMN duebase text;
--
DROP SEQUENCE serialnum_id CASCADE;
ALTER TABLE inventory DROP COLUMN serialnum_id;
--
UPDATE defaults SET version = '2.4.40';
