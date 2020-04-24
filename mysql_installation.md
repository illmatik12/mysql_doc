# Mysql installation 
## Version
```
[root@9129d64aed67 log]# mysql --version
mysql  Ver 14.14 Distrib 5.7.29, for Linux (x86_64) using  EditLine wrapper
[root@9129d64aed67 log]#
```

## single 
```
yum install mysql-community-server

mysql_secure_installation
> root 암호 입력 mysql log 참고 

```
## local install 
* bundle tar download 
```
yum localinstall mysql-community-common* mysql-community-libs* mysql-community-client* mysql-community-server-5*

```

* 참고 : https://yamoe.tistory.com/547


## replication
## mha 구성
test 환경 구성 문제로 docker 기반으로 진행한다.
- mha_mgr : mha manager , 172.17.0.3
- mha1 : mha master , 172.17.0.4
- mha2 : mha slave , 172.17.0.5
```
docker run --privileged --name mha_mgr -it -d -e container=docker -v /sys/fs/cgroup:/sys/fs/cgroup centos:7 /usr/sbin/init

docker run --privileged --name mha1 -it -d -e container=docker -v /sys/fs/cgroup:/sys/fs/cgroup centos:7 /usr/sbin/init

docker run --privileged --name mha2 -it -d -e container=docker -v /sys/fs/cgroup:/sys/fs/cgroup centos:7 /usr/sbin/init
```



https://www.onlab.kr/2016/11/29/mha%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%9C-mariadbmysql-replication-auto-failover/
https://khj93.tistory.com/entry/MHA-MHA-%EA%B5%AC%EC%84%B1-%EB%B0%8F-%EC%84%A4%EC%B9%98-DB%EC%9D%B4%EC%A4%91%ED%99%94-Fail-Over-%ED%85%8C%EC%8A%A4%ED%8A%B8


### MHA 설치 – 의존성 패키지 설치
* 각 replication 노드들에서 실행, 누락되는 패키지 없는지 확인한다.
```
yum list epel-release
yum install epel-release

yum -y install perl-CPAN perl-DBD-MySQL perl-Module-Install
```
https://github.com/yoshinorim/mha4mysql-manager/wiki/Installation
* manager 서버에서 실행
```
yum -y install perl-CPAN perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Module-Install
```
* mha manager download 
node도 설치 필요.
```
wget https://github.com/yoshinorim/mha4mysql-manager/archive/v0.58.tar.gz
```

* mha node downlaod 
```
wget https://github.com/yoshinorim/mha4mysql-node/archive/v0.58.tar.gz
```

* 공통
```
perl Makefile.PL
make
make install
```

### replication 설정 
https://server-talk.tistory.com/240
https://blog.boxcorea.com/wp/archives/1483
https://linuxize.com/post/how-to-configure-mysql-master-slave-replication-on-centos-7/

mysql의 replication 을 설정 한다.

#### Master 
1. mysql binary 설치 
```
rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum install -y mysql-community-server
systemctl start mysqld 
mysql_secure_installation

mysql -u root -pMysql123
```
```sql
create database repl_db default character set utf8;
create user user1@'%' identified by 'Mysql123!';
grant all privileges on repl_db.* to user1@'%' identified by 'Mysql123!';
grant replication slave on *.* to 'user1'@'%' identified by 'Mysql123!';

flush privileges;
```


2. my.conf
log_bin 권한 변경 필요.
실제 운영 환경 구성시 세부 파라미터 설정 필요.
https://www.percona.com/blog/2015/06/02/80-ram-tune-innodb_buffer_pool_size/
```
vi /etc/my.cnf
[mysqld]
log-bin=mysql-bin
server-id=1
log_bin                 = /var/log/mysql/mysql-bin
log_bin_index           = /var/log/mysql/mysql-bin.index

#innodb
innodb_buffer_pool_size = 2048M

max_allowed_packet=128M
innodb_log_file_size=128M
```

3. slave my.conf
```
server-id=2
replicate-do-db='repl_db'  // 리플리케이션DB명(생략시엔 전체DB를 리플리케이션함)
log_bin                 = /var/log/mysql/mysql-bin
log_bin_index           = /var/log/mysql/mysql-bin.index

#innodb
innodb_buffer_pool_size = 2048M

max_allowed_packet=128M
innodb_log_file_size=128M
```

4. mysqldump 
```
* export
mysqldump --single-transaction --routines --all-databases -h localhost -u root -pMysql123! > mydump.sql

* import 
mysql -u root -p -pMysql123! < mydump.sql
```

5. slave 
```
STOP SLAVE;
```
6. master 
```
show master status;

mysql> show master status\G;
*************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 581
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.00 sec)

ERROR:
No query specified

mysql>
```

7. slave 
master log position 확인.
```
CHANGE MASTER TO
MASTER_HOST='172.17.0.4',
MASTER_USER='user1',
MASTER_PASSWORD='Mysql123!',
MASTER_LOG_FILE='mysql-bin.000002',
MASTER_LOG_POS=154;

start slave;
```

### mha manager 구성 
설정시 권한 문제 확인한다.
```
GRANT ALL PRIVILEGES ON *.* TO 'mhauser'@'172.17.0.%' IDENTIFIED BY 'Mysql123!';
```
```
vi /etc/app1.cnf
...
[server default]
# mysql user and password
user=mhauser
password=Mysql123!
# working directory on the manager
manager_workdir=/var/log/masterha/app1
# manager log file
manager_log=/var/log/masterha/app1/app1.log
# working directory on MySQL servers
remote_workdir=/var/log/masterha/app1
[server1]
hostname=172.17.0.4 
master_binlog_dir=/var/lib/mysql
candidate_master=1
[server2]
hostname=172.17.0.5 
master_binlog_dir=/var/lib/mysql
candidate_master=1
```

#### SSH key 설정
> docker 이미지에 ssh가 안깔려 있다면 설치한다. ssh 설정 참조
```
yum install -y openssh-server openssh-clients

ssh-keyget -t rsa


ssh-copy-id root@172.17.0.3
ssh-copy-id root@172.17.0.4 
ssh-copy-id root@172.17.0.5
```
#### ssh 접속 테스트 실행

```
masterha_check_ssh --conf=/etc/app1.cnf
```
#### Replication 체크
> replication이 안될때 slave 상태 확인.
```
masterha_check_repl --conf=/etc/app1.cnf
```

#### VIP Setting
vip를 사용할 경우 방법을 기재한다.


#### mha manager 구동
```
masterha_manager --conf=/etc/app1.cnf
```
#### Failover
```
Tue Mar 10 00:59:02 2020 - [warning] Connection failed 2 time(s)..
Tue Mar 10 00:59:05 2020 - [warning] Got error on MySQL connect: 2003 (Can't connect to MySQL server on '172.17.0.4' (111))
Tue Mar 10 00:59:05 2020 - [warning] Connection failed 3 time(s)..
Tue Mar 10 00:59:08 2020 - [warning] Got error on MySQL connect: 2003 (Can't connect to MySQL server on '172.17.0.4' (111))
Tue Mar 10 00:59:08 2020 - [warning] Connection failed 4 time(s)..
Tue Mar 10 00:59:08 2020 - [warning] Master is not reachable from health checker!
Tue Mar 10 00:59:08 2020 - [warning] Master 172.17.0.4(172.17.0.4:3306) is not reachable!
Tue Mar 10 00:59:08 2020 - [warning] SSH is reachable.
Tue Mar 10 00:59:08 2020 - [info] Connecting to a master server failed. Reading configuration file /etc/masterha_default.cnf and /etc/app1.cnf again, and trying to connect to all servers to check server status..
Tue Mar 10 00:59:08 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue Mar 10 00:59:08 2020 - [info] Reading application default configuration from /etc/app1.cnf..
Tue Mar 10 00:59:08 2020 - [info] Reading server configuration from /etc/app1.cnf..
Tue Mar 10 00:59:09 2020 - [info] GTID failover mode = 0
Tue Mar 10 00:59:09 2020 - [info] Dead Servers:
Tue Mar 10 00:59:09 2020 - [info]   172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:09 2020 - [info] Alive Servers:
Tue Mar 10 00:59:09 2020 - [info]   172.17.0.5(172.17.0.5:3306)
Tue Mar 10 00:59:09 2020 - [info] Alive Slaves:
Tue Mar 10 00:59:09 2020 - [info]   172.17.0.5(172.17.0.5:3306)  Version=5.7.29-log (oldest major version between slaves) log-bin:enabled
Tue Mar 10 00:59:09 2020 - [info]     Replicating from 172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:09 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Mar 10 00:59:09 2020 - [info] Checking slave configurations..
Tue Mar 10 00:59:09 2020 - [info]  read_only=1 is not set on slave 172.17.0.5(172.17.0.5:3306).
Tue Mar 10 00:59:09 2020 - [warning]  relay_log_purge=0 is not set on slave 172.17.0.5(172.17.0.5:3306).
Tue Mar 10 00:59:09 2020 - [info] Checking replication filtering settings..
Tue Mar 10 00:59:09 2020 - [info]  Replication filtering check ok.
Tue Mar 10 00:59:09 2020 - [info] Master is down!
Tue Mar 10 00:59:09 2020 - [info] Terminating monitoring script.
Tue Mar 10 00:59:09 2020 - [info] Got exit code 20 (Master dead).
Tue Mar 10 00:59:09 2020 - [info] MHA::MasterFailover version 0.58.
Tue Mar 10 00:59:09 2020 - [info] Starting master failover.
Tue Mar 10 00:59:09 2020 - [info]
Tue Mar 10 00:59:09 2020 - [info] * Phase 1: Configuration Check Phase..
Tue Mar 10 00:59:09 2020 - [info]
Tue Mar 10 00:59:10 2020 - [info] GTID failover mode = 0
Tue Mar 10 00:59:10 2020 - [info] Dead Servers:
Tue Mar 10 00:59:10 2020 - [info]   172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:10 2020 - [info] Checking master reachability via MySQL(double check)...
Tue Mar 10 00:59:10 2020 - [info]  ok.
Tue Mar 10 00:59:10 2020 - [info] Alive Servers:
Tue Mar 10 00:59:10 2020 - [info]   172.17.0.5(172.17.0.5:3306)
Tue Mar 10 00:59:10 2020 - [info] Alive Slaves:
Tue Mar 10 00:59:10 2020 - [info]   172.17.0.5(172.17.0.5:3306)  Version=5.7.29-log (oldest major version between slaves) log-bin:enabled
Tue Mar 10 00:59:10 2020 - [info]     Replicating from 172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:10 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Mar 10 00:59:10 2020 - [info] Starting Non-GTID based failover.
Tue Mar 10 00:59:10 2020 - [info]
Tue Mar 10 00:59:10 2020 - [info] ** Phase 1: Configuration Check Phase completed.
Tue Mar 10 00:59:10 2020 - [info]
Tue Mar 10 00:59:10 2020 - [info] * Phase 2: Dead Master Shutdown Phase..
Tue Mar 10 00:59:10 2020 - [info]
Tue Mar 10 00:59:10 2020 - [info] Forcing shutdown so that applications never connect to the current master..
Tue Mar 10 00:59:10 2020 - [warning] master_ip_failover_script is not set. Skipping invalidating dead master IP address.
Tue Mar 10 00:59:10 2020 - [warning] shutdown_script is not set. Skipping explicit shutting down of the dead master.
Tue Mar 10 00:59:11 2020 - [info] * Phase 2: Dead Master Shutdown Phase completed.
Tue Mar 10 00:59:11 2020 - [info]
Tue Mar 10 00:59:11 2020 - [info] * Phase 3: Master Recovery Phase..
Tue Mar 10 00:59:11 2020 - [info]
Tue Mar 10 00:59:11 2020 - [info] * Phase 3.1: Getting Latest Slaves Phase..
Tue Mar 10 00:59:11 2020 - [info]
Tue Mar 10 00:59:11 2020 - [info] The latest binary log file/position on all slaves is mysql-bin.000002:672
Tue Mar 10 00:59:11 2020 - [info] Latest slaves (Slaves that received relay log files to the latest):
Tue Mar 10 00:59:11 2020 - [info]   172.17.0.5(172.17.0.5:3306)  Version=5.7.29-log (oldest major version between slaves) log-bin:enabled
Tue Mar 10 00:59:11 2020 - [info]     Replicating from 172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:11 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Mar 10 00:59:11 2020 - [info] The oldest binary log file/position on all slaves is mysql-bin.000002:672
Tue Mar 10 00:59:11 2020 - [info] Oldest slaves:
Tue Mar 10 00:59:11 2020 - [info]   172.17.0.5(172.17.0.5:3306)  Version=5.7.29-log (oldest major version between slaves) log-bin:enabled
Tue Mar 10 00:59:11 2020 - [info]     Replicating from 172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:11 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Mar 10 00:59:11 2020 - [info]
Tue Mar 10 00:59:11 2020 - [info] * Phase 3.2: Saving Dead Master's Binlog Phase..
Tue Mar 10 00:59:11 2020 - [info]
Tue Mar 10 00:59:11 2020 - [info] Fetching dead master's binary logs..
Tue Mar 10 00:59:11 2020 - [info] Executing command on the dead master 172.17.0.4(172.17.0.4:3306): save_binary_logs --command=save --start_file=mysql-bin.000002  --start_pos=672 --binlog_dir=/var/lib/mysql --output_file=/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.58
  Creating /var/log/masterha/app1 if not exists..    ok.
 Concat binary/relay logs from mysql-bin.000002 pos 672 to mysql-bin.000003 EOF into /var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog ..
 Binlog Checksum enabled
  Dumping binlog format description event, from position 0 to 154.. ok.
  No need to dump effective binlog data from /var/lib/mysql/mysql-bin.000002 (pos starts 672, filesize 672). Skipping.
  Dumping binlog head events (rotate events), skipping format description events from /var/lib/mysql/mysql-bin.000003..  Binlog Checksum enabled
dumped up to pos 154. ok.
  Dumping effective binlog data from /var/lib/mysql/mysql-bin.000003 position 154 to tail(177).. ok.
 Binlog Checksum enabled
 Concat succeeded.
Tue Mar 10 00:59:12 2020 - [info] scp from root@172.17.0.4:/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog to local:/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog succeeded.
Tue Mar 10 00:59:12 2020 - [info] HealthCheck: SSH to 172.17.0.5 is reachable.
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info] * Phase 3.3: Determining New Master Phase..
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info] Finding the latest slave that has all relay logs for recovering other slaves..
Tue Mar 10 00:59:12 2020 - [info] All slaves received relay logs to the same position. No need to resync each other.
Tue Mar 10 00:59:12 2020 - [info] Searching new master from slaves..
Tue Mar 10 00:59:12 2020 - [info]  Candidate masters from the configuration file:
Tue Mar 10 00:59:12 2020 - [info]   172.17.0.5(172.17.0.5:3306)  Version=5.7.29-log (oldest major version between slaves) log-bin:enabled
Tue Mar 10 00:59:12 2020 - [info]     Replicating from 172.17.0.4(172.17.0.4:3306)
Tue Mar 10 00:59:12 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Tue Mar 10 00:59:12 2020 - [info]  Non-candidate masters:
Tue Mar 10 00:59:12 2020 - [info]  Searching from candidate_master slaves which have received the latest relay log events..
Tue Mar 10 00:59:12 2020 - [info] New master is 172.17.0.5(172.17.0.5:3306)
Tue Mar 10 00:59:12 2020 - [info] Starting master failover..
Tue Mar 10 00:59:12 2020 - [info]
From:
172.17.0.4(172.17.0.4:3306) (current master)
 +--172.17.0.5(172.17.0.5:3306)

To:
172.17.0.5(172.17.0.5:3306) (new master)
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info] * Phase 3.4: New Master Diff Log Generation Phase..
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info]  This server has all relay logs. No need to generate diff files from the latest slave.
Tue Mar 10 00:59:12 2020 - [info] Sending binlog..
Tue Mar 10 00:59:12 2020 - [info] scp from local:/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog to root@172.17.0.5:/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog succeeded.
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info] * Phase 3.5: Master Log Apply Phase..
Tue Mar 10 00:59:12 2020 - [info]
Tue Mar 10 00:59:12 2020 - [info] *NOTICE: If any error happens from this phase, manual recovery is needed.
Tue Mar 10 00:59:12 2020 - [info] Starting recovery on 172.17.0.5(172.17.0.5:3306)..
Tue Mar 10 00:59:12 2020 - [info]  Generating diffs succeeded.
Tue Mar 10 00:59:12 2020 - [info] Waiting until all relay logs are applied.
Tue Mar 10 00:59:12 2020 - [info]  done.
Tue Mar 10 00:59:12 2020 - [info] Getting slave status..
Tue Mar 10 00:59:12 2020 - [info] This slave(172.17.0.5)'s Exec_Master_Log_Pos equals to Read_Master_Log_Pos(mysql-bin.000002:672). No need to recover from Exec_Master_Log_Pos.
Tue Mar 10 00:59:12 2020 - [info] Connecting to the target slave host 172.17.0.5, running recover script..
Tue Mar 10 00:59:12 2020 - [info] Executing command: apply_diff_relay_logs --command=apply --slave_user='mhauser' --slave_host=172.17.0.5 --slave_ip=172.17.0.5  --slave_port=3306 --apply_files=/var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog --workdir=/var/log/masterha/app1 --target_version=5.7.29-log --timestamp=20200310005909 --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.58 --slave_pass=xxx
Tue Mar 10 00:59:13 2020 - [info]
MySQL client version is 5.7.29. Using --binary-mode.
Applying differential binary/relay log files /var/log/masterha/app1/saved_master_binlog_from_172.17.0.4_3306_20200310005909.binlog on 172.17.0.5:3306. This may take long time...
Applying log files succeeded.
Tue Mar 10 00:59:13 2020 - [info]  All relay logs were successfully applied.
Tue Mar 10 00:59:13 2020 - [info] Getting new master's binlog name and position..
Tue Mar 10 00:59:13 2020 - [info]  mysql-bin.000002:590
Tue Mar 10 00:59:13 2020 - [info]  All other slaves should start replication from here. Statement should be: CHANGE MASTER TO MASTER_HOST='172.17.0.5', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=590, MASTER_USER='user1', MASTER_PASSWORD='xxx';
Tue Mar 10 00:59:13 2020 - [warning] master_ip_failover_script is not set. Skipping taking over new master IP address.
Tue Mar 10 00:59:13 2020 - [info] ** Finished master recovery successfully.
Tue Mar 10 00:59:13 2020 - [info] * Phase 3: Master Recovery Phase completed.
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] * Phase 4: Slaves Recovery Phase..
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] * Phase 4.1: Starting Parallel Slave Diff Log Generation Phase..
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] Generating relay diff files from the latest slave succeeded.
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] * Phase 4.2: Starting Parallel Slave Log Apply Phase..
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] All new slave servers recovered successfully.
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] * Phase 5: New master cleanup phase..
Tue Mar 10 00:59:13 2020 - [info]
Tue Mar 10 00:59:13 2020 - [info] Resetting slave info on the new master..
Tue Mar 10 00:59:13 2020 - [info]  172.17.0.5: Resetting slave info succeeded.
Tue Mar 10 00:59:13 2020 - [info] Master failover to 172.17.0.5(172.17.0.5:3306) completed successfully.
Tue Mar 10 00:59:13 2020 - [info]

----- Failover Report -----

app1: MySQL Master failover 172.17.0.4(172.17.0.4:3306) to 172.17.0.5(172.17.0.5:3306) succeeded

Master 172.17.0.4(172.17.0.4:3306) is down!

Check MHA Manager logs at 252214f7c5d4:/var/log/masterha/app1/app1.log for details.

Started automated(non-interactive) failover.
The latest slave 172.17.0.5(172.17.0.5:3306) has all relay logs for recovery.
Selected 172.17.0.5(172.17.0.5:3306) as a new master.
172.17.0.5(172.17.0.5:3306): OK: Applying all logs succeeded.
Generating relay diff files from the latest slave succeeded.
172.17.0.5(172.17.0.5:3306): Resetting slave info succeeded.
Master failover to 172.17.0.5(172.17.0.5:3306) completed successfully.
```

slave 재구성 , log에 MASTER_LOG_POS 기록되어 있다.
```sql
CHANGE MASTER TO MASTER_HOST='172.17.0.5', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=590, MASTER_USER='user1', MASTER_PASSWORD='Mysql123!';
```

#### FAILBACK 
강제로 master switch over 후 slave replication 재시작
```
rm -f /var/log/masterha/app1/app1.failover.complete
masterha_master_switch --master_state=alive --conf=/etc/app1.cnf

stop slave;
CHANGE MASTER TO MASTER_HOST='172.17.0.4', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000004', MASTER_LOG_POS=154, MASTER_USER='user1', MASTER_PASSWORD='Mysql123!';
start slave;

masterha_manager --conf=/etc/app1.cnf
```

#### reboot 
> reboot 순서
1. manager 종료
2. slave 종료
3. master 종료 
4. master 기동
5. slave 기동
6. manager 기동

## mmm 구성 

## Shard