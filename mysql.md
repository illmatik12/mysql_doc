
# adminstration
## Configuration
 
MySQL의 Buffer Pool 및 Log Buffer과 연관된 Configuration을 분석한다.
https://ssup2.github.io/theory_analysis/MySQL_Buffer_Pool_Redo_Log_Log_Buffer/

### innodb_buffer_pool_size
    innodb_buffer_pool_size는 Buffer Pool의 크기를 설정한다. 기본값은 128MB이다. 일반적으로 Buffer Pool Size가 클 수록 Disk에 접근하는 횟수가 줄어들기 때문에 DB의 성능이 좋아진다. 하지만 Server Memory 용량에 맞지 않게 너무 큰 값을 설정하면 잦은 Page Swap으로 인하여 오히려 성능이 저하된다. 따라서 적절한 값으로 설정해야 한다. Server에 MySQL만 구동되는 상태라면 Server Memory 크기의 80%를 설정하는 것을 추천한다.
### innodb_log_file_size
    innodb_log_file_size는 Redo Log의 크기를 설정한다. 위에서 설명한 것처럼 InnoDB는 주기적으로 또는 Redo Log이 가득찰 경우 Buffer Pool에 기록된 Data 변경 내용을 실제 Disk에 반영하는 Checkpoint 동작을 수행한다. Buffer Pool의 크기가 아무리 크더라도 Redo Log의 크기가 작다면 자주 Check Point가 발생하기 때문에 Buffer Pool를 제대로 이용 할 수 없게 된다. 따라서 Buffer Pool 크기 변경시 Redo Log의 크기도 같이 변경해야 한다. 일반적으로 Buffer Pool Size (innodb_buffer_pool_size)값의 반으로 설정한다.
### innodb_log_buffer_size
    innodb_log_buffer_size는 Log Buffer의 크기를 설정한다. innodb_log_buffer_size은 Redo Log Buffer Memory의 크기를 나타낸다. 한번의 Transaction내에서 많은 Data 변경이 발생하는 경우 Redo Log Buffer Memory의 크기를 늘려 Redo Log가 가득차지 않도록 만드는 것이 좋다. 일반적으로 1MB ~ 8MB 사이의 크기로 설정한다.
### innodb_flush_log_at_trx_commit
    [그림 2] MySQL Flush Log Buffer
    InnoDB가 Log Buffer의 내용을 Redo Log에 Write 및 Flush 동작을 언제 수행할지 설정한다. 현재 MySQL에서는 0,1,2 3개의 Option만을 제공한다. Default 값은 1로 설정되어 있다. [그림 2]는 Option에 따른 Write, Flush 동작이 언제 수행되는지를 나타내고 있다.
* Option 0 : InnoDB는 Redo Log에 Write 및 Flush 동작을 Commit과 관계없이 1초 간격으로 수행한다. Commit 명령으로 Transaction이 끝나도 Data 변경 내용은 최대 1초동안 Redo Log Buffer에만 반영 되어 있고, Redo Log에 반영되지 않을 수 있다. 따라서 0 Option 이용시 MySQL에 장애 및 MySQL이 동작하는 Node에 장애가 발생 할 경우, 장애 발생전 1초 동안의 Transaction 내용은 유실된다.
* Option 1 : InnoDB는 Redo Log에 Write 및 Flush 동작을 Commit 명령이 수행될 때마다 같이 수행한다. 잦은 Write 및 Flush 동작으로 Disk 접근 횟수가 많아 성능이 느려지지만, 완료된 Transaction은 어떠한 장애가 발생하여도 유실되지 않는다.
* Option 2 : InnoDB는 Redo Log에 Write 동작은 Commit 명령이 수행될 때마다 같이 수행하지만, Flush 동작은 1초 간격으로 수행한다. Option 0과 Option 1의 중간 형태의 동작을 수행한다. 단순히 MySQL에만 장애가 발생하였다면 OS Cache에 저장된 Transaction 내용은 Redo Log에 반영될 확률이 높다. 하지만 MySQL이 동작하는 Node에 장애가 발생하였을 경우, Node 장애 발생전 1초 동안의 Transaction 내용은 유실된다.

## session configuration
## identify slow query 

### MySQL Slow Query Log
* 기본값 
```sql
mysql> select @@long_query_time
    -> ;
+-------------------+
| @@long_query_time |
+-------------------+
|         10.000000 |
+-------------------+
1 row in set (0.00 sec)

mysql>

SET @@long_query_time = 5

mysql> SHOW VARIABLES Like 'slow_query_log%';
+---------------------+--------------------------------------+
| Variable_name       | Value                                |
+---------------------+--------------------------------------+
| slow_query_log      | OFF                                  |
| slow_query_log_file | /var/lib/mysql/53364085d678-slow.log |
+---------------------+--------------------------------------+
2 rows in set (0.00 sec)

mysql>
```

* 추가 설정 (slow 쿼리 활성화)
```
# Enable slow query logging - note the dashes rather than underscores:
slow-query-log=1
```

### Unused Index
```sql
SELECT object_schema AS schema_name, 
object_name   AS table_name, 
index_name, 
count_fetch
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE count_fetch > 0;

mysql> SELECT object_schema AS schema_name,
    -> object_name   AS table_name,
    -> index_name,
    -> count_fetch
    -> FROM performance_schema.table_io_waits_summary_by_index_usage
    -> WHERE count_fetch > 0;
+-------------+------------+------------+-------------+
| schema_name | table_name | index_name | count_fetch |
+-------------+------------+------------+-------------+
| repl_db     | t2         | NULL       |          14 |
+-------------+------------+------------+-------------+
1 row in set (0.00 sec)

mysql>
```
쿼리 통계 조회 
```sql
// 최근 실행된 쿼리 이력 기능 활성화
UPDATE performance_schema.setup_consumers SET ENABLED = 'yes' WHERE NAME = 'events_statements_history'
UPDATE performance_schema.setup_consumers SET ENABLED = 'yes' WHERE NAME = 'events_statements_history_long'

// 5.7에서 조회시 오류 발생
set @@global.show_compatibility_56=ON;

SELECT left(digest_text, 64) AS digest_text_start
, ROUND(SUM(timer_end-timer_start)/1000000000, 1) AS tot_exec_ms
, ROUND(SUM(timer_end-timer_start)/1000000000/COUNT(*), 1) AS avg_exec_ms
, ROUND(MAX(timer_end-timer_start)/1000000000, 1) AS max_exec_ms
, ROUND(SUM(timer_wait)/1000000000, 1) AS tot_wait_ms
, ROUND(SUM(timer_wait)/1000000000/COUNT(*), 1) AS avg_wait_ms
, ROUND(MAX(timer_wait)/1000000000, 1) AS max_wait_ms
, ROUND(SUM(lock_time)/1000000000, 1) AS tot_lock_ms
, ROUND(SUM(lock_time)/1000000000/COUNT(*), 1) AS avglock_ms
, ROUND(MAX(lock_time)/1000000000, 1) AS max_lock_ms
, COUNT(*) as count  
FROM events_statements_history_long
JOIN information_schema.global_status AS isgs
WHERE isgs.variable_name = 'UPTIME'
GROUP BY LEFT(digest_text,64)
ORDER BY tot_exec_ms DESC;


mysql> SELECT left(digest_text, 64) AS digest_text_start , ROUND(SUM(timer_end-timer_start)/1000000000, 1) AS tot_exec_ms , ROUND(SUM(timer_end-timer_start)/1000000000/COUNT(*), 1) AS avg_exec_ms , ROUND(MAX(timer_end-timer_start)/1000000000, 1) AS max_exec_ms , ROUND(SUM(timer_wait)/1000000000, 1) AS tot_wait_ms , ROUND(SUM(timer_wait)/1000000000/COUNT(*), 1) AS avg_wait_ms , ROUND(MAX(timer_wait)/1000000000, 1) AS max_wait_ms , ROUND(SUM(lock_time)/1000000000, 1) AS tot_lock_ms , ROUND(SUM(lock_time)/1000000000/COUNT(*), 1) AS avglock_ms , ROUND(MAX(lock_time)/1000000000, 1) AS max_lock_ms , COUNT(*) as count   FROM events_statements_history_long JOIN information_schema.global_status AS isgs WHERE isgs.variable_name = 'UPTIME' GROUP BY LEFT(digest_text,64) ORDER BY tot_exec_ms DESC;
+------------------------------------------------------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+------------+-------------+-------+
| digest_text_start                                                | tot_exec_ms | avg_exec_ms | max_exec_ms | tot_wait_ms | avg_wait_ms | max_wait_ms | tot_lock_ms | avglock_ms | max_lock_ms | count |
+------------------------------------------------------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+------------+-------------+-------+
| NULL                                                             |         3.2 |         0.0 |         0.2 |         3.2 |         0.0 |         0.2 |         0.0 |        0.0 |         0.0 |    89 |
| SELECT LEFT ( `digest_text` , ? ) AS `digest_text_start` , `ROUN |         1.5 |         0.7 |         1.0 |         1.5 |         0.7 |         1.0 |         0.5 |        0.3 |         0.3 |     2 |
| SELECT * FROM `performance_schema` . `events_statements_history` |         0.4 |         0.4 |         0.4 |         0.4 |         0.4 |         0.4 |         0.2 |        0.2 |         0.2 |     1 |
| SELECT * FROM `performance_schema` . `events_statements_history_ |         0.4 |         0.4 |         0.4 |         0.4 |         0.4 |         0.4 |         0.1 |        0.1 |         0.1 |     1 |
| SHOW SCHEMAS                                                     |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.0 |        0.0 |         0.0 |     1 |
| SHOW TABLES                                                      |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.0 |        0.0 |         0.0 |     1 |
| UPDATE `performance_schema` . `setup_consumers` SET `ENABLED` =  |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.2 |         0.1 |        0.1 |         0.1 |     1 |
| SET @@GLOBAL . `show_compatibility_56` = ON                      |         0.1 |         0.1 |         0.1 |         0.1 |         0.1 |         0.1 |         0.0 |        0.0 |         0.0 |     1 |
| SELECT SCHEMA ( )                                                |         0.1 |         0.1 |         0.1 |         0.1 |         0.1 |         0.1 |         0.0 |        0.0 |         0.0 |     1 |
+------------------------------------------------------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+------------+-------------+-------+
9 rows in set, 1 warning (0.00 sec)

mysql>

```
## Memory Usage
### Total Memory
```sql
SELECT * FROM sys.memory_global_total; 

mysql> SELECT * FROM sys.memory_global_total;
+-----------------+
| total_allocated |
+-----------------+
| 140.77 MiB      |
+-----------------+
1 row in set (0.00 sec)

mysql>
```
### Thread Memory
```sql
SELECT thread_id, 
user, 
current_avg_alloc, 
current_allocated
FROM sys.memory_by_thread_by_current_bytes
```


## session management 
### Process(session) 조회 
```sql
show processlist;
mysql> show processlist;
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
| Id | User  | Host             | db   | Command     | Time | State                                                         | Info             |
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
|  2 | user1 | 172.17.0.5:35506 | NULL | Binlog Dump |  292 | Master has sent all binlog to slave; waiting for more updates | NULL             |
|  4 | root  | localhost        | NULL | Query       |    0 | starting                                                      | show processlist |
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
2 rows in set (0.00 sec)

mysql>

```
### Lock 조회 
```sql;
select * from information_schema.innodb_locks;
select * from information_schema.innodb_lock_waits;
```

### Transaction 조회 
```sql
select * from information_schema.INNODB_TRX;
```

### 세션 강제 종료 (Kill)
> kill "ID"
```
mysql> show processlist;
+----+-------+------------------+---------+-------------+------+---------------------------------------------------------------+------------------+
| Id | User  | Host             | db      | Command     | Time | State                                                         | Info             |
+----+-------+------------------+---------+-------------+------+---------------------------------------------------------------+------------------+
|  2 | user1 | 172.17.0.5:35506 | NULL    | Binlog Dump | 1369 | Master has sent all binlog to slave; waiting for more updates | NULL             |
|  6 | root  | localhost        | NULL    | Query       |    0 | starting                                                      | show processlist |
|  9 | user1 | localhost        | repl_db | Sleep       |    2 |                                                               | NULL             |
+----+-------+------------------+---------+-------------+------+---------------------------------------------------------------+------------------+
3 rows in set (0.01 sec)

mysql> kill "9"
    -> ;
Query OK, 0 rows affected (0.00 sec)

mysql> show processlist;
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
| Id | User  | Host             | db   | Command     | Time | State                                                         | Info             |
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
|  2 | user1 | 172.17.0.5:35506 | NULL | Binlog Dump | 1409 | Master has sent all binlog to slave; waiting for more updates | NULL             |
|  6 | root  | localhost        | NULL | Query       |    0 | starting                                                      | show processlist |
+----+-------+------------------+------+-------------+------+---------------------------------------------------------------+------------------+
2 rows in set (0.00 sec)

mysql>
```

## Storage Engine


### Innodb 

- 트랜잭션–세이프 (transaction-safe) 엔진
- commit, rollback, 장애복구, row-level locking, 외래키 등의 다양한 기능 지원
- row-level lock(행 단위)을 사용하기 때문에 변경 작업(insert, update, delete) 속도가 빠름
- Full-text 인덱싱이 불가능
- 데이터 무결성 보장
- ibdata1, ibdata2 과 같은 파일에 index 및 파일데이터가 저장
- DB 및 테이블 정보는 /usr/local/mysql/data/DB명/테이블명.frm 과 같은 구조로 이루어져 있음
- 백업 시 ibdata1와 같은 파일과 /usr/local/mysql/data/DB명/테이블명.frm 파일을 복사하여 백업
- MyIsam에 비해 약 1.5~2.5배 정도 파일이 커짐
- 테이블 단위의 hot backup(파일복사)가 불가능
- mysqldump나 db 전체적인 복사가 필요

#### Clustererd Index 
https://12bme.tistory.com/149?category=682920

클러스터링 인덱스는 테이블의 프라이머리 키에 대해서만 적용되는 내용입니다. 즉 프라이머리 키값이 비슷한 레코드끼리 묶어서 저장하는 것을 클러스터링 인덱스라고 표현합니다. 중요한 것은 프라이머리 키값에 의해 레코드의 저장 위치가 결정된다는 것입니다. 또한 프라이머리 키값이 변경된다면 그 레코드의 물리적인 저장 위치가 바뀌어야 한다는 것을 의미하기도 합니다. 프라이머리 키값으로 클러스터링된 테이블은 프라이머리 키값 자체에 대한 의존도가 상당히 크기 때문에 신중히 프라이머리 키를 결정해야 합니다.

클러스터링 인덱스 구조를 보면 클러스터링 테이블의 구조 자체는 일반 B-Tree와 많이 비슷하게 닮아 있습니다. 하지만 B-Tree의 리프 노드와는 달리 클러스터링 인덱스의 리프 노드에는 레코드의 모든 컬럼이 같이 저장되어 있습니다. 즉 클러스터링 테이블은 그 자체가 하나의 거대한 인덱스 구조로 관리되는 것입니다.

> 프라이머리 키가 없는 경우에는 InnoDB 스토리지 엔진이 다음의 우선순위대로 프라이머리 키를 대체할 칼럼을 선택합니다.


#### Secondary Index 
InnoDB 테이블(클러스터 테이블)의 모든 보조 인덱스는 해당 레코드가 저장된 주소가 아니라 프라이머리 키값을 저장하도록 구현돼 있습니다.

#### 클러스터 인덱스의 장점과 단점

  MyISAM과 같은 일반 클러스터 되지 않은 일반 프라이머리 키와 클러스터 인덱스를 비교했을 때의 상대적인 장단점을 정리하면 다음과 같습니다.

* 장점

  프라이머리 키(클러스터 키)로 검색할 때 처리 성능이 매우 빠름(특히, 프라이머리 키를 범위 검색하는 경우 매우 빠름)
  테이블의 모든 보조 인덱스가 프라이머리 키를 가지고 있기 때문에 인덱스만으로 처리될 수 있는 경우가 많음(이를 커버링 인덱스라고 함)
* 단점

  테이블의 모든 보조 인덱스가 클러스터 키를 갖기 때문에 클러스터 키값의 크기가 클 경우 전체적으로 인덱스의 크기가 커짐
  보조 인덱스를 통해 검색할 때 프라이머리 키로 다시 한번 검색해야 하므로 처리 성능이 조금 느림
  INSERT할 때 프라이머리 키에 의해 레코드의 저장 위치가 결정되기 때문에 처리 성능이 느림
  프라이머리 키를 변경할 때 레코드를 DELETE하고 INSERT하는 작업이 필요하기 때문에 처리 성능이 느림

#### Auto increment
로그 테이블과 같이 조회보다는 INSERT 위주의 테이블들은 AUTO_INCREMENT를 이용한 인조 식별자를 프라이머리 키로 설정하는 것이 성능 향상에 도움이 됩니다.


### MyISAM 엔진
- ISAM(Indexed Sequential Access Method)의 단점을 보완하기 위해 나온 업그레이드 버전
- 비–트랜잭션–세이프(non-transaction-safe) 엔진
- 읽기 작업(Select) 속도가 빠름
- table-level lock을 사용하기 때문에 쓰기 작업(insert,update) 속도가 느림
- Full-text 인덱싱이 가능하여 검색하고자 하는 내용에 대한 복합검색이 가능
- 데이터 무결성 보장이 되지 않음
- 인덱스(.MYI)와 데이터 파일(.MYD)가 분리
- 백업 시 /usr/local/mysql/data/DB명 을 전체백업
- innodb보다 파일 크기가 작음
- 테이블 단위의 hot backup(파일 복사)을 할 수 있음
- 테이블 파일만 있더라도 복구가 가능

- /usr/local/mysql/data/DB명/테이블명.frm => 테이블 구조
- /usr/local/mysql/data/DB명/테이블명.MYD => Myisam Type 테이블의 DATA  
- /usr/local/mysql/data/DB명/테이블명.MYI => Myisam Type 테이블의 index


## monitoring query 
세션 및 트랜잭션 참조
### Thread Monigoring
```sql
show status where variable_name in (
    'max_used_connections',
    'aborted_clients',
    'aborted_connects',
    'threads_connected',
    'connections'
    );
```

### Table size
```sql
SELECT TABLE_NAME AS "Tables",
                     round(((data_length + index_length) / 1024 / 1024), 2) "Size in MB"
FROM information_schema.TABLES
ORDER BY (data_length + index_length) DESC;
```
## PMM2 Monitoring

https://rastalion.me/archives/882

$ pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.17.0.6:443


pmm-admin add mysql --query-source=perfschema --username=user1 --password=Mysql123! repl_db 172.17.0.4:3306


### 참고 
- https://aws.amazon.com/ko/blogs/database/best-practices-for-configuring-parameters-for-amazon-rds-for-mysql-part-1-parameters-related-to-performance/

> 잡다한 팁
- https://bstar36.tistory.com/category/MYSQL%20and%20Maria?page=26