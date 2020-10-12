# Trouble Shooting
## engine
### Strict Mode
mysql 5.5 version은 해당 기능이 꺼져 있어서 데이터 입력시 char size에 맞게만 데이터가 입력된다.
5.7 부터는 default 적용

## How To Troubleshoot Issues in MySQL
- https://www.digitalocean.com/community/tutorial_series/how-to-troubleshoot-issues-in-mysql



## slave 구성 오류 
```
Last_IO_Error: Fatal error: The slave I/O thread stops because master and slave have equal MySQL server ids; these ids must be different for replication to work (or the --replicate-same-server-id option must be used on slave but this does not always make sense; please check the manual before using it).
```

* ip나 데이터베이스 등 확인. 


```
  Last_IO_Error: Fatal error: The slave I/O thread stops because master and slave have equal MySQL server UUIDs; these UUIDs must be different for replication to work.
```
* auto.conf 삭제 후 재기동. 

