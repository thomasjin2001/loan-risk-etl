-- Change delimiter ";" into "$$"
DELIMITER $$

-- Create procedure load_data_to_model and define the start, end and error time of ETL process
CREATE PROCEDURE load_data_to_model()
BEGIN
	DECLARE start_time DATETIME;
    DECLARE end_time DATETIME;
    DECLARE error_time DATETIME;
    
    -- Define exception handling
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
		-- Record error time
		SET error_time = NOW();
        
        -- Record failure status into audit table audit
        INSERT INTO audit (`table_name`, execution_timestamp, record_count, load_status)
        VALUES
			('loan_purpose', error_time, 0, 'Failed'),
			('purpose_category', error_time, 0, 'Failed'),
			('purpose_subcategory', error_time, 0, 'Failed'),
			('status', error_time, 0, 'Failed'),
			('time_dimension', error_time, 0, 'Failed'),
			('loans', error_time, 0, 'Failed');
        
        -- Terminate the process and throwing errors
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error occurred while loading data.';
	END;
    
    -- Record start time
    SET start_time = NOW();
    
    -- Load data into dimension table loan_purpose
    INSERT INTO loan_purpose (loan_purpose)
    SELECT DISTINCT st.loan_purpose
    FROM staging st
    WHERE st.loan_purpose IS NOT NULL
    AND NOT EXISTS (
		SELECT 1 FROM loan_purpose lp WHERE lp.loan_purpose = st.loan_purpose
	);
    
    -- Load data into dimension table purpose_category
    INSERT INTO purpose_category (loan_purpose_id, purpose_category)
	SELECT DISTINCT lp.loan_purpose_id, st.purpose_category
    FROM staging st
    INNER JOIN loan_purpose lp ON st.loan_purpose = lp.loan_purpose
    WHERE st.purpose_category IS NOT NULL
    AND NOT EXISTS (
		SELECT 1 FROM purpose_category pc 
		WHERE pc.loan_purpose_id = lp.loan_purpose_id 
		AND pc.purpose_category = st.purpose_category
	);
	
    -- Load data into dimension table purpose_subcategory
    INSERT INTO purpose_subcategory (purpose_category_id, purpose_subcategory)
    SELECT DISTINCT pc.purpose_category_id, st.purpose_subcategory
    FROM staging st
    INNER JOIN purpose_category pc ON st.purpose_category = pc.purpose_category
    WHERE st.purpose_subcategory IS NOT NULL
	AND NOT EXISTS (
		SELECT 1 FROM purpose_subcategory psc 
		WHERE psc.purpose_category_id = pc.purpose_category_id 
		AND psc.purpose_subcategory = st.purpose_subcategory
	);
	
    -- Load data into dimension table status
    INSERT INTO `status` (loan_status, payment_status, active_status)
    SELECT DISTINCT st.loan_status, st.payment_status, st.active_status
    FROM staging st
    WHERE st.loan_status IS NOT NULL
    AND NOT EXISTS (
		SELECT 1 FROM `status` s
        WHERE s.loan_status = st.loan_status
        AND s.payment_status = st.payment_status
        AND s.active_status = st.active_status
	);
	
    -- Load data into dimension table time_dimension
    INSERT INTO time_dimension (issue_date, `month`, `year`)
    SELECT DISTINCT
		st.issue_date,
        MONTH(st.issue_date),
        YEAR(st.issue_date)
	FROM staging st
    WHERE st.issue_date IS NOT NULL
    AND NOT EXISTS (
		SELECT 1 FROM time_dimension td
        WHERE td.issue_date = st.issue_date
	);
    
    -- Load data into fact table loans
    INSERT INTO loans (
		loan_number,
        loan_purpose_id,
        status_id,
        time_id,
        amount_funded,
        amount_requested,
        interest_rate,
        interest_paid,
        origination_fee,
        outstanding_balance,
        fico_at_origination
	)
    SELECT
		st.loan_number,
        lp.loan_purpose_id, -- Foreign key from loan_purpose
        s.status_id, -- Foreign key from status
        td.time_id, -- Foreign key from time_dimension
        st.amount_funded,
        st.amount_requested,
        st.interest_rate,
        st.interest_paid,
        st.origination_fee,
        st.outstanding_balance,
        st.fico_at_origination
	FROM staging st
    INNER JOIN loan_purpose lp ON st.loan_purpose = lp.loan_purpose
    INNER JOIN `status` s ON st.loan_status = s.loan_status
    INNER JOIN time_dimension td ON st.issue_date = td.issue_date;
    
    -- Record end time
    SET end_time = NOW();
    
    -- Record success status into audit table audit
    INSERT INTO audit (`table_name`, execution_timestamp, record_count, load_status)
    VALUES
		('loan_purpose', end_time, (SELECT COUNT(*) FROM loan_purpose), 'Success'),
        ('purpose_category', end_time, (SELECT COUNT(*) FROM purpose_category), 'Success'),
        ('purpose_subcategory', end_time, (SELECT COUNT(*) FROM purpose_subcategory), 'Success'),
        ('status', end_time, (SELECT COUNT(*) FROM `status`), 'Success'),
        ('time_dimension', end_time, (SELECT COUNT(*) FROM time_dimension), 'Success'),
        ('loans', end_time, (SELECT COUNT(*) FROM loans), 'Success');
END$$

-- Change delimiter "$$" into ";"
DELIMITER ;

-- Call procedure load_data_to_model
CALL load_data_to_model();

-- Check the records in audit table audit
SELECT 1 FROM audit ORDER BY execution_timestamp DESC;