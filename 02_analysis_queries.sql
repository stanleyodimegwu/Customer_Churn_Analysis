-- 02_analysis_queries.sql
-- Project  : Customer Churn Analysis
-- Analyst  : Stanley Odimegwu
-- Platform : Google BigQuery
-- Source   : customer-churn-analysis-499807.customer_churn.stg_telco_clean
/* For this part of the project, I will be conducting an analysis using queries from the clean table produced in 01_data_cleaning.sql. Each query answers a specific business question and insights will be documented at the bottom of each query. You also have access to my loom video where I will explaining my process and insights.*/
--STRUCTURE
-- 1. TOTAL SUMMARY
-- 2. CUSTOMER/USER ANALYSIS
-- 3. REVENUE ANALYSIS
-- 4. DEEPER ANALYSIS


/* SECTION 1: TOTAL SUMMARY */

--Overall churn rate
SELECT COUNT(*) AS total_users,
SUM(churn_value) AS churned_users,
COUNT(*) - SUM(churn_value) AS retained_users,
ROUND(100 * SUM(churn_value)/COUNT(*), 2) AS churn_pct,
ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
ROUND(SUM(monthly_charges), 2) AS monthly_revenue,
ROUND(SUM(CASE WHEN churn_value = 1 THEN monthly_charges ELSE 0 END),2) AS monthly_revenue_at_risk
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`;

--Insight: Generally the company's customer base is stable but there is a 26.54% churn rate which means 1 in 4 customers are leaving.

--Churn rate by contract
SELECT
    contract,
    COUNT(*) AS total_customers,
    SUM(churn_value) AS churned,
    COUNT(*) - SUM(churn_value) AS retained,
    ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN churn_value = 1
                   THEN monthly_charges ELSE 0 END), 2)     AS churned_monthly_revenue
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
GROUP BY contract
ORDER BY churn_rate_pct DESC;
--Insight: There is a 42.71% churn rate for users with a month to month contract while users with a year to year has an 11.27% churn rate which is signficantly lower. Given the data provided, customers on month-to-month contracts exhibit significantly higher churn and investigating incentives for long-term contracts could improve retention.


/* SECTION 2: CUSTOMER ANALYSIS */
--Churn rate by tenure
SELECT
    CASE
        WHEN tenure_months = 0   THEN '00 — New (0 months)'
        WHEN tenure_months <= 6  THEN '01 — 1–6 months'
        WHEN tenure_months <= 12 THEN '02 — 7–12 months'
        WHEN tenure_months <= 24 THEN '03 — 13–24 months'
        WHEN tenure_months <= 48 THEN '04 — 25–48 months'
        ELSE                                 '05 — 49+ months'
    END AS tenure_cohort,
    COUNT(*) AS total_customers,
    SUM(churn_value) AS churned,
    ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(CAST(cltv AS FLOAT64)), 2) AS avg_cltv
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
GROUP BY tenure_cohort
ORDER BY tenure_cohort;
--Insight: 52.9% churn in first six months, dropping sharply by year 2 . We also see that the first six months has the highest window for churn and early contract conversion are the most actionable step to take.


--Churn rate by Internet Service
SELECT internet_service,
 COUNT(*) AS total_customers,
    SUM(churn_value) AS churned,
    ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
        ROUND(SUM(CASE WHEN churn_value = 1
                   THEN monthly_charges ELSE 0 END), 2) AS churned_monthly_revenue
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;
--Insight: Fiber optic customers experience the highest churn rate (41.89%) despite paying higher monthly charges. Because these customers generate greater revenue per account, they contribute disproportionately to monthly revenue loss and should be prioritized for retention initiatives.

--Churn rate for payment method
SELECT payment_method,
 COUNT(*) AS total_customers,
    SUM(churn_value) AS churned,
    ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
        ROUND(SUM(CASE WHEN churn_value = 1
                   THEN monthly_charges ELSE 0 END), 2) AS churned_monthly_revenue
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

--Insight: electronic check customers churn at ~45% — well above baseline. Recommending customers to use auto payment methods(bank transfer, credit card et cetera) would yield less churn.


/*SECTION 3: REVENUE IMPACT ANALYSIS TO UNCOVER MORE INSIGHTS USING CTEs AND ADVANCED WINDOWS FNS*/
--Monthly revenue at risk by contract and internet service segment
WITH summary AS (
    SELECT
        contract,
        internet_service,
        COUNT(*) AS total_customers,
        SUM(churn_value) AS churned_customers,
        ROUND(100.0 * SUM(churn_value) / COUNT(*), 2) AS churn_rate_pct,
        ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
        ROUND(SUM(CASE WHEN churn_value = 1 THEN monthly_charges ELSE 0 END), 2) AS monthly_revenue_at_risk
    FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
    GROUP BY contract, internet_service
)
SELECT
    contract,
    internet_service,
    total_customers,
    churned_customers,
    churn_rate_pct,
    avg_monthly_charges,
    monthly_revenue_at_risk,
    RANK() OVER (ORDER BY monthly_revenue_at_risk DESC) AS risk_rank
FROM summary
ORDER BY monthly_revenue_at_risk DESC;
--Insight: Approximately $100,000 in churned revenue from month-to-month and fiber optic. This should be the primary target for any retention intervention.

--High value customers at risk analysis. Identifies customers who have NOT churned yet but show high churn risk scores and above-average lifetime value.
SELECT
    customer_id,
    state,
    contract,
    internet_service,
    tenure_months,
    monthly_charges,
    churn_score,
    cltv,
    CASE
        WHEN churn_score >= 90 THEN 'Critical'
        WHEN churn_score >= 80 THEN 'High'
        ELSE 'Elevated'
    END                                                     AS risk_tier
FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
WHERE churn_label = 'no'
  AND churn_score >= 75
  AND cltv > (
        SELECT AVG(cltv)
        FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
      )
ORDER BY cltv DESC, churn_score DESC
LIMIT 25;
--Insight: Retention strategy should prioritize high-CLTV customers with elevated churn scores not just the customers most likely to leave, but the ones whose departure costs the business the most

/*SECTION 4: CHURN PATTERN ANALYSIS TO UNCOVER MORE INSIGHTS USING CTEs AND ADVANCED WINDOWS FNS*/
--Running cumulative churn rate by tenure month
WITH monthly_churn AS (
    SELECT
        tenure_months,
        COUNT(*) AS customers_at_tenure,
        SUM(churn_value) AS churned_at_tenure
    FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
    GROUP BY tenure_months
),
running_totals AS (
    SELECT
        tenure_months,
        customers_at_tenure,
        churned_at_tenure,
        ROUND(100.0 * churned_at_tenure / customers_at_tenure, 2) AS churn_rate_this_month,
        SUM(churned_at_tenure)  OVER (ORDER BY tenure_months) AS cumulative_churned,
        SUM(customers_at_tenure) OVER (ORDER BY tenure_months) AS cumulative_customers
    FROM monthly_churn
)
SELECT
    tenure_months,
    customers_at_tenure,
    churned_at_tenure,
    churn_rate_this_month,
    cumulative_churned,
    ROUND(100.0 * cumulative_churned / cumulative_customers, 2) AS cumulative_churn_rate_pct
FROM running_totals
ORDER BY tenure_months;

--Insight: This supports previous analysis as we churn rate reduce gradually after 12 months. The first year is where retention investment has the highest ROI.

---- Churn reason comparison using LAG
WITH reason_counts AS (
    SELECT
        CASE
            WHEN churn_reason LIKE '%competitor%' THEN 'Competitor'

            WHEN churn_reason LIKE '%attitude%'
              OR churn_reason LIKE '%support%' THEN 'Service & Support'

            WHEN churn_reason LIKE '%dissatisf%'
              OR churn_reason LIKE '%product%' THEN 'Product Dissatisfaction'

            WHEN churn_reason LIKE '%price%'
              OR churn_reason LIKE '%expensive%'
              OR churn_reason LIKE '%charge%' THEN 'Pricing'

            WHEN churn_reason = 'not chhurned' THEN NULL
            ELSE 'Other'
        END AS reason_category,
        COUNT(*) AS num_customers,
        ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
    FROM `customer-churn-analysis-499807.customer_churn.stg_telco_clean`
    WHERE churn_value = 1
    GROUP BY reason_category
),
ranked_reasons AS (
    SELECT
        reason_category,
        num_customers,
        avg_monthly_charges,
        ROUND(100.0 * num_customers / SUM(num_customers) OVER (), 2) AS pct_of_total_churn,
        LAG(num_customers) OVER (ORDER BY num_customers DESC) AS prev_reason_count,
        num_customers - LAG(num_customers) OVER (ORDER BY num_customers DESC)  AS diff_from_prev_reason
    FROM reason_counts
    WHERE reason_category IS NOT NULL
)
SELECT
    reason_category,
    num_customers,
    pct_of_total_churn,
    avg_monthly_charges,
    diff_from_prev_reason
FROM ranked_reasons
ORDER BY num_customers DESC;

--Insight: Based on the analysis, Competitor related churn dominate and large gaps between product dissatisfaction supports this.



