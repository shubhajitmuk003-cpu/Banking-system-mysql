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
