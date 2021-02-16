
# Backup
## full backup

```bash
mariabackup --backup --user root --password Mysql123! --target-dir /backup/full --no-lock
```
## incremental backup
```bash
mariabackup --backup --user root --password Mysql123! --target-dir /backup/inc1 --incremental-basedir=/backup/full --no-lock 
mariabackup --backup --user root --password Mysql123! --target-dir /backup/inc2 --incremental-basedir=/backup/inc1 --no-lock 
mariabackup --backup --user root --password Mysql123! --target-dir /backup/inc3 --incremental-basedir=/backup/inc2 --no-lock 
```


# Restore
## preparing the backup

```
mariabackup --prepare --target-dir /backup/full --incremental-basedir=/backup/inc1  
mariabackup --prepare --target-dir /backup/full --incremental-basedir=/backup/inc2  
mariabackup --prepare --target-dir /backup/full --incremental-basedir=/backup/inc3  
```

# restoring backup
```
mariabackup --copy-back --target-dir=/backup/full
```

# set permission
```
$ chown -R mysql:mysql /var/lib/mysql/
```

## 완전 복구 
- incremental 백업 본 까지 적용한 database에 binlog의 정보를 추출하여 적용한다. 
- 복구 sql 수행 시 포지션이 정확하지 않은지 duplicate 오류가 발생하여서 sql을 직접 편집하였다. 

```
mysqlbinlog --start-position 456485 mysql-bin.000001  > recovery.sql

mysql < recovery.sql
```


# Troubleshooting
## mariadb 기동시 아래 메시지 발생할 경우 강제 rollback 처리 해줘야함
- mysqld --tc-heuristic-recover=rollback
```
2020-08-31 15:22:47 0 [ERROR] Found 1 prepared transactions! It means that mysqld was not shut down properly last time and cri
tical recovery information (last binlog or tc.log file) was manually deleted after a crash. You have to start mysqld with --tc
-heuristic-recover switch to commit or rollback pending transactions.
```

## binlog apply 
- incremental recovery 시점 이후 transaction 로그 반영 
- mysql  < recovery.sql
- duplicate 발생시 rollback -f option 추가
```
[root@bpobackuptest binary]# mysql -f < recovery.sql 
ERROR 1062 (23000) at line 39: Duplicate entry '6144' for key 'PRIMARY'
[root@bpobackuptest binary]# 
```
