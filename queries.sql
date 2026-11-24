-- Car Rental Database - Queries
-- Run after schema.sql and data.sql.
-- Part 1 creates the view, trigger and procedure (run once).
-- Part 2 onwards are queries to run one at a time in the viva
-- (click inside a query and press Cmd + Enter).

USE car_rental;

-- =====================================================================
-- PART 1: SETUP (view, trigger, stored procedure)
-- =====================================================================

-- VIEW: cars that are free to rent right now, with model details
DROP VIEW IF EXISTS available_cars;
CREATE VIEW available_cars AS
SELECT c.car_id, c.reg_number, m.make, m.model, m.category, m.daily_rate, b.name AS branch
FROM Car c
JOIN Car_Model m ON c.model_id = m.model_id
JOIN Branch b    ON c.branch_id = b.branch_id
WHERE c.status = 'available';

-- TRIGGER: when a rental is returned, mark the car available again
-- and move it to the branch it was returned to
DROP TRIGGER IF EXISTS car_returned;
DELIMITER $$
CREATE TRIGGER car_returned
AFTER UPDATE ON Rental
FOR EACH ROW
BEGIN
    IF OLD.actual_return_date IS NULL AND NEW.actual_return_date IS NOT NULL THEN
        UPDATE Car
        SET status = 'available', branch_id = NEW.return_branch_id
        WHERE car_id = NEW.car_id;
    END IF;
END$$
DELIMITER ;

-- STORED PROCEDURE: book a car safely (this is the concurrency part)
--   1. Start a transaction
--   2. Lock the car's row with FOR UPDATE, so anyone else booking
--      the same car has to wait until we finish
--   3. Check no other rental overlaps the requested dates
--   4. Insert the rental and COMMIT, or ROLLBACK with an error
DROP PROCEDURE IF EXISTS book_car;
DELIMITER $$
CREATE PROCEDURE book_car(
    IN p_customer INT, IN p_car INT,
    IN p_pickup INT,   IN p_return INT,
    IN p_start DATE,   IN p_end DATE
)
BEGIN
    DECLARE v_rate    DECIMAL(8,2);
    DECLARE v_clashes INT;

    START TRANSACTION;

    -- get the car's daily rate AND lock the car's row (FOR UPDATE)
    SELECT m.daily_rate INTO v_rate
    FROM Car c JOIN Car_Model m ON c.model_id = m.model_id
    WHERE c.car_id = p_car
    FOR UPDATE;

    -- count bookings that overlap the requested dates
    SELECT COUNT(*) INTO v_clashes
    FROM Rental
    WHERE car_id = p_car
      AND status <> 'cancelled'
      AND start_date < p_end
      AND end_date   > p_start;

    IF v_clashes > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car is already booked for those dates';
    ELSE
        INSERT INTO Rental (customer_id, car_id, pickup_branch_id, return_branch_id,
                            start_date, end_date, total_cost, status)
        VALUES (p_customer, p_car, p_pickup, p_return,
                p_start, p_end, DATEDIFF(p_end, p_start) * v_rate, 'booked');
        COMMIT;
    END IF;
END$$
DELIMITER ;


-- =====================================================================
-- PART 2: LIVE AGGREGATION
-- =====================================================================

-- 1. Revenue per branch (based on where the rental was picked up)
SELECT b.name AS branch, SUM(p.amount) AS revenue
FROM Payment p
JOIN Rental r ON p.rental_id = r.rental_id
JOIN Branch b ON r.pickup_branch_id = b.branch_id
GROUP BY b.name
ORDER BY revenue DESC;

-- 2. Number of rentals per car category
SELECT m.category, COUNT(*) AS num_rentals
FROM Rental r
JOIN Car c       ON r.car_id = c.car_id
JOIN Car_Model m ON c.model_id = m.model_id
WHERE r.status <> 'cancelled'
GROUP BY m.category
ORDER BY num_rentals DESC;

-- 3. Customers who have spent more than 300 euro (HAVING)
SELECT cu.first_name, cu.last_name, SUM(p.amount) AS total_spent
FROM Customer cu
JOIN Rental r  ON cu.customer_id = r.customer_id
JOIN Payment p ON r.rental_id = p.rental_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name
HAVING total_spent > 300
ORDER BY total_spent DESC;

-- 4. Revenue per month
SELECT DATE_FORMAT(paid_at, '%Y-%m') AS month, SUM(amount) AS revenue
FROM Payment
GROUP BY month
ORDER BY month;

-- 5. Outstanding balance on each rental that isn't fully paid
SELECT r.rental_id, r.status, r.total_cost,
       COALESCE(SUM(p.amount), 0)                AS paid,
       r.total_cost - COALESCE(SUM(p.amount), 0) AS still_owed
FROM Rental r
LEFT JOIN Payment p ON r.rental_id = p.rental_id
WHERE r.status <> 'cancelled'
GROUP BY r.rental_id, r.status, r.total_cost
HAVING still_owed > 0;


-- =====================================================================
-- PART 3: ADVANCED SQL
-- =====================================================================

-- 6. Use the view
SELECT * FROM available_cars;

-- 7. Overdue rentals (due back already, not returned yet)
SELECT r.rental_id, cu.first_name, cu.last_name, c.reg_number, r.end_date,
       DATEDIFF(CURDATE(), r.end_date) AS days_overdue
FROM Rental r
JOIN Customer cu ON r.customer_id = cu.customer_id
JOIN Car c       ON r.car_id = c.car_id
WHERE r.actual_return_date IS NULL
  AND r.status = 'active'
  AND r.end_date < CURDATE();

-- 8. Subquery: cars that have never been rented
SELECT reg_number, status
FROM Car
WHERE car_id NOT IN (SELECT car_id FROM Rental);

-- 9. Window function: rank customers by total spend
SELECT cu.first_name, cu.last_name, SUM(p.amount) AS total_spent,
       RANK() OVER (ORDER BY SUM(p.amount) DESC) AS spend_rank
FROM Customer cu
JOIN Rental r  ON cu.customer_id = r.customer_id
JOIN Payment p ON r.rental_id = p.rental_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name
ORDER BY spend_rank;

-- 10. One-way rentals (picked up and returned at different branches)
SELECT r.rental_id, pb.name AS picked_up_at, rb.name AS returned_to
FROM Rental r
JOIN Branch pb ON r.pickup_branch_id = pb.branch_id
JOIN Branch rb ON r.return_branch_id = rb.branch_id
WHERE r.pickup_branch_id <> r.return_branch_id;

-- 11. Stored procedure: successful booking
CALL book_car(5, 4, 2, 2, '2026-12-01', '2026-12-04');
SELECT * FROM Rental ORDER BY rental_id DESC LIMIT 1;

-- 12. Stored procedure: clashing booking (should give an error)
--     Car 1 is already booked 18-23 Dec
CALL book_car(6, 1, 1, 1, '2026-12-20', '2026-12-22');

-- 13. Trigger: return rental 8 (car 2) and check the car is available again
SELECT car_id, status, branch_id FROM Car WHERE car_id = 2;
UPDATE Rental SET actual_return_date = CURDATE(), status = 'completed' WHERE rental_id = 8;
SELECT car_id, status, branch_id FROM Car WHERE car_id = 2;


-- =====================================================================
-- PART 4: CONCURRENCY DEMO (needs two Workbench tabs)
-- =====================================================================
-- Check the isolation level (InnoDB default is REPEATABLE-READ)
SELECT @@transaction_isolation;

-- Copy these into two separate query tabs to show locking:
--
-- TAB 1:
--   START TRANSACTION;
--   SELECT * FROM Car WHERE car_id = 3 FOR UPDATE;   -- car 3 is now locked
--
-- TAB 2:
--   CALL book_car(1, 3, 2, 2, '2027-01-10', '2027-01-12');   -- this WAITS
--
-- TAB 1:
--   COMMIT;   -- lock released, Tab 2 now finishes


-- =====================================================================
-- PART 5: DURABILITY / TRANSACTIONS
-- =====================================================================

-- ROLLBACK: the payment is undone as if it never happened
START TRANSACTION;
INSERT INTO Payment (rental_id, amount, method) VALUES (9, 515.00, 'card');
SELECT * FROM Payment WHERE rental_id = 9;   -- 2 rows
ROLLBACK;
SELECT * FROM Payment WHERE rental_id = 9;   -- back to 1 row

-- COMMIT: once committed, it's saved permanently (InnoDB redo log),
-- even if MySQL crashes straight after
START TRANSACTION;
INSERT INTO Payment (rental_id, amount, method) VALUES (9, 515.00, 'card');
COMMIT;
SELECT * FROM Payment WHERE rental_id = 9;   -- 2 rows, permanent


-- =====================================================================
-- PART 6: PHYSICAL LAYER
-- =====================================================================

-- Show the indexes on Rental (primary key, foreign keys, our index)
SHOW INDEX FROM Rental;

-- EXPLAIN shows MySQL using idx_rental_car_dates for the overlap check
EXPLAIN
SELECT * FROM Rental
WHERE car_id = 1 AND start_date < '2026-12-22' AND end_date > '2026-12-20';

-- Storage engine of each table (should all be InnoDB)
SELECT table_name, engine
FROM information_schema.tables
WHERE table_schema = 'car_rental';