CREATE TABLE income_final AS
SELECT 
    REPLACE(GEO_ID, '1400000US', '') AS GEOID_clean,
    NAME,
    CASE 
        WHEN median_household_income IN ('-', 'N', '(X)') THEN NULL
        WHEN median_household_income LIKE '%+%' THEN 250000
        ELSE CAST(median_household_income AS INTEGER)
    END AS median_income
FROM income_clean;
