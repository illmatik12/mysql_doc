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


## 참고 
- https://woowabros.github.io/experience/2018/05/28/billingjul.html
- https://hyunki1019.tistory.com/94?category=665171
- https://bstar36.tistory.com/342
