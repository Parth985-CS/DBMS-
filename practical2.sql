-- ============================================================
-- PRACTICAL-2 (Problem Statement 02): MySQL solution with outputs
-- ============================================================

-- 0) Fresh start
SELECT '0) Dropping & creating database' AS step;
DROP DATABASE IF EXISTS practical2;
CREATE DATABASE practical2;
USE practical2;

SET SESSION sql_safe_updates = 0;

-- ============================================================
-- 1) CREATE TABLES
-- ============================================================
SELECT '1) Creating tables: Department, Employee' AS step;

CREATE TABLE Department (
  Deptno INT PRIMARY KEY,
  Dname VARCHAR(50) NOT NULL UNIQUE,
  Location VARCHAR(50) NOT NULL
);

CREATE TABLE Employee (
  Empno INT PRIMARY KEY,
  Ename VARCHAR(100) NOT NULL,
  Job VARCHAR(30) NOT NULL,
  Mgr INT NULL,
  Joined_date DATE NOT NULL,
  Salary DECIMAL(10,2) NOT NULL CHECK (Salary >= 0),
  Commission DECIMAL(10,2) NULL,
  Deptno INT NULL,
  Address VARCHAR(100) NULL,
  CONSTRAINT fk_emp_dept FOREIGN KEY (Deptno)
      REFERENCES Department(Deptno)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mgr_emp FOREIGN KEY (Mgr)
      REFERENCES Employee(Empno)
      ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- 2) INSERT DEPARTMENTS
-- ============================================================
SELECT '2) Inserting departments' AS step;
INSERT INTO Department (Deptno, Dname, Location) VALUES
  (10, 'Accounting', 'Mumbai'),
  (20, 'Research',   'Pune'),
  (30, 'Sales',      'Nashik'),
  (40, 'Operations', 'Nagpur');

SELECT 'Departments after insert' AS info;
SELECT * FROM Department;

-- ============================================================
-- 3) INSERT EMPLOYEES
-- ============================================================
SELECT '3) Inserting employees' AS step;
INSERT INTO Employee (Empno, Ename, Job, Mgr, Joined_date, Salary, Commission, Deptno, Address) VALUES
(1004, 'Nitin Kulkarni', 'President', NULL, '1986-04-19', 50000, NULL, 10, 'Mumbai'),
(1003, 'Amit Kumar', 'Manager', 1004, '1986-04-02', 2000, NULL, 30, 'Pune'),
(1007, 'Sumit Patil', 'Manager', 1004, '1991-05-01', 25000, NULL, 20, 'Mumbai'),
(1005, 'Niraj Sharma', 'Analyst', 1003, '1998-12-03', 12000, NULL, 20, 'Satara'),
(1001, 'Nilesh Joshi', 'Clerk', 1005, '1995-12-17', 2800, 600, 20, 'Nashik'),
(1002, 'Avinash Pawar', 'Salesman', 1003, '1996-02-20', 5000, 1200, 30, 'Nagpur'),
(1006, 'Pushkar Deshpande', 'Salesman', 1003, '1996-09-01', 6500, 1500, 30, 'Pune'),
(1008, 'Ravi Sawant', 'Analyst', 1007, '1995-11-17', 10000, NULL, NULL, 'Amaravati');

SELECT 'Employees after insert' AS info;
SELECT Empno,Ename,Job,Mgr,Deptno,Salary FROM Employee;

-- ============================================================
-- TASKS
-- ============================================================

-- 1) Display employee information
SELECT 'Task 1) Employee information' AS task;
SELECT Empno AS Emp_No, Ename AS Employee_Name, Job AS Job_Title, 
       Mgr AS Manager_No, Joined_date AS Date_Joined,
       Salary, Commission, Deptno AS Dept_No, Address
FROM Employee;

-- 2) Unique job titles
SELECT 'Task 2) Unique job titles' AS task;
SELECT DISTINCT Job FROM Employee ORDER BY Job;

-- 3) Update department 40’s location
SELECT 'Task 3) Update department 40 location to Bangalore' AS task;
UPDATE Department SET Location = 'Bangalore' WHERE Deptno = 40;
SELECT 'Rows affected' AS info, ROW_COUNT() AS Rows;
SELECT * FROM Department WHERE Deptno = 40;

-- 4) Rename employee 1003
SELECT 'Task 4) Update employee 1003 name' AS task;
UPDATE Employee SET Ename = 'Nikhil Gosavi' WHERE Empno = 1003;
SELECT 'Rows affected' AS info, ROW_COUNT() AS Rows;
SELECT Empno,Ename FROM Employee WHERE Empno = 1003;

-- 5) Delete Pushkar Deshpande
SELECT 'Task 5) Delete Pushkar Deshpande' AS task;
DELETE FROM Employee WHERE Ename = 'Pushkar Deshpande';
SELECT 'Rows affected' AS info, ROW_COUNT() AS Rows;
SELECT Empno,Ename FROM Employee;

-- 6a) Filter (OR)
SELECT 'Task 6a) Job = Manager OR Analyst' AS task;
SELECT Empno,Ename,Job FROM Employee
WHERE LOWER(Job) = 'manager' OR LOWER(Job) = 'analyst';

-- 6b) Filter (IN)
SELECT 'Task 6b) Job IN (Manager, Analyst)' AS task;
SELECT Empno,Ename,Job FROM Employee
WHERE LOWER(Job) IN ('manager','analyst');

-- 7) Employees by Deptno
SELECT 'Task 7) Employees in depts 10,20,30,40' AS task;
SELECT Ename,Deptno FROM Employee
WHERE Deptno IN (10,20,30,40)
ORDER BY Deptno,Ename;

-- 8) Names starting with A
SELECT 'Task 8) Names starting with A' AS task;
SELECT Ename,Joined_date FROM Employee
WHERE Ename LIKE 'A%' COLLATE utf8mb4_general_ci;

-- 9) Names with i as 2nd letter
SELECT 'Task 9) Names with i as second letter' AS task;
SELECT Ename FROM Employee
WHERE Ename LIKE '_i%' COLLATE utf8mb4_general_ci;

-- 10) Max salary per dept
SELECT 'Task 10) Max salary per department > 5000' AS task;
SELECT Deptno, MAX(Salary) AS Max_Salary
FROM Employee
GROUP BY Deptno
HAVING MAX(Salary) > 5000
ORDER BY Max_Salary DESC;

-- Final snapshots
SELECT 'Final Departments' AS info;
SELECT * FROM Department;
SELECT 'Final Employees' AS info;
SELECT Empno,Ename,Job,Mgr,Deptno,Salary FROM Employee;
desc employee;
desc department; 