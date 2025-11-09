-- ============================================================
-- PRACTICAL-7  (MySQL 8.0)
-- Triggers to audit UPDATE/DELETE on Library into Library_Audit
-- ============================================================

-- Fresh DB (optional)
DROP DATABASE IF EXISTS practical7;
CREATE DATABASE practical7;
USE practical7;

-- 1) Main table: Library
--    (Use a compact, sensible schema; adjust columns as needed for your lab)
CREATE TABLE Library (
  book_id     INT PRIMARY KEY,
  book_title  VARCHAR(150) NOT NULL,
  author      VARCHAR(100) NOT NULL,
  category    VARCHAR(60)  NULL,
  price       DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  status      ENUM('Available','Issued','Lost') NOT NULL DEFAULT 'Available',
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2) Audit table: stores OLD values whenever Library is UPDATED or DELETED
CREATE TABLE Library_Audit (
  audit_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  op_type      ENUM('UPDATE','DELETE') NOT NULL,          -- kind of change
  op_time      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- when it happened
  op_user      VARCHAR(100) NOT NULL,                     -- who triggered it
  -- OLD row snapshot:
  old_book_id    INT NOT NULL,
  old_book_title VARCHAR(150) NOT NULL,
  old_author     VARCHAR(100) NOT NULL,
  old_category   VARCHAR(60),
  old_price      DECIMAL(10,2) NOT NULL,
  old_status     ENUM('Available','Issued','Lost') NOT NULL
);

DELIMITER //

-- 3) BEFORE UPDATE trigger: capture OLD values before they change
CREATE TRIGGER trg_Library_BU
BEFORE UPDATE ON Library
FOR EACH ROW
BEGIN
  INSERT INTO Library_Audit
    (op_type, op_time, op_user,
     old_book_id, old_book_title, old_author, old_category, old_price, old_status)
  VALUES
    ('UPDATE', CURRENT_TIMESTAMP, CURRENT_USER(),
     OLD.book_id, OLD.book_title, OLD.author, OLD.category, OLD.price, OLD.status);
END;
//

-- 4) BEFORE DELETE trigger: capture OLD values before delete
CREATE TRIGGER trg_Library_BD
BEFORE DELETE ON Library
FOR EACH ROW
BEGIN
  INSERT INTO Library_Audit
    (op_type, op_time, op_user,
     old_book_id, old_book_title, old_author, old_category, old_price, old_status)
  VALUES
    ('DELETE', CURRENT_TIMESTAMP, CURRENT_USER(),
     OLD.book_id, OLD.book_title, OLD.author, OLD.category, OLD.price, OLD.status);
END;
//

DELIMITER ;

-- =========================
-- DEMO DATA & OPERATIONS
-- =========================

-- Seed a few books
INSERT INTO Library (book_id, book_title, author, category, price, status) VALUES
  (101, 'DBMS Made Easy',    'Khan',   'Database', 550.00, 'Available'),
  (102, 'Operating Systems', 'Silbers', 'Systems',  799.00, 'Available'),
  (103, 'Computer Networks', 'Tanen',  'Networks', 699.00, 'Issued');

--  A) Update some rows  -> should create 'UPDATE' audit rows
UPDATE Library
   SET price = price + 50, status = 'Issued'
 WHERE book_id = 101;

UPDATE Library
   SET category = 'Distributed Systems'
 WHERE book_id = 102;

--  B) Delete a row       -> should create a 'DELETE' audit row
DELETE FROM Library WHERE book_id = 103;

-- =========================
-- VERIFY: main and audit
-- =========================

-- Current Library contents
SELECT * FROM Library ORDER BY book_id;

-- Audit trail (OLD snapshots of modified/deleted rows)
SELECT * FROM Library_Audit ORDER BY audit_id;
