ALTER TABLE chart ADD COLUMN validfrom DATE;
ALTER TABLE chart ADD COLUMN validto DATE;
ALTER TABLE chart ALTER validfrom SET DEFAULT '2000-01-01';
ALTER TABLE chart ALTER validto SET DEFAULT '2020-12-31';
UPDATE chart SET validfrom = '2000-01-01', validto = '2020-12-31';
--
update defaults set version = '2.4.25';