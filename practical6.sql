-- ============================================================
-- PRACTICAL-6  (MySQL 8.0)
-- Stored Procedure: proc_Grade
-- Tables: Stud_Marks(Roll, Name, Total_marks), Result(Roll, Name, Class)
-- Rules per spec:
--   Distinction        : 990–1500
--   First Class        : 900–989
--   Higher Second Class: 825–899
--   (Else -> 'No Category' for completeness)
-- ============================================================

-- Fresh DB (optional)
DROP DATABASE IF EXISTS practical6;
CREATE DATABASE practical6;
USE practical6;

-- 1) Tables
CREATE TABLE Stud_Marks (
  Roll         INT          NOT NULL PRIMARY KEY,
  Name         VARCHAR(50)  NOT NULL,
  Total_marks  INT          NOT NULL,
  CONSTRAINT ck_marks_range CHECK (Total_marks BETWEEN 0 AND 1500)
);

CREATE TABLE Result (
  Roll   INT          NOT NULL PRIMARY KEY,
  Name   VARCHAR(50)  NOT NULL,
  Class  VARCHAR(30)  NOT NULL
);

-- 2) Sample data (covers boundaries)
INSERT INTO Stud_Marks (Roll, Name, Total_marks) VALUES
  (101, 'Asha',     1500),  -- Distinction (upper bound)
  (102, 'Bhavesh',   990),  -- Distinction (lower bound)
  (103, 'Chitra',    989),  -- First Class (upper bound)
  (104, 'Deepak',    900),  -- First Class (lower bound)
  (105, 'Esha',      899),  -- Higher Second (upper bound)
  (106, 'Farhan',    825),  -- Higher Second (lower bound)
  (107, 'Gita',      824),  -- No Category (below spec)
  (108, 'Harsh',    1200);  -- Distinction (middle)

-- 3) Optional helper: function that maps marks -> class
DELIMITER //
CREATE FUNCTION fn_grade(p_marks INT)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
  DECLARE v_class VARCHAR(30);
  IF p_marks BETWEEN 990 AND 1500 THEN
    SET v_class = 'Distinction';
  ELSEIF p_marks BETWEEN 900 AND 989 THEN
    SET v_class = 'First Class';
  ELSEIF p_marks BETWEEN 825 AND 899 THEN
    SET v_class = 'Higher Second Class';
  ELSE
    SET v_class = 'No Category';
  END IF;
  RETURN v_class;
END;
//
DELIMITER ;

-- 4) Required procedure: proc_Grade (grade one roll & store in Result)
DELIMITER //
CREATE PROCEDURE proc_Grade(IN p_roll INT)
BEGIN
  DECLARE v_name  VARCHAR(50);
  DECLARE v_marks INT;
  DECLARE v_class VARCHAR(30);

  -- fetch student
  SELECT Name, Total_marks
    INTO v_name, v_marks
  FROM Stud_Marks
  WHERE Roll = p_roll;

  -- derive class (via function for clarity)
  SET v_class = fn_grade(v_marks);

  -- upsert into Result
  INSERT INTO Result(Roll, Name, Class)
  VALUES (p_roll, v_name, v_class)
  ON DUPLICATE KEY UPDATE
    Name = VALUES(Name),
    Class = VALUES(Class);

  -- show a friendly summary
  SELECT p_roll AS Roll, v_name AS Name, v_marks AS Total_marks, v_class AS Class;
END;
//
DELIMITER ;

-- 5) (Optional) Grade all students in one go
DELIMITER //
CREATE PROCEDURE proc_Grade_All()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_roll INT;
  DECLARE cur CURSOR FOR SELECT Roll FROM Stud_Marks ORDER BY Roll;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_roll;
    IF done = 1 THEN LEAVE read_loop; END IF;
    CALL proc_Grade(v_roll);
  END LOOP;
  CLOSE cur;

  -- final view
  SELECT * FROM Result ORDER BY Roll;
END;
//
DELIMITER ;

-- =========================
-- DEMOS
-- =========================

-- Grade a single student
CALL proc_Grade(101);

-- Grade everyone
CALL proc_Grade_All();

-- Final results
SELECT * FROM Result ORDER BY Roll;
