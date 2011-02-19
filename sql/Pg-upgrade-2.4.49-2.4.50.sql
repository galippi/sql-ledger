--devel 48-49
ALTER TABLE parts ADD COLUMN project_id INT;
--
ALTER TABLE parts ADD COLUMN tdij2 boolean;
ALTER TABLE parts ALTER COLUMN tdij2 SET default 'f';
--
UPDATE defaults SET version = '2.4.50';
