# partitioning
CREATE TABLE tr ( id INT, name VARCHAR(50), purchased DATE
primary key (id)
)
PARTITION BY RANGE( YEAR (purchased))
(
PARTITION p0 VALUES LESS THAN (1990),
PARTITION p1 VALUES LESS THAN (1995),
PARTITION p2 VALUES LESS THAN (2000),
PARTITION p3 VALUES LESS THAN (2005),
PARTITION p4 VALUES LESS THAN (2010),
PARTITION p5 VALUES LESS THAN (2015)
)

insert into tr values (1,'desk', '2003-10-15');
insert into tr values (2,'desk2', '1997-10-15');
insert into tr values (3,'desk3', '2009-10-15');
insert into tr values (4,'desk4', '2013-10-15');
insert into tr values (5,'desk5', '1999-10-15');
insert into tr values (6,'desk6', '1989-10-15');


alter table tr drop partition p2; 

alter table tr add partition (partition p6 values  less than(2020));


insert into tr values (7,'desk7', '2019-10-15');


select * from tr where purchased between '2011-01-11' and '2015-12-31' ;

select purchased from tr partition (p5);

# partitioning with pk
CREATE TABLE tr2 ( 
    id INT, 
    name VARCHAR(50), 
    purchased DATE,
    primary key (id, purchased)
)
PARTITION BY RANGE( YEAR (purchased))
(
PARTITION p0 VALUES LESS THAN (1990),
PARTITION p1 VALUES LESS THAN (1995),
PARTITION p2 VALUES LESS THAN (2000),
PARTITION p3 VALUES LESS THAN (2005),
PARTITION p4 VALUES LESS THAN (2010),
PARTITION p5 VALUES LESS THAN (2015)
);


select id, name, purchased
into outfile 'tr2.csv' FIELDS TERMINATED BY ','
FROM tr2; 

-- 경로 미지정시 database directory에 파일 생성됨. 


-- 절대 경로 지정 
select id, name, purchased
into outfile '/tmp/tr2.csv' FIELDS TERMINATED BY ','
FROM tr2; 


