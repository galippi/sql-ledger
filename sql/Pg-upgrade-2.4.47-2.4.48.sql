ALTER TABLE parts ADD COLUMN tdij boolean;
ALTER TABLE parts ALTER COLUMN tdij SET default 'f';
ALTER TABLE business ADD COLUMN tdij1 real;
ALTER TABLE business ADD COLUMN tdij2 real;
CREATE TABLE product_charge (
    id int default nextval ('id'),
    tdij1 real,
    tdij2 real,
    invoice_id int
);
--
UPDATE defaults SET version = '2.4.48';
