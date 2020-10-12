# percona-toolkit
online alter database tool

## Install
```
wget https://github.com/percona/percona-toolkit/archive/v3.2.1.tar.gz


yum install perl-DBI perl-DBD-MySQL perl-TermReadKey perl-IO-Socket-SSL perl-Time-HiRes perl-devel -y 
yum install perl perl-IO-Socket-SSL perl-Time-HiRes

Installing
To install all tools, run:

perl Makefile.PL
make
make test
make install
```


### Test Data 생성 
```
create table testtable (id int auto_increment primary key, value int, value2 varchar(100)) engine=innodb;


mysqlslap -uroot -p'Mysql123!' -h 127.0.0.1 -P 3306 --create-schema=repl_db --query="insert into repl_db.testtable values (null, 1, 'abcdefghijklmn')" --number-of-queries=20000 --concurrency=2 &

```

### pt-online-schema-change
online 상태의 데이터베이스 스키마를 변경할수 있는 툴. 
용량이 크거나 부득이하게 데이터베이스 오픈된 상태에서 사용
```
pt-online-schema-change --alter "add column testcol varchar(255) default null" D=repl_db,t=testtable \
--no-drop-old-table \
--no-drop-new-table \
--chunk-size=500 \
--chunk-size-limit=600 \
--defaults-file=/etc/my.cnf \
--host=127.0.0.1 \
--port=3306 \
--user=root \
--ask-pass \
--progress=time,30 \
--max-load="Threads_running=100" \
--critical-load="Threads_running=1000" \
--chunk-index=PRIMARY \
--charset=UTF8 \
--alter-foreign-keys-method=auto \
--preserve-triggers \
--execute


[root@53364085d678 /]# pt-online-schema-change --alter "add column testcol2 varchar(255) default null" D=repl_db,t=test
table --no-drop-old-table --no-drop-new-table --chunk-size=500 --chunk-size-limit=600 --defaults-file=/etc/my.cnf --hos
t=127.0.0.1 --port=3306 --user=root --ask-pass --progress=time,30 --max-load="Threads_running=100" --critical-load="Thr
eads_running=1000" --chunk-index=PRIMARY --charset=UTF8 --alter-foreign-keys-method=auto --preserve-triggers --execute
Enter MySQL password:
Cannot connect to A=UTF8,F=/etc/my.cnf,h=172.17.0.5,p=...,u=root
No slaves found.  See --recursion-method if host 53364085d678 has slaves.
Not checking slave lag because no slaves were found and --check-slave-lag was not specified.
Operation, tries, wait:
  analyze_table, 10, 1
  copy_rows, 10, 0.25
  create_triggers, 10, 1
  drop_triggers, 10, 1
  swap_tables, 10, 1
  update_foreign_keys, 10, 1
No foreign keys reference `repl_db`.`testtable`; ignoring --alter-foreign-keys-method.
Altering `repl_db`.`testtable`...
Creating new table...
Created new table repl_db._testtable_new OK.
Altering new table...
Altered `repl_db`.`_testtable_new` OK.
2020-10-12T10:09:41 Creating triggers...
2020-10-12T10:09:41 Created triggers OK.
2020-10-12T10:09:41 Copying approximately 21173 rows...
Cannot connect to A=UTF8,F=/etc/my.cnf,h=172.17.0.5,p=...,u=root
2020-10-12T10:09:41 Copied rows OK.
2020-10-12T10:09:41 Adding original triggers to new table.
2020-10-12T10:09:41 Analyzing new table...
2020-10-12T10:09:41 Swapping tables...
2020-10-12T10:09:42 Swapped original and new tables OK.
Not dropping old table because --no-drop-old-table was specified.
2020-10-12T10:09:42 Dropping triggers...
2020-10-12T10:09:42 Dropped triggers OK.
Successfully altered `repl_db`.`testtable`.
[root@53364085d678 /]#
```

## Result 
```
mysql> show create table testtable;'
+-----------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Table     | Create Table                                                                                                                                                                                                                                                                                           |
+-----------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| testtable | CREATE TABLE `testtable` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` int(11) DEFAULT NULL,
  `value2` varchar(100) DEFAULT NULL,
  `testcol` varchar(255) DEFAULT NULL,
  `testcol2` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21491 DEFAULT CHARSET=utf8 |
+-----------+--------------------------------------------------
```