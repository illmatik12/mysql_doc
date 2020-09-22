# Useful tips
## Mysql Sample data set
https://dev.mysql.com/doc/employee/en/employees-preface.html

## Sample query
```sql
mysql> select * from employees limit 10;
+--------+------------+------------+-----------+--------+------------+
| emp_no | birth_date | first_name | last_name | gender | hire_date  |
+--------+------------+------------+-----------+--------+------------+
|  10001 | 1953-09-02 | Georgi     | Facello   | M      | 1986-06-26 |
|  10002 | 1964-06-02 | Bezalel    | Simmel    | F      | 1985-11-21 |
|  10003 | 1959-12-03 | Parto      | Bamford   | M      | 1986-08-28 |
|  10004 | 1954-05-01 | Chirstian  | Koblick   | M      | 1986-12-01 |
|  10005 | 1955-01-21 | Kyoichi    | Maliniak  | M      | 1989-09-12 |
|  10006 | 1953-04-20 | Anneke     | Preusig   | F      | 1989-06-02 |
|  10007 | 1957-05-23 | Tzvetan    | Zielinski | F      | 1989-02-10 |
|  10008 | 1958-02-19 | Saniya     | Kalloufi  | M      | 1994-09-15 |
|  10009 | 1952-04-19 | Sumant     | Peac      | F      | 1985-02-18 |
|  10010 | 1963-06-01 | Duangkaew  | Piveteau  | F      | 1989-08-24 |
+--------+------------+------------+-----------+--------+------------+
10 rows in set (0.00 sec)

mysql>
mysql> select * from salaries limit 10;
+--------+--------+------------+------------+
| emp_no | salary | from_date  | to_date    |
+--------+--------+------------+------------+
|  10001 |  60117 | 1986-06-26 | 1987-06-26 |
|  10001 |  62102 | 1987-06-26 | 1988-06-25 |
|  10001 |  66074 | 1988-06-25 | 1989-06-25 |
|  10001 |  66596 | 1989-06-25 | 1990-06-25 |
|  10001 |  66961 | 1990-06-25 | 1991-06-25 |
|  10001 |  71046 | 1991-06-25 | 1992-06-24 |
|  10001 |  74333 | 1992-06-24 | 1993-06-24 |
|  10001 |  75286 | 1993-06-24 | 1994-06-24 |
|  10001 |  75994 | 1994-06-24 | 1995-06-24 |
|  10001 |  76884 | 1995-06-24 | 1996-06-23 |
+--------+--------+------------+------------+
10 rows in set (0.00 sec)

mysql>
```
    Q1. 전체 직원중  현재 salary 기준 평균은 얼마인가? (추가, 현재 재직중인)

```sql
A) 
SELECT avg(current_salary)
FROM 
( 
    SELECT e.emp_no , e.hire_date
    (
    select  s.salary
        from salaries s
        where s.emp_no = e.emp_no
        order by from_date desc 
        limit 1
    ) as current_salary
    FROM employees e 
) a 
;
+---------------------+
| avg(current_salary) |
+---------------------+
|          69928.7770 |
+---------------------+
1 row in set (2.25 sec)

mysql>

A2) to_date가 9999-01-01이면 재직중, 아니면 퇴사라고 가정. 

SELECT avg(current_salary)
FROM 
( 
    SELECT e.emp_no ,
    (
        select  s.salary
        from salaries s
        where s.emp_no = e.emp_no
        order by from_date desc 
        limit 1
    ) as current_salary
    FROM employees e , current_dept_emp dp
    WHERE e.emp_no = dp.emp_no
    AND dp.to_date = str_to_date('9999-01-01', '%Y-%m-%d')
) t
+---------------------+
| avg(current_salary) |
+---------------------+
|          72012.2359 |
+---------------------+
1 row in set (3.72 sec)

```

    Q2. 특정 사원의 정보를 모두 조회 하라. (emp_no 지정) 


    
```sql    
SELECT e.emp_no ,e.birth_date, e.first_name, e.last_name, e.gender, e.hire_date,
( 
    SELECT d.dept_name 
    FROM departments d
    WHERE d.dept_no = ( SELECT dp.dept_no 
                        FROM current_dept_emp dp 
                        WHERE dp.emp_no = e.emp_no 
                        )
) AS dept_name
,
(
    SELECT t.title
    FROM titles t
    WHERE t.emp_no = e.emp_no
    ORDER BY from_date DESC
    LIMIT 1
) AS title
,
(
SELECT  s.salary
    FROM salaries s
    WHERE s.emp_no = e.emp_no
    ORDER BY from_date DESC
    LIMIT 1
) AS current_salary
FROM employees e 
WHERE e.emp_no = 99999
;

-- 검증 
SELECT COUNT(*) as cnt
FROM (
SELECT e.emp_no ,e.birth_date, e.first_name, e.last_name, e.gender, e.hire_date,
( 
    SELECT d.dept_name 
    FROM departments d
    WHERE d.dept_no = ( SELECT dp.dept_no 
                        FROM current_dept_emp dp 
                        WHERE dp.emp_no = e.emp_no 
                        )
) AS dept_name
,
(
    SELECT t.title
    FROM titles t
    WHERE t.emp_no = e.emp_no
    ORDER BY from_date DESC
    LIMIT 1
) AS title
,
(
SELECT  s.salary
    FROM salaries s
    WHERE s.emp_no = e.emp_no
    ORDER BY from_date DESC
    LIMIT 1
) AS current_salary
FROM employees e 
) AS t
```

=> Scalar subquery 를 join으로 변경 



    Q3. 부서별 현재 salary 합,평균을 구하라.
```
select *
from (
select emp_no,count(*) cnt from current_dept_emp group by emp_no
) t 
WHERE cnt > 1
;
```


## Procedure Sample
```sql
use testdb;
create table board(
board_id integer auto_increment
,board_title varchar(200)
, board_content varchar(4000)
, board_date timestamp
, PRIMARY KEY(board_id)
);


DELIMITER $$
DROP PROCEDURE IF EXISTS loopInsert $$
CREATE PROCEDURE loopInsert()
BEGIN
DECLARE i INT DEFAULT 0;
WHILE (i <= 10000) DO 
INSERT INTO board (board_title, board_content, board_date)
VALUES (CONCAT('TEST',i), CONCAT('TEST_STRING',i), NOW());
SET i = i + 1;
END WHILE;
END $$
DELIMITER $$

CALL loopInsert();


create index board_idx_01 on board (board_title);
```

## buffer pool tuning
https://www.percona.com/blog/2015/06/02/80-ram-tune-innodb_buffer_pool_size/



## Slave reset 
```
reset slave all;
```