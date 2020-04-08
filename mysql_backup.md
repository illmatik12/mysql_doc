# Backup 
## mysqldump 
```
mysqldump --single-transaction --routines --all-databases -h localhost -u root -pMysql123! > mydump.sql

```
## xtrabackup  

### Install

```bash
yum install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm

[root@53364085d678 /]# yum install percona-xtrabackup-24.x86_64
Loaded plugins: fastestmirror, ovl
Loading mirror speeds from cached hostfile
 * base: mirror.kakao.com
 * epel: mirrors.thzhost.com
 * extras: mirror.kakao.com
 * updates: mirror.kakao.com
Resolving Dependencies
--> Running transaction check
---> Package percona-xtrabackup-24.x86_64 0:2.4.19-1.el7 will be installed
--> Processing Dependency: rsync for package: percona-xtrabackup-24-2.4.19-1.el7.x86_64
--> Processing Dependency: libev.so.4()(64bit) for package: percona-xtrabackup-24-2.4.19-1.el7.x86_64
--> Running transaction check
---> Package libev.x86_64 0:4.15-7.el7 will be installed
---> Package rsync.x86_64 0:3.1.2-6.el7_6.1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=====================================================================================================================
 Package                         Arch             Version                     Repository                        Size
=====================================================================================================================
Installing:
 percona-xtrabackup-24           x86_64           2.4.19-1.el7                percona-release-x86_64           7.6 M
Installing for dependencies:
 libev                           x86_64           4.15-7.el7                  extras                            44 k
 rsync                           x86_64           3.1.2-6.el7_6.1             base                             404 k

Transaction Summary
=====================================================================================================================
Install  1 Package (+2 Dependent packages)

Total download size: 8.0 M
Installed size: 8.4 M
Is this ok [y/d/N]: y
Downloading packages:
(1/3): libev-4.15-7.el7.x86_64.rpm                                                            |  44 kB  00:00:00
(2/3): rsync-3.1.2-6.el7_6.1.x86_64.rpm                                                       | 404 kB  00:00:00
(3/3): percona-xtrabackup-24-2.4.19-1.el7.x86_64.rpm                                          | 7.6 MB  00:00:13
---------------------------------------------------------------------------------------------------------------------
Total                                                                                596 kB/s | 8.0 MB  00:00:13
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : rsync-3.1.2-6.el7_6.1.x86_64                                                                      1/3
  Installing : libev-4.15-7.el7.x86_64                                                                           2/3
  Installing : percona-xtrabackup-24-2.4.19-1.el7.x86_64                                                         3/3
  Verifying  : percona-xtrabackup-24-2.4.19-1.el7.x86_64                                                         1/3
  Verifying  : libev-4.15-7.el7.x86_64                                                                           2/3
  Verifying  : rsync-3.1.2-6.el7_6.1.x86_64                                                                      3/3

Installed:
  percona-xtrabackup-24.x86_64 0:2.4.19-1.el7

Dependency Installed:
  libev.x86_64 0:4.15-7.el7                              rsync.x86_64 0:3.1.2-6.el7_6.1

Complete!
[root@53364085d678 /]#
[root@53364085d678 /]#
[root@53364085d678 /]#
[root@53364085d678 /]# yum list installed | grep percona-xtrabackup
percona-xtrabackup-24.x86_64        2.4.19-1.el7             @percona-release-x86_64
[root@53364085d678 /]#
```

### xtrabackup User 생성 
#### Local backup
```sql
CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY 'Xtra123!' ;

GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost' ;

FLUSH PRIVILEGES ;
```
#### Remote backup
```sql
CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY 'Xtra123!' ;

GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'%' ;

FLUSH PRIVILEGES ;
```
#### Backup 경로 설정
```bash
mkdir /xbackup

mkdir /xbackup/maria5

mkdir /xbackup/maria10
mkdir /xbackup/mysql5

chown -R mysql:mysql /xbackup

```


#### fullbackup
```
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --user xtrabackup --password Xtra123! --socket=/var/lib/mysql/mysql.sock /xbackup/mysql5

```
```bash
[root@53364085d678 ~]# /usr/bin/innobackupex --defaults-file=/etc/my.cnf --user xtrabackup --password Xtra123! --socket=/var/lib/mysql/mysql.sock /xbackup/mysql5
xtrabackup: recognized server arguments: --log_bin=/var/log/mysql/mysql-bin --datadir=/var/lib/mysql --log_bin=mysql-bin --server-id=1 --innodb_buffer_pool_size=2048M --innodb_log_file_size=128M
xtrabackup: recognized client arguments:
200407 10:04:58 innobackupex: Starting the backup operation

IMPORTANT: Please check that the backup run completes successfully.
           At the end of a successful backup run innobackupex
           prints "completed OK!".

200407 10:04:58  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;mysql_socket=/var/lib/mysql/mysql.sock' as 'xtrabackup'  (using password: YES).
200407 10:04:58  version_check Connected to MySQL server
200407 10:04:58  version_check Executing a version check against the server...

... 중략 ...
200407 10:05:06 Finished backing up non-InnoDB tables and files
200407 10:05:06 [00] Writing /xbackup/mysql5/2020-04-07_10-04-58/xtrabackup_binlog_info
200407 10:05:06 [00]        ...done
200407 10:05:06 Executing FLUSH NO_WRITE_TO_BINLOG ENGINE LOGS...
xtrabackup: The latest check point (for incremental): '14118995'
xtrabackup: Stopping log copying thread.
.200407 10:05:06 >> log scanned up to (14119004)

200407 10:05:07 Executing UNLOCK TABLES
200407 10:05:07 All tables unlocked
200407 10:05:07 [00] Copying ib_buffer_pool to /xbackup/mysql5/2020-04-07_10-04-58/ib_buffer_pool
200407 10:05:07 [00]        ...done
200407 10:05:07 Backup created in directory '/xbackup/mysql5/2020-04-07_10-04-58/'
MySQL binlog position: filename 'mysql-bin.000008', position '10264351'
200407 10:05:07 [00] Writing /xbackup/mysql5/2020-04-07_10-04-58/backup-my.cnf
200407 10:05:07 [00]        ...done
200407 10:05:07 [00] Writing /xbackup/mysql5/2020-04-07_10-04-58/xtrabackup_info
200407 10:05:07 [00]        ...done
xtrabackup: Transaction log of lsn (14118995) to (14119004) was copied.
200407 10:05:07 completed OK!
[root@53364085d678 ~]#
[root@53364085d678 ~]#
[root@53364085d678 ~]#

[root@53364085d678 2020-04-07_10-04-58]# ls -al
total 12344
drwxr-x--- 6 root  root      4096 Apr  7 10:05 .
drwxr-xr-x 4 mysql mysql       60 Apr  7 10:04 ..
-rw-r----- 1 root  root       488 Apr  7 10:05 backup-my.cnf
-rw-r----- 1 root  root       323 Apr  7 10:05 ib_buffer_pool
-rw-r----- 1 root  root  12582912 Apr  7 10:05 ibdata1
drwxr-x--- 2 root  root      4096 Apr  7 10:05 mysql
drwxr-x--- 2 root  root      8192 Apr  7 10:05 performance_schema
drwxr-x--- 2 root  root        76 Apr  7 10:05 repl_db
drwxr-x--- 2 root  root      8192 Apr  7 10:05 sys
-rw-r----- 1 root  root        26 Apr  7 10:05 xtrabackup_binlog_info
-rw-r----- 1 root  root       138 Apr  7 10:05 xtrabackup_checkpoints
-rw-r----- 1 root  root       557 Apr  7 10:05 xtrabackup_info
-rw-r----- 1 root  root      2560 Apr  7 10:05 xtrabackup_logfile
[root@53364085d678 2020-04-07_10-04-58]#

```

#### Recovery
- --copy-back 옵션 사용
- --apply-log 최신 로그 내용 반영
```
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --copy-back /xbackup/mysql5/2020-04-07_10-04-58

#데이터 디렉토리가 지정되지 않을경우 옵션으로 지정해줌. 
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --datadir=/recovery_path --copy-back /xbackup/mysql5/2020-04-07_10-04-58


/usr/bin/innobackupex --defaults-file=/etc/my.cnf --datadir=/mysql_recovery --copy-back /xbackup/mysql5/2020-04-07_10-04-58

```
실행결과 
```bash
[root@53364085d678 ~]# /usr/bin/innobackupex --defaults-file=/etc/my.cnf --datadir=/mysql_recovery --copy-back /xbackup/mysql5/2020-04-07_10-04-58
xtrabackup: recognized server arguments: --log_bin=/var/log/mysql/mysql-bin --datadir=/var/lib/mysql --log_bin=mysql-bin --server-id=1 --innodb_buffer_pool_size=2048M --innodb_log_file_size=128M --datadir=/mysql_recovery
xtrabackup: recognized client arguments:
200407 10:14:54 innobackupex: Starting the copy-back operation

IMPORTANT: Please check that the copy-back run completes successfully.
           At the end of a successful copy-back run innobackupex
           prints "completed OK!".

/usr/bin/innobackupex version 2.4.19 based on MySQL server 5.7.26 Linux (x86_64) (revision id: c2d69da)
200407 10:14:54 [01] Copying ibdata1 to /mysql_recovery/ibdata1
200407 10:14:54 [01]        ...done

... 중략 ...

200407 10:15:04 [01] Copying ./xtrabackup_info to /mysql_recovery/xtrabackup_info
200407 10:15:04 [01]        ...done
200407 10:15:05 completed OK!
[root@53364085d678 ~]#
```
#### DB 기동 
권한 복구 후 기동 



### Innodb force recovery
* recovery 옵션 값 설명
```
– 0 기본값

– 1 (SRV_FORCE_IGNORE_CORRUPT)

서버가 깨진 페이지를 발견한다고 하더라도 계속 구동하도록 만든다.

Try to make SELECT * FROM tbl_name로 하여금 깨진 인덱스 레코드와 페이지를 건너 띄도록 만들며, 이렇게 하면 테이블을 덤핑하는데 도움이 된다.

– 2 (SRV_FORCE_NO_BACKGROUND)

메인 쓰레드가 구동되지 못하도록 한다.

만일 퍼지 연산 (purge operation)이 진행되는 동안 크래시가 발생한다면, 이 복구 값은 퍼지 연산이 실행되는 것을 막게 된다.

– 3 (SRV_FORCE_NO_TRX_UNDO)

복구 다음에 트랜젝션 롤백을 실행하지 않는다.

– 4 (SRV_FORCE_NO_IBUF_MERGE)

삽입 버퍼 병합 연산 (insert buffer merge operations)까지 금지한다.

만일 이 연산이 크래시의 원인이 된다면, 그것을 실행하지 않도록 한다. 테이블 통계값을 계산하지 않도록 한다.

– 5 (SRV_FORCE_NO_UNDO_LOG_SCAN)

데이터베이스를 시작할 때 언두 로그 (undo log)를 검사하지 않는다.

InnoDB는 완벽하지 않은 트랜잭션도 실행된 것으로 다루게 된다.

– 6 (SRV_FORCE_NO_LOG_REDO)

복구 연결에서 로그 롤–포워드 (roll-forward)를 실행하지 않는다.
```

## 참고 
- https://woowabros.github.io/experience/2018/05/28/billingjul.html
- https://hyunki1019.tistory.com/94?category=665171
- https://bstar36.tistory.com/342
