CREATE TABLE income_clean AS
SELECT 
    GEO_ID,
    NAME,
    S1901_C01_012E AS median_household_income
FROM income_raw
WHERE GEO_ID != 'Geography';
