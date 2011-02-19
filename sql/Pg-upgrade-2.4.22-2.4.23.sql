ALTER TABLE acc_trans ADD COLUMN taxbase character varying(6);
--
update defaults set version = '2.4.23';