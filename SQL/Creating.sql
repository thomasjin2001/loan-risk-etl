-- Create database credit_risk
CREATE DATABASE credit_risk;
USE credit_risk;

-- Create dimension table loan_purpose
CREATE TABLE loan_purpose (
	loan_purpose_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_purpose VARCHAR(255) NOT NULL
);

-- Create dimension table purpose_category
CREATE TABLE purpose_category (
	purpose_category_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_purpose_id INT NOT NULL,
    purpose_category VARCHAR(255) NOT NULL,
    FOREIGN KEY (loan_purpose_id) REFERENCES loan_purpose (loan_purpose_id) ON DELETE CASCADE
);

-- Create dimension table purpose_subcategory
CREATE TABLE purpose_subcategory (
	purpose_subcategory_id INT AUTO_INCREMENT PRIMARY KEY,
    purpose_category_id INT NOT NULL,
    purpose_subcategory VARCHAR(255) NOT NULL,
    FOREIGN KEY (purpose_category_id) REFERENCES purpose_category (purpose_category_id) ON DELETE CASCADE
);

-- Create dimension table status
CREATE TABLE `status` (
	status_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_status VARCHAR(255) NOT NULL,
    payment_status VARCHAR(255),
    active_status VARCHAR(255) NOT NULL
);

-- Create dimension table time_dimension
CREATE TABLE time_dimension (
	time_id INT AUTO_INCREMENT PRIMARY KEY,
    issue_date DATE NOT NULL,
	`month` INT NOT NULL,
    `year` INT NOT NULL
);

-- Create fact table loans
CREATE TABLE loans (
	loan_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_number VARCHAR(255) NOT NULL,
    loan_purpose_id INT NOT NULL, -- Foreign key from loan_purpose
    status_id INT NOT NULL, -- Foreign key from status
    time_id INT NOT NULL, -- Foreign key from time_dimension
    amount_funded DECIMAL(10, 2) NOT NULL,
    amount_requested DECIMAL(10, 2) NOT NULL,
    interest_rate DECIMAL(6, 4) NOT NULL,
    interest_paid DECIMAL(10, 2),
    origination_fee DECIMAL(10, 2),
    outstanding_balance DECIMAL(12, 2),
    fico_at_origination VARCHAR(255) NOT NULL,
    FOREIGN KEY (loan_purpose_id) REFERENCES loan_purpose (loan_purpose_id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES `status` (status_id) ON DELETE CASCADE,
    FOREIGN KEY (time_id) REFERENCES time_dimension (time_id) ON DELETE CASCADE
);

-- Create audit table audit for recording the ETL execution status
CREATE TABLE audit (
	audit_id INT AUTO_INCREMENT PRIMARY KEY,
	`table_name` VARCHAR(255) NOT NULL,
    execution_timestamp DATETIME NOT NULL,
    record_count INT NOT NULL,
    load_status ENUM('Success', 'Failed') NOT NULL
);