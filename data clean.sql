-- ===============================
-- 📦 1. CHECK FOR DUPLICATES
-- ===============================
-- Purpose: Ensure there are no duplicate customer records before processing.
-- We'll check based on 'customerID' to confirm uniqueness.

SELECT customerID, COUNT(*) AS count
FROM telecom
GROUP BY customerID
HAVING COUNT(*) > 1;

-- If the result is empty (no rows returned), there are no duplicate customers.
-- You can now safely drop the customerID column.

-- ===============================
-- 🧹 2. DROP IRRELEVANT COLUMNS
-- ===============================
-- Purpose: Remove columns that are not useful for churn prediction or add no value.

ALTER TABLE telecom DROP COLUMN TotalCharges;  -- Redundant (correlates with tenure × MonthlyCharges)
ALTER TABLE telecom DROP COLUMN customerID;    -- Just a unique identifier, not useful
ALTER TABLE telecom DROP COLUMN gender;        -- Typically low predictive power for churn

-- ===============================
-- 🔄 3. CLEAN CATEGORICAL VALUES
-- ===============================
-- Purpose: Standardize nested categorical values (e.g., "No internet service") to "No"
-- This simplifies feature encoding and modeling later.

-- 🔹 3.1 Fix "No internet service" in Internet-related columns
UPDATE telecom
SET OnlineSecurity = 'No'
WHERE OnlineSecurity = 'No internet service';

UPDATE telecom
SET OnlineBackup = 'No'
WHERE OnlineBackup = 'No internet service';

UPDATE telecom
SET DeviceProtection = 'No'
WHERE DeviceProtection = 'No internet service';

UPDATE telecom
SET TechSupport = 'No'
WHERE TechSupport = 'No internet service';

UPDATE telecom
SET StreamingTV = 'No'
WHERE StreamingTV = 'No internet service';

UPDATE telecom
SET StreamingMovies = 'No'
WHERE StreamingMovies = 'No internet service';

-- 🔹 3.2 Fix "No phone service" in phone-related column
UPDATE telecom
SET MultipleLines = 'No'
WHERE MultipleLines = 'No phone service';

-- 🔍 4.1 View: Tenure Groups
-- Group customers by how long they’ve been with the company
-- Helps identify churn behavior based on customer loyalty

CREATE OR REPLACE VIEW tenure_groups AS
SELECT *,
  CASE
    WHEN tenure <= 12 THEN '0-1 year'
    WHEN tenure <= 24 THEN '1-2 years'
    WHEN tenure <= 48 THEN '2-4 years'
    ELSE '4+ years'
  END AS tenure_group
FROM telecom;

-- 🔍 4.2 View: Contract Type Summary with Churn Rate
-- Summarize how contract type relates to churn rate
-- Useful for identifying retention levers

CREATE OR REPLACE VIEW contract_type_summary AS
SELECT 
  Contract,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_percent
FROM telecom
GROUP BY Contract;