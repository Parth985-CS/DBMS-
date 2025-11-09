-- ============================================================
-- PRACTICAL-3: Joins, Subqueries, and View (MySQL 8.0+)
-- Schema per spec: Employee, Works, Company, Manages
-- ============================================================

-- 0) Fresh start & DB selection
DROP DATABASE IF EXISTS practical3;
CREATE DATABASE practical3;
USE practical3;

-- 1) Tables with constraints
CREATE TABLE Employee (
  employee_name VARCHAR(100) PRIMARY KEY,
  street        VARCHAR(100) NOT NULL,
  city          VARCHAR(100) NOT NULL
);
-- If Manages already exists from a previous attempt:
DROP TABLE IF EXISTS Manages;

-- Recreate without the CHECK constraint
CREATE TABLE Manages (
  employee_name VARCHAR(100) PRIMARY KEY,
  manager_name  VARCHAR(100) NULL,
  CONSTRAINT fk_mng_emp FOREIGN KEY (employee_name)
    REFERENCES Employee(employee_name)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mng_mgr FOREIGN KEY (manager_name)
    REFERENCES Employee(employee_name)
    ON UPDATE CASCADE ON DELETE SET NULL
);

-- Triggers to prevent self-management
DELIMITER //

CREATE TRIGGER trg_manages_no_self_ins
BEFORE INSERT ON Manages
FOR EACH ROW
BEGIN
  IF NEW.manager_name IS NOT NULL AND NEW.manager_name = NEW.employee_name THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'manager_name cannot equal employee_name';
  END IF;
END;
//

CREATE TRIGGER trg_manages_no_self_upd
BEFORE UPDATE ON Manages
FOR EACH ROW
BEGIN
  IF NEW.manager_name IS NOT NULL AND NEW.manager_name = NEW.employee_name THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'manager_name cannot equal employee_name';
  END IF;
END;
//

DELIMITER ;

CREATE TABLE Company (
  company_name  VARCHAR(120) PRIMARY KEY,
  city          VARCHAR(100) NOT NULL
);

-- One job per employee (enforced by PK on employee_name in Works)
CREATE TABLE Works (
  employee_name VARCHAR(100) PRIMARY KEY,
  company_name  VARCHAR(120) NOT NULL,
  salary        DECIMAL(12,2) NOT NULL CHECK (salary >= 0),
  CONSTRAINT fk_works_emp FOREIGN KEY (employee_name)
    REFERENCES Employee(employee_name)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_works_comp FOREIGN KEY (company_name)
    REFERENCES Company(company_name)
    ON UPDATE CASCADE ON DELETE RESTRICT
);



-- 2) Sample data (covers all questions)
INSERT INTO Company (company_name, city) VALUES
  ('First Bank Coorporation', 'Metropolis'),
  ('Small Bank Coorporation', 'Star City'),
  ('Wayne Finance',           'Gotham'),
  ('Lex Holdings',            'Metropolis');

INSERT INTO Employee (employee_name, street, city) VALUES
  ('Alice',   '12 Maple Ave',  'Metropolis'),
  ('Bob',     '77 King Rd',    'Star City'),
  ('Carol',   '5 Harbor St',   'Gotham'),
  ('David',   '9 Cedar Way',   'Metropolis'),
  ('Eve',     '33 Lake View',  'Central City'),
  ('Frank',   '41 Oak Blvd',   'Star City'),
  ('Grace',   '19 Pine Dr',    'Coast City');

INSERT INTO Works (employee_name, company_name, salary) VALUES
  ('Alice',  'First Bank Coorporation', 12000),
  ('Bob',    'First Bank Coorporation',  9000),
  ('Carol',  'Small Bank Coorporation', 11000),
  ('David',  'Lex Holdings',             15000),
  ('Eve',    'Wayne Finance',             9500),
  ('Frank',  'Small Bank Coorporation',   8000),
  ('Grace',  'First Bank Coorporation',  20000);

INSERT INTO Manages (employee_name, manager_name) VALUES
  ('Alice',  'Grace'),
  ('Bob',    'Alice'),
  ('Carol',  NULL),
  ('David',  'Grace'),
  ('Eve',    'David'),
  ('Frank',  'Carol'),
  ('Grace',  NULL);

-- 3) View that’s useful for many queries
CREATE OR REPLACE VIEW EmpWork AS
SELECT e.employee_name, e.street, e.city AS emp_city,
       w.company_name, w.salary, c.city AS comp_city
FROM Employee e
JOIN Works w   ON w.employee_name = e.employee_name
JOIN Company c ON c.company_name  = w.company_name;

-- =========================
-- QUERIES (as per Practical-3)
-- =========================

-- 1) Names of employees who work for First Bank Coorporation
SELECT employee_name
FROM Works
WHERE company_name = 'First Bank Coorporation';

-- 2) Names and cities of residence of all employees who work for First Bank Coorporation
SELECT e.employee_name, e.city AS residence_city
FROM Employee e
JOIN Works w ON w.employee_name = e.employee_name
WHERE w.company_name = 'First Bank Coorporation';

-- 3) Names, street, city of residence of employees at First Bank Coorporation earning > 10000
SELECT e.employee_name, e.street, e.city
FROM Employee e
JOIN Works w ON w.employee_name = e.employee_name
WHERE w.company_name = 'First Bank Coorporation'
  AND w.salary > 10000;

-- 4) Employees who earn more than each employee of Small Bank Coorporation (ALL)
SELECT e.employee_name
FROM Works e
WHERE e.salary > ALL (
  SELECT salary
  FROM Works
  WHERE company_name = 'Small Bank Coorporation'
);

-- 5) Employees who earn more than the avg salary of their own companies
SELECT w.employee_name
FROM Works w
JOIN (
  SELECT company_name, AVG(salary) AS avg_sal
  FROM Works
  GROUP BY company_name
) a ON a.company_name = w.company_name
WHERE w.salary > a.avg_sal;

-- 6) Company that has the smallest payroll (sum of salaries)
SELECT company_name
FROM Works
GROUP BY company_name
ORDER BY SUM(salary) ASC
LIMIT 1;

-- 7) Companies whose avg salary > avg salary at First Bank Coorporation
SELECT a.company_name
FROM (
  SELECT company_name, AVG(salary) AS avg_sal
  FROM Works
  GROUP BY company_name
) a
CROSS JOIN (
  SELECT AVG(salary) AS fbc_avg
  FROM Works
  WHERE company_name = 'First Bank Coorporation'
) f
WHERE a.avg_sal > f.fbc_avg;

-- 8) Give all employees of First Bank Coorporation a 10% raise
UPDATE Works
SET salary = salary * 1.10
WHERE company_name = 'First Bank Coorporation';

-- (Optional check)
SELECT employee_name, salary
FROM Works
WHERE company_name = 'First Bank Coorporation';

-- 9) Insert names & salaries of employees who earn more than the overall average into HighEarners
CREATE TABLE IF NOT EXISTS HighEarners (
  employee_name VARCHAR(100) PRIMARY KEY,
  salary        DECIMAL(12,2) NOT NULL
);

INSERT INTO HighEarners (employee_name, salary)
SELECT w.employee_name, w.salary
FROM Works w
WHERE w.salary > (SELECT AVG(salary) FROM Works)
ON DUPLICATE KEY UPDATE salary = VALUES(salary);

SELECT * FROM HighEarners ORDER BY salary DESC;

-- 10) Delete employees from Employee who work for a company located in Gotham
-- (i.e., any employee whose company's city is Gotham)
DELETE e
FROM Employee e
JOIN Works w   ON w.employee_name = e.employee_name
JOIN Company c ON c.company_name  = w.company_name
WHERE c.city = 'Gotham';

-- (Optional checks)
SELECT 'Remaining employees' AS info;
SELECT * FROM Employee ORDER BY employee_name;
SELECT 'Remaining works' AS info;
SELECT * FROM Works ORDER BY employee_name;
