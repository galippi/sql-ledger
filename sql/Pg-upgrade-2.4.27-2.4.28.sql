CREATE TABLE ds (
    id int DEFAULT nextval('id'),
    usr varchar(128),
    name varchar(1024),
    query varchar(4096),
    template varchar(256)
);
--
update defaults set version = '2.4.28';
