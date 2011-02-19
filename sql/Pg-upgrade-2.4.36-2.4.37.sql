--startdate enddate for customers, vendors
ALTER TABLE customer ADD COLUMN startdate date;
ALTER TABLE customer ADD COLUMN enddate date;
ALTER TABLE vendor ADD COLUMN startdate date;
ALTER TABLE vendor ADD COLUMN enddate date;

--
UPDATE defaults SET version = '2.4.37';

