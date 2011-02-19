-- weighted average price
ALTER TABLE parts ADD COLUMN avprice DOUBLE PRECISION;
--
UPDATE defaults SET version = '2.4.51';
