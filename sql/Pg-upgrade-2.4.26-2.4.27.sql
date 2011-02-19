ALTER TABLE employee ADD COLUMN warehouse_id INT;
--
update defaults set version = '2.4.27';
