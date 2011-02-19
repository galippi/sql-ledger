ALTER TABLE inventory ADD COLUMN iris_id INT;
ALTER TABLE inventory ADD COLUMN invoice_id INT;
ALTER TABLE invoice ADD COLUMN ship REAL;
--
UPDATE defaults SET version = '2.4.29';
