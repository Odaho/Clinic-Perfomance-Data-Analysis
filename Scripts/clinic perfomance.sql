/* 
Standardise visit_status values so analytics are accurate.
This prevents 'Completed' and 'completed' from being counted separately.
*/

UPDATE visits
SET visit_status =
    CASE
        WHEN LOWER(visit_status) = 'completed' THEN 'Completed'
        WHEN LOWER(visit_status) = 'no show' THEN 'No Show'
        WHEN LOWER(visit_status) = 'cancelled' THEN 'Cancelled'
        ELSE visit_status
    END;

/*
Ensure gender values are consistent.
Only 'M', 'F', or 'Unknown' are allowed.
*/

UPDATE patients
SET gender =
    CASE
        WHEN gender IN ('M', 'F') THEN gender
        ELSE 'Unknown'
    END;

/*
Remove payments with zero amount.
Zero payments distort revenue calculations.
*/

DELETE FROM payments
WHERE amount_paid = 0;

----------------------------------------------------------------
###########CREATING VIEWS FOR VISUALS###########################
----------------------------------------------------------------

/*
This view aggregates completed visits by date.
Power BI can use this to display:
- Visits per day
- Visits per week
- Visits per month
*/

CREATE VIEW vw_patient_visits AS
SELECT
    CAST(visit_date AS DATE) AS visit_day,         -- Exact visit date
    DATENAME(WEEK, visit_date) AS visit_week,      -- Week number/name
    DATENAME(MONTH, visit_date) AS visit_month,    -- Month name
    COUNT(*) AS total_visits                        -- Number of visits
FROM visits
WHERE visit_status = 'Completed'                   -- Only completed visits count
GROUP BY
    CAST(visit_date AS DATE),
    DATENAME(WEEK, visit_date),
    DATENAME(MONTH, visit_date);

/*
This view aggregates completed visits by date.
Power BI can use this to display:
- Visits per day
- Visits per week
- Visits per month
*/

CREATE VIEW vw_patient_visits AS
SELECT
    CAST(visit_date AS DATE) AS visit_day,         -- Exact visit date
    DATENAME(WEEK, visit_date) AS visit_week,      -- Week number/name
    DATENAME(MONTH, visit_date) AS visit_month,    -- Month name
    COUNT(*) AS total_visits                        -- Number of visits
FROM visits
WHERE visit_status = 'Completed'                   -- Only completed visits count
GROUP BY
    CAST(visit_date AS DATE),
    DATENAME(WEEK, visit_date),
    DATENAME(MONTH, visit_date);

/*
Identifies patients who visited the clinic more than once.
Used to measure patient retention.
*/

CREATE VIEW vw_repeat_patients AS
SELECT
    patient_id,                                    -- Patient identifier
    COUNT(*) AS visit_count                        -- Number of visits
FROM visits
WHERE visit_status = 'Completed'                   -- Only completed visits matter
GROUP BY patient_id
HAVING COUNT(*) > 1;                               -- More than one visit = repeat patient

/*
Provides revenue per treatment.
Power BI will apply Pareto (80/20) logic on this data.
*/

CREATE VIEW vw_treatment_revenue_pareto AS
SELECT
    t.treatment_name,                              -- Treatment name
    SUM(p.amount_paid) AS total_revenue             -- Revenue per treatment
FROM payments p
JOIN treatments t
    ON p.treatment_id = t.treatment_id
GROUP BY t.treatment_name;
