CREATE DATABASE IF NOT EXISTS banking_system;
USE banking_system;
-- CUSTOMERS table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT,
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ACCOUNTS table
CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type ENUM('SAVINGS', 'CURRENT', 'FIXED_DEPOSIT') DEFAULT 'SAVINGS',
    balance DECIMAL(15, 2) DEFAULT 0.00,
    status ENUM('ACTIVE', 'INACTIVE', 'FROZEN', 'CLOSED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);
-- TRANSACTIONS table
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    transaction_type ENUM('DEPOSIT', 'WITHDRAWAL', 'TRANSFER_IN', 'TRANSFER_OUT', 'EMI_PAYMENT') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    balance_after DECIMAL(15, 2),
    description VARCHAR(255),
    status ENUM('SUCCESS', 'FAILED', 'PENDING', 'FLAGGED') DEFAULT 'SUCCESS',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
-- LOANS table
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    account_id INT NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) NOT NULL,       -- Annual rate in %
    tenure_months INT NOT NULL,
    loan_type ENUM('HOME', 'PERSONAL', 'CAR', 'EDUCATION') NOT NULL,
    status ENUM('PENDING', 'ACTIVE', 'CLOSED', 'DEFAULTED') DEFAULT 'PENDING',
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
-- EMI_SCHEDULE table
CREATE TABLE emi_schedule (
    emi_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    installment_no INT NOT NULL,
    due_date DATE NOT NULL,
    emi_amount DECIMAL(10, 2) NOT NULL,
    principal_part DECIMAL(10, 2),
    interest_part DECIMAL(10, 2),
    outstanding_balance DECIMAL(15, 2),
    payment_status ENUM('PENDING', 'PAID', 'OVERDUE') DEFAULT 'PENDING',
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);
-- AUDIT_LOG table
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    action_type VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by VARCHAR(100) DEFAULT 'SYSTEM',
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
-- Customers
INSERT INTO customers (full_name, email, phone, address, date_of_birth) VALUES
('Ravi Sharma', 'ravi@email.com', '9876543210', 'Mumbai, MH', '1990-05-12'),
('Priya Mehta', 'priya@email.com', '9876543211', 'Pune, MH', '1985-08-22'),
('Arjun Patel', 'arjun@email.com', '9876543212', 'Ahmedabad, GJ', '1992-03-17'),
('Sneha Iyer', 'sneha@email.com', '9876543213', 'Chennai, TN', '1995-11-30');
-- Accounts
INSERT INTO accounts (customer_id, account_number, account_type, balance) VALUES
(1, 'ACC100001', 'SAVINGS', 50000.00),
(2, 'ACC100002', 'CURRENT', 150000.00),
(3, 'ACC100003', 'SAVINGS', 25000.00),
(4, 'ACC100004', 'SAVINGS', 80000.00);
-- Transactions
INSERT INTO transactions (account_id, transaction_type, amount, balance_after, description) VALUES
(1, 'DEPOSIT', 10000.00, 60000.00, 'Salary credit'),
(1, 'WITHDRAWAL', 5000.00, 55000.00, 'ATM withdrawal'),
(2, 'DEPOSIT', 50000.00, 200000.00, 'Business income'),
(3, 'TRANSFER_IN', 15000.00, 40000.00, 'Transfer from Ravi');
-- Loans
INSERT INTO loans (customer_id, account_id, principal_amount, interest_rate, tenure_months, loan_type, status, start_date, end_date) VALUES
(1, 1, 500000.00, 8.50, 60, 'HOME', 'ACTIVE', '2024-01-01', '2029-01-01'),
(3, 3, 100000.00, 12.00, 24, 'PERSONAL', 'ACTIVE', '2024-06-01', '2026-06-01');
-- Fetch loan details
    SELECT principal_amount, interest_rate, tenure_months, start_date
    INTO v_principal, v_rate, v_months, v_start_date
    FROM loans WHERE loan_id = p_loan_id;
    
 --  EMI = P * r * (1+r)^n  /  ((1+r)^n - 1)
-- Where:
--  P = Principal loan amount
 -- r = Monthly interest rate  (annual rate / 12 / 100)
--  n = Tenure in months
DELIMITER $$

CREATE PROCEDURE generate_emi_schedule(IN p_loan_id INT)
BEGIN
    DECLARE v_principal    DECIMAL(15,2);
    DECLARE v_rate         DECIMAL(5,2);
    DECLARE v_months       INT;
    DECLARE v_monthly_rate DECIMAL(10,8);
    DECLARE v_emi          DECIMAL(10,2);
    DECLARE v_balance      DECIMAL(15,2);
    DECLARE v_interest     DECIMAL(10,2);
    DECLARE v_principal_part DECIMAL(10,2);
    DECLARE v_start_date   DATE;
    DECLARE i INT DEFAULT 1;
SELECT principal_amount, interest_rate, tenure_months, start_date
    INTO   v_principal, v_rate, v_months, v_start_date
    FROM loans WHERE loan_id = p_loan_id;

    SET v_monthly_rate = v_rate / (12 * 100);
    SET v_balance      = v_principal;
    SET v_emi = ROUND(
        v_principal * v_monthly_rate * POW(1 + v_monthly_rate, v_months)
        / (POW(1 + v_monthly_rate, v_months) - 1), 2);

    DELETE FROM emi_schedule WHERE loan_id = p_loan_id;  -- clear old

    WHILE i <= v_months DO
        SET v_interest       = ROUND(v_balance * v_monthly_rate, 2);
        SET v_principal_part = ROUND(v_emi - v_interest, 2);
        SET v_balance        = ROUND(v_balance - v_principal_part, 2);

        INSERT INTO emi_schedule
            (loan_id, installment_no, due_date, emi_amount,
             principal_part, interest_part, outstanding_balance)
        VALUES
            (p_loan_id, i,
             DATE_ADD(v_start_date, INTERVAL i MONTH),
             v_emi, v_principal_part, v_interest,
             IF(v_balance < 0, 0, v_balance));
        SET i = i + 1;
    END WHILE;

    SELECT CONCAT('EMI Schedule generated: ', v_months,
                  ' installments of Rs.', v_emi) AS result;
END$$

DELIMITER ;

-- Run it for both loans:
CALL generate_emi_schedule(1);
CALL generate_emi_schedule(2);
DELIMITER $$

CREATE PROCEDURE transfer_funds(
    IN from_acc   INT,
    IN to_acc     INT,
    IN amount     DECIMAL(15,2),
    IN description VARCHAR(255)
)
BEGIN
    DECLARE from_balance DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transaction FAILED and ROLLED BACK' AS result;
    END;

    START TRANSACTION;

    -- Lock both rows to prevent dirty reads (FOR UPDATE)
    SELECT balance INTO from_balance
    FROM accounts WHERE account_id = from_acc FOR UPDATE;

    -- Validate sufficient balance
    IF from_balance < amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    -- Debit sender
    UPDATE accounts SET balance = balance - amount WHERE account_id = from_acc;

    -- Credit receiver
    UPDATE accounts SET balance = balance + amount WHERE account_id = to_acc;

    -- Log both legs of the transfer
    INSERT INTO transactions (account_id, transaction_type, amount, balance_after, description)
    VALUES (from_acc, 'TRANSFER_OUT', amount,
            (SELECT balance FROM accounts WHERE account_id = from_acc), description);

    INSERT INTO transactions (account_id, transaction_type, amount, balance_after, description)
    VALUES (to_acc, 'TRANSFER_IN', amount,
            (SELECT balance FROM accounts WHERE account_id = to_acc), description);

    COMMIT;
    SELECT 'Transfer SUCCESSFUL' AS result;
END$$

DELIMITER ;

-- Test:
CALL transfer_funds(2, 3, 10000.00, 'Rent payment');
DELIMITER $$

-- Trigger 1: Flag suspicious large withdrawals
CREATE TRIGGER flag_large_withdrawal
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'WITHDRAWAL' AND NEW.amount > 100000 THEN
        UPDATE transactions SET status = 'FLAGGED'
        WHERE transaction_id = NEW.transaction_id;

        INSERT INTO audit_log (account_id, action_type, old_value, new_value, changed_by)
        VALUES (NEW.account_id, 'FRAUD_ALERT',
                'Normal', CONCAT('Large withdrawal: Rs.', NEW.amount), 'SYSTEM');
    END IF;
END$$

-- Trigger 2: Block transactions on frozen/closed accounts
CREATE TRIGGER block_inactive_account_txn
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE acc_status ENUM('ACTIVE','INACTIVE','FROZEN','CLOSED');
    SELECT status INTO acc_status FROM accounts WHERE account_id = NEW.account_id;

    IF acc_status IN ('FROZEN', 'CLOSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction blocked: Account is Frozen or Closed';
    END IF;
END$$

-- Trigger 3: Auto-audit every balance change
CREATE TRIGGER audit_balance_change
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF OLD.balance <> NEW.balance THEN
        INSERT INTO audit_log (account_id, action_type, old_value, new_value, changed_by)
        VALUES (NEW.account_id, 'BALANCE_CHANGE',
                CONCAT('Rs.', OLD.balance), CONCAT('Rs.', NEW.balance), 'SYSTEM');
    END IF;
END$$

DELIMITER ;
SELECT
    c.full_name,
    SUM(t.amount) AS total_deposits,
    RANK() OVER (ORDER BY SUM(t.amount) DESC) AS deposit_rank
FROM customers c
JOIN accounts a    ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id  = t.account_id
WHERE t.transaction_type = 'DEPOSIT'
GROUP BY c.full_name;
SELECT
    DATE_FORMAT(created_at, '%Y-%m') AS month,
    COUNT(*)                         AS total_transactions,
    SUM(amount)                      AS total_volume,
    SUM(CASE WHEN status = 'FLAGGED' THEN 1 ELSE 0 END) AS flagged_count
FROM transactions
GROUP BY month
ORDER BY month;
SELECT
    c.full_name,
    l.loan_type,
    e.due_date,
    e.emi_amount,
    DATEDIFF(CURDATE(), e.due_date) AS days_overdue
FROM emi_schedule e
JOIN loans     l ON e.loan_id     = l.loan_id
JOIN customers c ON l.customer_id = c.customer_id
WHERE e.due_date < CURDATE()
  AND e.payment_status = 'PENDING'
ORDER BY days_overdue DESC;
WITH account_summary AS (
    SELECT
        a.account_id,
        a.account_number,
        a.balance,
        COUNT(t.transaction_id) AS txn_count,
        MAX(t.created_at)       AS last_txn_date
    FROM accounts a
    LEFT JOIN transactions t ON a.account_id = t.account_id
    GROUP BY a.account_id
)
SELECT * FROM account_summary WHERE txn_count > 0;
SELECT
    c.full_name,
    a.account_number,
    t.amount,
    t.transaction_type,
    t.status,
    t.created_at,
    al.action_type AS alert_type
FROM transactions t
JOIN accounts  a  ON t.account_id  = a.account_id
JOIN customers c  ON a.customer_id = c.customer_id
LEFT JOIN audit_log al ON al.account_id = t.account_id
                      AND al.action_type = 'FRAUD_ALERT'
WHERE t.status = 'FLAGGED';
CREATE VIEW customer_dashboard AS
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.account_type,
    a.balance,
    a.status AS account_status,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'DEPOSIT'    THEN t.amount END), 0) AS total_deposits,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN t.amount END), 0) AS total_withdrawals
FROM customers c
JOIN accounts a     ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, a.account_id;
-- Query the view like a table:
SELECT * FROM customer_dashboard;
SELECT * FROM customer_dashboard WHERE balance > 50000;
SELECT * FROM customer_dashboard WHERE account_status = 'ACTIVE';
-- END--






