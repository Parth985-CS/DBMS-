-- =====================================================
-- 1. CREATE DATABASE AND USE IT
-- =====================================================
DROP DATABASE IF EXISTS accident_management;
CREATE DATABASE accident_management;
USE accident_management;

-- =====================================================
-- 2. CREATE TABLES
-- =====================================================

CREATE TABLE Person (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    address VARCHAR(100)
);

CREATE TABLE Car (
    license VARCHAR(20) PRIMARY KEY,
    model VARCHAR(50),
    year INT
);

CREATE TABLE Accident (
    report_no INT AUTO_INCREMENT PRIMARY KEY,
    date_acc DATE,
    location VARCHAR(100)
);

CREATE TABLE Owns (
    driver_id INT,
    license VARCHAR(20),
    PRIMARY KEY (driver_id, license),
    FOREIGN KEY (driver_id) REFERENCES Person(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (license) REFERENCES Car(license) ON DELETE CASCADE
);

CREATE TABLE Participated (
    driver_id INT,
    car_model VARCHAR(50),
    report_no INT,
    damage_amount DECIMAL(10,2),
    PRIMARY KEY (driver_id, report_no),
    FOREIGN KEY (driver_id) REFERENCES Person(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (report_no) REFERENCES Accident(report_no) ON DELETE CASCADE
);

CREATE TABLE Employee (
    employee_name VARCHAR(50) PRIMARY KEY,
    street VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE Company (
    company_name VARCHAR(50) PRIMARY KEY,
    city VARCHAR(50)
);

CREATE TABLE Works (
    employee_name VARCHAR(50),
    company_name VARCHAR(50),
    salary DECIMAL(10,2),
    PRIMARY KEY (employee_name, company_name),
    FOREIGN KEY (employee_name) REFERENCES Employee(employee_name) ON DELETE CASCADE,
    FOREIGN KEY (company_name) REFERENCES Company(company_name) ON DELETE CASCADE
);

CREATE TABLE Manages (
    employee_name VARCHAR(50),
    company_name VARCHAR(50),
    manager_name VARCHAR(50),
    PRIMARY KEY (employee_name, company_name),
    FOREIGN KEY (employee_name) REFERENCES Employee(employee_name) ON DELETE CASCADE,
    FOREIGN KEY (company_name) REFERENCES Company(company_name) ON DELETE CASCADE
);

-- =====================================================
-- 3. CREATE VIEW
-- =====================================================

CREATE OR REPLACE VIEW emp_company_view AS
SELECT e.employee_name, e.city AS employee_city, 
       c.company_name, c.city AS company_city, 
       w.salary
FROM Employee e
JOIN Works w ON e.employee_name = w.employee_name
JOIN Company c ON w.company_name = c.company_name;

-- =====================================================
-- 4. CREATE INDEXES
-- =====================================================

CREATE INDEX idx_employee_city ON Employee(city);
CREATE INDEX idx_participated_damage ON Participated(damage_amount);

-- =====================================================
-- 5. INSERT SAMPLE DATA
-- =====================================================

-- Person
INSERT INTO Person (name, address) VALUES
('Rahul', 'Pune'),
('Sneha', 'Mumbai'),
('Amit', 'Delhi'),
('Neha', 'Nagpur');

-- Car
INSERT INTO Car VALUES
('MH12AB1234', 'Swift', 2020),
('MH14XY5678', 'i20', 2021),
('DL05MN4321', 'Baleno', 2019);

-- Accident
INSERT INTO Accident (date_acc, location) VALUES
('2024-01-10', 'Pune'),
('2024-02-12', 'Mumbai'),
('2024-03-18', 'Delhi');

-- Participated
INSERT INTO Participated VALUES
(1, 'Swift', 1, 15000.00),
(2, 'i20', 2, 22000.00),
(3, 'Baleno', 3, 12000.00);

-- Employee
INSERT INTO Employee VALUES
('Ravi', 'MG Road', 'Pune'),
('Meera', 'LBS Road', 'Mumbai'),
('Suresh', 'Ring Road', 'Delhi');

-- Company
INSERT INTO Company VALUES
('TCS', 'Pune'),
('Infosys', 'Bangalore');

-- Works
INSERT INTO Works VALUES
('Ravi', 'TCS', 60000),
('Meera', 'Infosys', 70000),
('Suresh', 'TCS', 55000);

-- Manages
INSERT INTO Manages VALUES
('Ravi', 'TCS', 'Meera');

-- =====================================================
-- 6. CREATE “SYNONYM” EQUIVALENTS (VIEWS)
-- =====================================================

CREATE OR REPLACE VIEW part_syn AS SELECT * FROM Participated;
CREATE OR REPLACE VIEW comp_syn AS SELECT * FROM Company;

-- View data using “synonyms”
SELECT * FROM part_syn;
SELECT * FROM comp_syn;

-- Update through synonym (view)
UPDATE part_syn SET damage_amount = 25000 WHERE driver_id = 1;
UPDATE comp_syn SET city = 'Hyderabad' WHERE company_name = 'TCS';

-- =====================================================
-- 7. DISPLAY FINAL DATA
-- =====================================================

SELECT * FROM Person;
SELECT * FROM emp_company_view;
SELECT * FROM part_syn;
SELECT * FROM comp_syn;
