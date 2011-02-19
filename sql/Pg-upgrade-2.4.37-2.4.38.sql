--invoice-like document
ALTER TABLE ar ADD COLUMN szeta BOOLEAN;
ALTER TABLE defaults ADD COLUMN invnumber_st TEXT;
UPDATE defaults SET invnumber_st = '00000';
--
UPDATE defaults SET version = '2.4.38';

