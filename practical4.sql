-- ==============================
-- PRACTICAL-4 (MySQL 8.0 version)
-- Borrower & Fine + return rules
-- ==============================

-- Fresh DB
DROP DATABASE IF EXISTS practical4;
CREATE DATABASE practical4;
USE practical4;

-- Tables
CREATE TABLE Borrower (
  Rollin       INT            NOT NULL,
  Name         VARCHAR(50)    NOT NULL,
  DateofIssue  DATE           NOT NULL,
  NameofBook   VARCHAR(100)   NOT NULL,
  Status       CHAR(1)        NOT NULL,  -- 'I' = Issued, 'R' = Returned
  PRIMARY KEY (Rollin, NameofBook)
);

CREATE TABLE Fine (
  Roll_no   INT           NOT NULL,
  Date      DATE          NOT NULL DEFAULT (CURRENT_DATE),
  Amt       DECIMAL(10,2) NOT NULL CHECK (Amt >= 0)
);

-- Sample row to test quickly (issued 18 days ago)
INSERT INTO Borrower (Rollin, Name, DateofIssue, NameofBook, Status)
VALUES (101, 'Parth', DATE_SUB(CURDATE(), INTERVAL 18 DAY), 'DBMS Made Easy', 'I')
AS new_row
ON DUPLICATE KEY UPDATE Name = new_row.Name;


-- ===============================================
-- Stored procedure to process a return + compute fine
-- Rules:
--   days = DATEDIFF(CURDATE(), DateofIssue)
--   days <= 14          -> fine = 0
--   15 <= days <= 30    -> fine = 5 * days
--   days > 30           -> fine = 50 * days
--   then set Status = 'R' and insert into Fine if fine > 0
-- ===============================================

DELIMITER //

DROP PROCEDURE IF EXISTS ProcessReturn;

DELIMITER //

CREATE PROCEDURE ProcessReturn(IN p_roll INT, IN p_book VARCHAR(100))
BEGIN
  DECLARE v_doissue DATE DEFAULT NULL;
  DECLARE v_status  CHAR(1) DEFAULT NULL;
  DECLARE v_days    INT;
  DECLARE v_amt     DECIMAL(10,2) DEFAULT 0;
  DECLARE v_name    VARCHAR(50);

  -- Fetch the loan row (and borrower name)
  SELECT DateofIssue, Status, Name
    INTO v_doissue, v_status, v_name
  FROM Borrower
  WHERE Rollin = p_roll AND NameofBook = p_book
  LIMIT 1;

  -- If no row found
  IF v_doissue IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No active issue found for given roll_no and book';
  END IF;

  -- Must currently be issued
  IF v_status <> 'I' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Book is not currently issued';
  END IF;

  -- Compute days and fine
  SET v_days = DATEDIFF(CURDATE(), v_doissue);

  IF v_days <= 14 THEN
    SET v_amt = 0;
  ELSEIF v_days BETWEEN 15 AND 30 THEN
    SET v_amt = 5 * v_days;
  ELSE
    SET v_amt = 50 * v_days;
  END IF;

  -- Mark as returned
  UPDATE Borrower
     SET Status = 'R'
   WHERE Rollin = p_roll AND NameofBook = p_book;

  -- Record fine if any
  IF v_amt > 0 THEN
    INSERT INTO Fine (Roll_no, Date, Amt)
    VALUES (p_roll, CURDATE(), v_amt);
  END IF;

  -- Friendly summary
  SELECT
    CONCAT('Return processed for Roll=', p_roll,
           ', Name=', v_name,
           ', Book=\"', p_book, '\"') AS message,
    v_days  AS days_since_issue,
    v_amt   AS fine_amount;
END;
//

DELIMITER ;
CALL ProcessReturn(101, 'DBMS Made Easy');
SELECT * FROM Borrower;
SELECT * FROM Fine ORDER BY Date DESC;

