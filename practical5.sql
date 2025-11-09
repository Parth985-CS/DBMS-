-- ============================================================
-- PRACTICAL 5 : Parameterized Cursor equivalent (MySQL 8.0)
-- Task: Merge N_RollCall → O_RollCall for a given date,
--       skipping existing (roll_no, att_date) rows.
-- ============================================================

DROP DATABASE IF EXISTS practical5;
CREATE DATABASE practical5;
USE practical5;

-- 1️⃣ Create tables
CREATE TABLE O_RollCall (
  roll_no   INT          NOT NULL,
  stud_name VARCHAR(50)  NOT NULL,
  att_date  DATE         NOT NULL,
  PRIMARY KEY (roll_no, att_date)
);

CREATE TABLE N_RollCall (
  roll_no   INT          NOT NULL,
  stud_name VARCHAR(50)  NOT NULL,
  att_date  DATE         NOT NULL
);

-- 2️⃣ Sample data
INSERT INTO O_RollCall VALUES
 (101,'Parth','2025-11-01'),
 (102,'Asha','2025-11-01');

INSERT INTO N_RollCall VALUES
 (101,'Parth','2025-11-01'),  -- duplicate
 (103,'Vijay','2025-11-01'),  -- new
 (104,'Sneha','2025-11-01'),  -- new
 (102,'Asha','2025-11-01'),   -- duplicate
 (105,'Riya','2025-11-02');   -- other date

-- 3️⃣ Stored procedure using a cursor and parameter (p_date)
DELIMITER //

CREATE PROCEDURE MergeRollCall(IN p_date DATE)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_roll INT;
  DECLARE v_name VARCHAR(50);
  DECLARE v_date DATE;
  DECLARE v_exists INT;
  DECLARE v_ins INT DEFAULT 0;
  DECLARE v_skip INT DEFAULT 0;

  -- Cursor to read new-roll-call rows for the given date
  DECLARE cur CURSOR FOR
    SELECT roll_no, stud_name, att_date
    FROM N_RollCall
    WHERE att_date = p_date
    ORDER BY roll_no;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_roll, v_name, v_date;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;

    -- Check if this roll/date already exists
    SELECT COUNT(*) INTO v_exists
    FROM O_RollCall
    WHERE roll_no = v_roll AND att_date = v_date;

    IF v_exists = 0 THEN
      INSERT INTO O_RollCall(roll_no, stud_name, att_date)
      VALUES (v_roll, v_name, v_date);
      SET v_ins = v_ins + 1;
      SELECT CONCAT('Inserted roll=', v_roll, ', name=', v_name) AS info;
    ELSE
      SET v_skip = v_skip + 1;
      SELECT CONCAT('Skipped roll=', v_roll, ' (already exists)') AS info;
    END IF;
  END LOOP;

  CLOSE cur;

  -- Show summary
  SELECT CONCAT('Merge complete for ', p_date,
                ': Inserted=', v_ins, ', Skipped=', v_skip) AS summary;
END;
//

DELIMITER ;

-- 4️⃣ Test the procedure
CALL MergeRollCall('2025-11-01');

-- 5️⃣ Verify final merged table
SELECT * FROM O_RollCall ORDER BY att_date, roll_no;
SELECT * FROM O_RollCall ORDER BY att_date, roll_no;
