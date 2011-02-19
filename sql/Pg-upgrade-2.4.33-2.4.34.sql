--Better IS
ALTER TABLE customer ADD COLUMN shipvia TEXT;
ALTER TABLE customer ADD COLUMN shippingpoint TEXT;
UPDATE defaults SET version = '2.4.34';
