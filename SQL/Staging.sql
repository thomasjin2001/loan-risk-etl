-- Create staging table staging
CREATE TABLE staging (
    raw_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_number VARCHAR(255),
    loan_purpose VARCHAR(255),
    purpose_category VARCHAR(255),
    purpose_subcategory VARCHAR(255),
    loan_status VARCHAR(255),
    payment_status VARCHAR(255),
    active_status VARCHAR(255),
    issue_date DATE,
    amount_funded DECIMAL(10, 2),
    amount_requested DECIMAL(10, 2),
    interest_rate DECIMAL(6, 4),
    interest_paid DECIMAL(10, 2),
    origination_fee DECIMAL(10, 2),
    outstanding_balance DECIMAL(12, 2),
    fico_at_origination VARCHAR(255)
);

-- Check if LOAD DATA INFILE is ON
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

-- Load Loan Purpose Data.csv into staging table and check if the number of rows is the same as CSV's
LOAD DATA LOCAL INFILE '/Users/thomasjin_2001/Desktop/MINE/Work/Other/MiMentor/Dashboard Project/Data Sources/Loan Purpose Data.csv'
INTO TABLE staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(active_status,
 @dummy,
 @fico_at_origination,
 @issue_date,
 loan_number,
 loan_purpose,
 @dummy,
 loan_status,
 @dummy,
 payment_status,
 purpose_category,
 purpose_subcategory,
 @dummy,
 @dummy,
 @amount_funded,
 @amount_requested,
 @interest_rate,
 @interest_paid,
 @dummy,
 @origination_fee,
 @outstanding_balance)
SET
    fico_at_origination = NULLIF(TRIM(@fico_at_origination), ''),
    issue_date = STR_TO_DATE(NULLIF(@issue_date, ''), '%m/%d/%Y'),
    amount_funded = NULLIF(TRIM(@amount_funded), ''),
    amount_requested = NULLIF(TRIM(@amount_requested), ''),
    interest_rate = ROUND(NULLIF(TRIM(@interest_rate), ''), 2),
    interest_paid = NULLIF(TRIM(@interest_paid), ''),
    origination_fee = NULLIF(TRIM(@origination_fee), ''),
    outstanding_balance = NULLIF(TRIM(@outstanding_balance), '') + 0;
SELECT COUNT(*) FROM staging;