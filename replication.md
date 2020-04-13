# Replication Architecture
## binlog  
- mysql에서 출력하는 로그로 row의 내용을 저장하며 주로 replication에 사용
- 일련번호로 파일 생성.
- 변경 이력 저장.

### Binlog format 
- Statement : SQL 자체를 저장
- Row : row를 그대로 복사
- Mixed : 위의 두가지 방식 혼재.

#### Binary log 관리 
- 용량 확보를 위해 bin log 삭제 
- expire_log_days로 보관 기간 조절 가능 
- flush logs (database checkpoint, oracle switch logfile)
```sql
mysql> show binary logs;
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000002 |       672 |
| mysql-bin.000003 |       177 |
| mysql-bin.000004 |      1651 |
| mysql-bin.000005 |       446 |
| mysql-bin.000006 |       447 |
| mysql-bin.000007 |      1720 |
| mysql-bin.000008 |  10263547 |
+------------------+-----------+
7 rows in set (0.08 sec)

mysql> purge master logs to
    -> 'mysql-bin.000008';
Query OK, 0 rows affected (0.33 sec)

ysql> show variables like 'expire%';
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| expire_logs_days | 0     |
+------------------+-------+
1 row in set (0.00 sec)

mysql>
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000008 | 10264614 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

mysql> flush logs;
Query OK, 0 rows affected (0.29 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000009 |      154 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

mysql>
```

#### mysqlbinlog
- bin 로그 내용을 읽어서 텍스트 형태로 변경하여 쉽게 실행할수 있게 해줌.
- 출력 파일은 mysql 에서 바로 실행 가능함. 
- 시점 복구시 활용

```bash
mysqlbinlog /var/lib/mysql/mysql-bin.000009 > dump.txt
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#200407 13:20:40 server id 1  end_log_pos 123 CRC32 0xf4eb553a  Start: binlog v 4, server v 5.7.29-log created 200407 13:20:40
# Warning: this binlog is either in use or was not closed properly.
BINLOG '
mP+LXg8BAAAAdwAAAHsAAAABAAQANS43LjI5LWxvZwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAEzgNAAgAEgAEBAQEEgAAXwAEGggAAAAICAgCAAAACgoKKioAEjQA
ATpV6/Q=
'/*!*/;

```


## redo log 
- innodb engine 에서만 사용 (engine level)
- 트랜잭션 정보의 사용 , crash recovery 시 사용 
- redo data를 이용하여 마지막 checkpoint 부터 장애발생시점까지의 데이터 복구 
- 이후에 undo data를 복구 하여 rollback 한다. 
- database replay
- 복수의 고정된 사이즈의 파일로 이루어짐.

- https://m.blog.naver.com/PostView.nhn?blogId=parkjy76&logNo=220918956412&proxyReferer=https%3A%2F%2Fwww.google.com%2F

### 처리 흐름 
- sync_binlog : bin log sync mode에 따라 다를수 있다.
1. DML 실행
2. innodb log buffer에 기록
3. 커밋시 redo log에 flush(prepared 상태)
4. binlog에 기록
5. redo log와 binlog의 status를 완료로 변경

> dmysql은 기본적으로 비동기 복제 방식을 사용

1. 마스터 데이터베이스가 binary log를 만들어 이벤트 기록.
2. 각 슬레이브는 어떤 이벤트까지 저장되어 있는지를 기억하고 있다.
3. 슬레이브의 IO Thread를 통해서 마스터에 이벤트를 요청하고 받는다.
4. 마스터는 이벤트를 요청받으면 binlog dump thread를 통해서 클라이언트에게 이벤트를 전송한다.
5. IO thread는 전송받은 덤프 로그를 이용하여 relay log를 만든다.
6. SQL thread는 replay log를 읽어서 이벤트를 다시 실행하여 슬레이브에 데이터를 복사한다.


### 싱크 깨짐 대처 방안
- https://cusmaker.tistory.com/238

## 참고 블로그 
- http://cloudrain21.com/mysql-replication

## Mysql Proxy
- proxy server 

- https://www.slideshare.net/LeeIGoo/mysqlmariadb-proxy-software-test


## MaxScale vs ProxySQL
- 두가지 모두 부하 분산과 트랜잭션 지원 (약 13% 성능 저하)
- 운영중 DB node 추가는  ProxySQL만 가능 , MaxScale은 재시작 필요
- MaxScale 은 MariaDB의 Proxy