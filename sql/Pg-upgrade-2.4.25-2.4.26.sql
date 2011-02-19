ALTER TABLE defaults ADD COLUMN promptshipreceive BOOLEAN;
INSERT INTO language (code,description) VALUES('export', 'export');
INSERT INTO language (code,description) VALUES('kp', 'kp');
--
update defaults set version = '2.4.26';
