-- 01_data_cleaning.sql
-- Project  : Customer Churn Analysis
-- Analyst  : Stanley
-- Platform : Google BigQuery
-- Source: customer-churn-analysis-499807.customer_churn (raw table: telco_churn)

/* According to a widely cited 2016 IBM estimate, the yearly cost of poor quality data is $3.1 trillion in the US alone, which is why I prioritized cleaning the data properly before drawing any conclusions from it. Every transformation below is documented and justified rather than applied silently. A clean dataset is important because it enables us to turn insights into actions. */

--STRUCTURE
-- 1.) INSPECTION 
-- 2.) ROW COUNT
-- 3.) DUPLICATES AUDIT
-- 4.) NULL AUDIT
-- 5.) WHITESPACE AUDIT
-- 6.) Data type validation
-- 7.) Category inspection
-- 8.) Build clean table
-- 9.) Post-clean validation



/* STEP 1: INITIAL INSPECTION */
-- Inspect table
SELECT *
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`
LIMIT 10;

/* STEP 2: Row count 
Confirm the row count matches the known dataset size before any cleaning starts, so any later mismatch signals a real problem.
Expected: 7,043. In order to ensure the accuracy of the schema */
SELECT COUNT(*)
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`;


/* STEP 3: Duplicates audit 
CustomerID is treated as the unique identifier for this dataset confirm no customer appears more than once before it's relied on as one. Returning CustomerID + count (not just a duplicate flag) makes any hits actionable. 
Expected: 0 rows returned. */
SELECT CustomerID, COUNT(*) AS occurrence_count
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;


/* STEP 4: NULL AUDIT 
Every column retained in the final clean table
Check every column retained in the final clean table for missing values before deciding how to handle each one.. */
SELECT
  COUNTIF(CustomerID IS NULL) AS null_customer_id,
  COUNTIF(State IS NULL) AS null_state,
  COUNTIF(City IS NULL) AS null_city,
  COUNTIF(Country IS NULL) AS null_country,
  COUNTIF(`Zip Code` IS NULL) AS null_zip,
  COUNTIF(Latitude IS NULL) AS null_lat,
  COUNTIF(Longitude IS NULL) AS null_long,
  COUNTIF(Gender IS NULL) AS null_gender,
  COUNTIF(`Senior Citizen` IS NULL) AS null_senior,
  COUNTIF(Partner IS NULL) AS null_partner,
  COUNTIF(Dependents IS NULL) AS null_dependents,
  COUNTIF(`Phone Service` IS NULL) AS null_phone_service,
  COUNTIF(`Multiple Lines` IS NULL) AS null_multiple_lines,
  COUNTIF(`Internet Service` IS NULL) AS null_internet_service,
  COUNTIF(`Online Security` IS NULL) AS null_online_security,
  COUNTIF(`Online Backup` IS NULL) AS null_online_backup,
  COUNTIF(`Device Protection` IS NULL) AS null_device_protection,
  COUNTIF(`Tech Support` IS NULL) AS null_tech_support,
  COUNTIF(`Streaming TV` IS NULL) AS null_streaming_tv,
  COUNTIF(`Streaming Movies` IS NULL) AS null_streaming_movies,
  COUNTIF(`Tenure Months` IS NULL) AS null_tenure,
  COUNTIF(Contract IS NULL) AS null_contract,
  COUNTIF(`Paperless Billing` IS NULL) AS null_paperless_billing,
  COUNTIF(`Payment Method` IS NULL) AS null_payment_method,
  COUNTIF(`Monthly Charges` IS NULL) AS null_monthly_charges,
  COUNTIF(`Total Charges` IS NULL) AS null_total_charges,
  COUNTIF(`Churn Label` IS NULL) AS null_churn_label,
  COUNTIF(`Churn Value` IS NULL) AS null_churn_value,
  COUNTIF(`Churn Score` IS NULL) AS null_churn_score,
  COUNTIF(CLTV IS NULL) AS null_cltv,
  COUNTIF(`Churn Reason` IS NULL) AS null_churn_reason
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`;

/* STEP 5: WHITESPACE AUDIT
Covers every text column that gets Trimmed in the clean table build so every transformation below is backed by evidence it was needed. */
SELECT
  COUNTIF(CAST(Gender AS STRING)!= TRIM(CAST(Gender AS STRING))) AS whitespace_gender,
  COUNTIF(CAST(City AS STRING)!= TRIM(CAST(City AS STRING))) AS whitespace_city,
  COUNTIF(CAST(Country AS STRING)!= TRIM(CAST(Country AS STRING))) AS whitespace_country,
  COUNTIF(CAST(State AS STRING)!= TRIM(CAST(State AS STRING))) AS whitespace_state,
  COUNTIF(CAST(Contract AS STRING)!= TRIM(CAST(Contract AS STRING))) AS whitespace_contract,
  COUNTIF(CAST(`Payment Method` AS STRING)!= TRIM(CAST(`Payment Method` AS STRING)))AS whitespace_payment_method,
  COUNTIF(CAST(`Internet Service` AS STRING)!= TRIM(CAST(`Internet Service` AS STRING))) AS whitespace_internet_service,
  COUNTIF(CAST(`Phone Service` AS STRING)!= TRIM(CAST(`Phone Service` AS STRING))) AS whitespace_phone_service,
  COUNTIF(CAST(`Multiple Lines` AS STRING)!= TRIM(CAST(`Multiple Lines` AS STRING))) AS whitespace_multiple_lines,
  COUNTIF(CAST(`Online Security` AS STRING)!= TRIM(CAST(`Online Security` AS STRING))) AS whitespace_online_security,
  COUNTIF(CAST(`Online Backup` AS STRING)!= TRIM(CAST(`Online Backup` AS STRING))) AS whitespace_online_backup,
  COUNTIF(CAST(`Device Protection` AS STRING)!= TRIM(CAST(`Device Protection` AS STRING))) AS whitespace_device_protection,
  COUNTIF(CAST(`Tech Support` AS STRING)!= TRIM(CAST(`Tech Support` AS STRING))) AS whitespace_tech_support,
  COUNTIF(CAST(`Streaming TV` AS STRING)!= TRIM(CAST(`Streaming TV` AS STRING))) AS whitespace_streaming_tv,
  COUNTIF(CAST(`Streaming Movies` AS STRING)!= TRIM(CAST(`Streaming Movies` AS STRING))) AS whitespace_streaming_movies,
  COUNTIF(CAST(`Churn Reason` AS STRING)!= TRIM(CAST(`Churn Reason` AS STRING))) AS whitespace_churn_reason
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`;

/* STEP 6: DATA TYPE VALIDATION
Catches bad casts, negative values, and out-of-range scores before they silently flow into the clean table.
Expected: all bad_* / negative_* / out_of_range counts = 0 */
SELECT
  COUNTIF(SAFE_CAST(`Zip Code` AS INT64) IS NULL) AS bad_zip,
  COUNTIF(SAFE_CAST(Latitude AS FLOAT64) IS NULL) AS bad_latitude,
  COUNTIF(SAFE_CAST(Longitude AS FLOAT64) IS NULL) AS bad_longitude,
  COUNTIF(SAFE_CAST(`Monthly Charges` AS FLOAT64) IS NULL) AS bad_monthly_charges,
  COUNTIF(`Monthly Charges` < 0) AS negative_monthly_charges,
  COUNTIF(CLTV < 0) AS negative_cltv,
  COUNTIF(`Churn Score` < 0 OR `Churn Score` > 100) AS churn_score_out_of_range,
  MIN(`Churn Score`) AS min_churn_score,
  MAX(`Churn Score`) AS max_churn_score,
  MIN(`Tenure Months`) AS min_tenure,
  MAX(`Tenure Months`) AS max_tenure
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`;


/* STEP 7: CATEGORY INSPECTION
Covers every categorical column: contract, payment methods, internet service, churn label, gender, AND the 7 service columns, AND the binary flag columns (senior citizen, partner, dependents, paperless billing, phone service) whose underlying representation (Yes/No vs 0/1) was previously assumed rather than verified. */
SELECT DISTINCT Contract FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Confirm payment method categories are clean before using them to segment churn by billing behavior.
SELECT DISTINCT `Payment Method` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Ensures Internet Service column is clean before using them to segment churn.
SELECT DISTINCT `Internet Service` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Churn Label is the target variable for the whole analysis so if it has unexpected values or casing, the churn rate itself would be wrong.
SELECT DISTINCT `Churn Label` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Quick check for stray Gender variants before it's used in any demographic breakdown.
SELECT DISTINCT Gender FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Service columns — confirm "No X service" variants alongside plain "No"
SELECT DISTINCT `Phone Service` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Multiple Lines` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Online Security` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Online Backup` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Device Protection` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Tech Support` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Streaming TV` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Streaming Movies` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;

-- Binary flag columns — confirm representation (Yes/No vs 0/1) before passing them through untouched
SELECT DISTINCT `Senior Citizen` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT Partner FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT Dependents FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;
SELECT DISTINCT `Paperless Billing` FROM `customer-churn-analysis-499807.customer_churn.telco_churn` ORDER BY 1;


-- Inspect distinct cities
SELECT DISTINCT City
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`
ORDER BY City;


-- TOTAL CHARGES BLANK CHECK
-- Expected: all blank rows have tenure_months = 0 (brand-new customers, no billing cycle completed yet)
SELECT
  COUNT(*) AS blank_total_charges,
  MIN(`Tenure Months`) AS min_tenure,
  MAX(`Tenure Months`) AS max_tenure
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`
WHERE `Total Charges` IS NULL OR TRIM(CAST(`Total Charges` AS STRING)) = '';


/* STEP 9: BUILD CLEAN STAGING TABLE
-- Casing standardized to lowercase across ALL text/categorical columns for consistency. "No X service" variants preserved intentionally. This ensures original dataset is not altered. */
CREATE OR REPLACE TABLE `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
AS
SELECT
  CustomerID AS customer_id,

  ---- DEMOGRAPHICS ----
  TRIM(LOWER(State)) AS state,
  TRIM(LOWER(City)) AS city,
  TRIM(LOWER(Country)) AS country,
  `Zip Code` AS zip_code,
  Latitude AS latitude,
  Longitude AS longitude,
  TRIM(LOWER(Gender)) AS gender,
  `Senior Citizen` AS senior_citizen,
  `Partner` AS partner,
  `Dependents` AS dependents,

  ---- SERVICES OFFERED ----
  CASE CAST(`Phone Service` AS STRING)
    WHEN 'true'  THEN 'yes'
    WHEN 'false' THEN 'no'
END AS phone_service,
  TRIM(LOWER(`Multiple Lines`)) AS multiple_lines,
  TRIM(LOWER(`Internet Service`)) AS internet_service,
  TRIM(LOWER(`Online Security`)) AS online_security,
  TRIM(LOWER(`Online Backup`)) AS online_backup,
  TRIM(LOWER(`Device Protection`)) AS device_protection,
  TRIM(LOWER(`Tech Support`)) AS tech_support,
  TRIM(LOWER(`Streaming TV`)) AS streaming_tv,
  TRIM(LOWER(`Streaming Movies`)) AS streaming_movies,

  ---- ACCOUNT ----
  `Tenure Months` AS tenure_months,
  TRIM(LOWER(Contract)) AS contract,
  `Paperless Billing` AS paperless_billing,
  TRIM(LOWER(`Payment Method`)) AS payment_method,
  `Monthly Charges` AS monthly_charges,
  
  CASE
    WHEN `Total Charges` IS NULL OR TRIM(CAST(`Total Charges` AS STRING)) = ''
      THEN 0.0
    ELSE CAST(`Total Charges` AS FLOAT64)
  END AS total_charges,

---- CHURN OUTCOME ----
  CASE CAST(`Churn label` AS STRING)
    WHEN 'true'  THEN 'yes'
    WHEN 'false' THEN 'no'
END AS churn_label,
  `Churn Value` AS churn_value,
  `Churn Score` AS churn_score,
  CLTV AS cltv,
  COALESCE(TRIM(LOWER(`Churn Reason`)), 'not churned') AS churn_reason
FROM `customer-churn-analysis-499807.customer_churn.telco_churn`;


/* STEP 9: POST-CLEAN VALIDATION
Row count preserved
Expected: both = 7,043 */
SELECT
  (SELECT COUNT(*) FROM `customer-churn-analysis-499807.customer_churn.telco_churn`) AS raw_rows,
  (SELECT COUNT(*) FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`) AS clean_rows;

-- Expected: 0 rows returned. CustomerID is still a unique identifier
SELECT customer_id, COUNT(*) AS occurrence_count
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Confirm every transformed categorical column is clean — no stray whitespace, no case-duplicate categories (e.g. 'Yes' and 'yes' both present)
SELECT DISTINCT gender FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT contract FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT payment_method FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT internet_service FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT churn_label FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT phone_service FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT multiple_lines FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT online_security FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT online_backup FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT device_protection FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT tech_support FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT streaming_tv FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;
SELECT DISTINCT streaming_movies FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean` ORDER BY 1;

-- total_charges = 0 only where tenure_months = 0
-- Expected: only tenure_months = 0 appears
SELECT
  tenure_months,
  COUNT(*)            AS customers,
  MIN(total_charges)  AS min_charges,
  MAX(total_charges)  AS max_charges
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
WHERE total_charges = 0
GROUP BY tenure_months;


-- No NULLs in total_charges or churn_reason after CASE / COALESCE
-- Expected: both = 0
SELECT
  COUNTIF(total_charges IS NULL) AS null_total_charges,
  COUNTIF(churn_reason IS NULL)  AS null_churn_reason
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`;


-- Data summary
SELECT
  COUNT(*)                                      AS total_customers,
  SUM(churn_value)                              AS total_churned,
  ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
  ROUND(AVG(monthly_charges), 2)                AS avg_monthly_charges,
  ROUND(AVG(total_charges), 2)                  AS avg_total_charges,
  MIN(tenure_months)                            AS min_tenure_months,
  MAX(tenure_months)                            AS max_tenure_months
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`;