# file list 

```
-rwxr-xr-x.  1 root root  8390792 Aug 13 16:38 galera-25.3.28-1.rhel7.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root 11829744 Aug 13 16:26 MariaDB-client-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root 37002664 Aug 13 16:26 MariaDB-client-debuginfo-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root    82492 Aug 13 16:26 MariaDB-common-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root   184908 Aug 13 16:26 MariaDB-common-debuginfo-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root  2974108 Aug 13 16:26 MariaDB-compat-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root  7450028 Aug 13 16:26 MariaDB-devel-10.3.22-1.el7.centos.x86_64.rpm
-rwxr-xr-x.  1 root root 25519436 Aug 13 16:26 MariaDB-server-10.3.22-1.el7.centos.x86_64.rpm
```

# requirements
selinux disabled
# yum local install 

yum localinstall -y 

```
================================================================================================================================================================================================================================================================
 Package                                                    Arch                                        Version                                                          Repository                                                                        Size
================================================================================================================================================================================================================================================================
Installing:
 MariaDB-client                                             x86_64                                      10.3.22-1.el7.centos                                             /MariaDB-client-10.3.22-1.el7.centos.x86_64                                       58 M
 MariaDB-server                                             x86_64                                      10.3.22-1.el7.centos                                             /MariaDB-server-10.3.22-1.el7.centos.x86_64                                      121 M
 galera                                                     x86_64                                      25.3.28-1.rhel7.el7.centos                                       /galera-25.3.28-1.rhel7.el7.centos.x86_64                                         35 M
Installing for dependencies:
 boost-program-options                                      x86_64                                      1.53.0-27.el7                                                    RHEL-DVD                                                                         156 k

Transaction Summary
================================================================================================================================================================================================================================================================
Install  3 Packages (+1 Dependent package)

Total size: 213 M
Total download size: 156 k
Installed size: 214 M
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-client-10.3.22-1.el7.centos.x86_64                                                                                                                                                                                                   1/4 
  Installing : boost-program-options-1.53.0-27.el7.x86_64                                                                                                                                                                                                   2/4 
  Installing : galera-25.3.28-1.rhel7.el7.centos.x86_64                                                                                                                                                                                                     3/4 
  Installing : MariaDB-server-10.3.22-1.el7.centos.x86_64                                                                                                                                                                                                   4/4 


PLEASE REMEMBER TO SET A PASSWORD FOR THE MariaDB root USER !
To do so, start the server, then issue the following commands:

'/usr/bin/mysqladmin' -u root password 'new-password'
'/usr/bin/mysqladmin' -u root -h bpobackuptest password 'new-password'

Alternatively you can run:
'/usr/bin/mysql_secure_installation'

which will also give you the option of removing the test
databases and anonymous user created by default.  This is
strongly recommended for production servers.

See the MariaDB Knowledgebase at http://mariadb.com/kb or the
MySQL manual for more instructions.

Please report any problems at http://mariadb.org/jira

The latest information about MariaDB is available at http://mariadb.org/.
You can find additional information about the MySQL part at:
http://dev.mysql.com
Consider joining MariaDB's strong and vibrant community:
https://mariadb.org/get-involved/

  Verifying  : galera-25.3.28-1.rhel7.el7.centos.x86_64                                                                                                                                                                                                     1/4 
  Verifying  : MariaDB-server-10.3.22-1.el7.centos.x86_64                                                                                                                                                                                                   2/4 
  Verifying  : boost-program-options-1.53.0-27.el7.x86_64                                                                                                                                                                                                   3/4 
  Verifying  : MariaDB-client-10.3.22-1.el7.centos.x86_64                                                                                                                                                                                                   4/4 

Installed:
  MariaDB-client.x86_64 0:10.3.22-1.el7.centos                                         MariaDB-server.x86_64 0:10.3.22-1.el7.centos                                         galera.x86_64 0:25.3.28-1.rhel7.el7.centos                                        

Dependency Installed:
  boost-program-options.x86_64 0:1.53.0-27.el7                                                                                                                                                                                                                  

Complete!
```

# systemctl status mariadb 

# config 
* /etc/my.cnf.d/server.conf

[mysqld]
character-set-server = utf8
collation-server     = utf8_general_ci
port = 13306

server-id = 1
datadir = /maria_data 

<!-- default-storage-engine = InnoDB -->




# mariabackup 
* yum localinstall MariaDB-backup-10.3.22-1.el7.centos.x86_64.rpm 


