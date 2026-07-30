-- Databricks notebook source
-- ============================================================
-- PROJECT: FNB Sales Case Study Analysis
-- ANALYST: Siyakha Ntuli
-- DATE: July 2026
-- PURPOSE: Complete end-to-end data analysis
-- FIXED VERSION: corrected syntax errors and promo-grouping logic
-- ============================================================

-- ============================================================
-- PART 1: DATA EXPLORATION
-- ============================================================

-- 1.1 Table structure
DESCRIBE retail.default.sales_case_study_2021;

-- 1.2 View sample data
SELECT * FROM retail.default.sales_case_study_2021 LIMIT 5;

-- 1.3 Date range and record count
SELECT 
    MIN(Date) AS First_Date,
    MAX(Date) AS Last_Date,
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Date) AS Unique_Dates,
    DATEDIFF(MAX(Date), MIN(Date)) + 1 AS Expected_Days,
    (DATEDIFF(MAX(Date), MIN(Date)) + 1) - COUNT(*) AS Missing_Days
FROM retail.default.sales_case_study_2021;

-- 1.4 Summary statistics
-- FIX: Min_Qty / Max_Qty / Avg_Qty were pulling from the wrong columns
SELECT 
    ROUND(MIN(Sales), 2) AS Min_Sales,
    ROUND(MAX(Sales), 2) AS Max_Sales,
    ROUND(AVG(Sales), 2) AS Avg_Sales,
    ROUND(MIN(`Cost Of Sales`), 2) AS Min_Cost,
    ROUND(MAX(`Cost Of Sales`), 2) AS Max_Cost,
    ROUND(MIN(`Quantity Sold`), 0) AS Min_Qty,
    ROUND(MAX(`Quantity Sold`), 0) AS Max_Qty,
    ROUND(AVG(`Quantity Sold`), 0) AS Avg_Qty
FROM retail.default.sales_case_study_2021;

-- 1.5 Null values check
SELECT 
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS Null_Dates,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Null_Sales,
    SUM(CASE WHEN `Cost Of Sales` IS NULL THEN 1 ELSE 0 END) AS Null_Cost,
    SUM(CASE WHEN `Quantity Sold` IS NULL THEN 1 ELSE 0 END) AS Null_Qty
FROM retail.default.sales_case_study_2021;

-- 1.6 Distinct values - view then count
SELECT DISTINCT Date FROM retail.default.sales_case_study_2021 ORDER BY Date LIMIT 10;

SELECT DISTINCT `Quantity Sold` FROM retail.default.sales_case_study_2021 ORDER BY `Quantity Sold` LIMIT 10;

SELECT 
    COUNT(DISTINCT Date) AS Distinct_Dates,
    COUNT(DISTINCT Sales) AS Distinct_Sales,
    COUNT(DISTINCT `Cost Of Sales`) AS Distinct_Cost,
    COUNT(DISTINCT `Quantity Sold`) AS Distinct_Qty
FROM retail.default.sales_case_study_2021;

-- 1.7 Profitability check
SELECT 
    COUNT(*) AS Total_Days,
    SUM(CASE WHEN Sales > `Cost Of Sales` THEN 1 ELSE 0 END) AS Profitable_Days,
    SUM(CASE WHEN Sales < `Cost Of Sales` THEN 1 ELSE 0 END) AS Loss_Days,
    ROUND(SUM(CASE WHEN Sales > `Cost Of Sales` THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Pct_Profitable
FROM retail.default.sales_case_study_2021;

-- 1.8 Check for invalid data
SELECT 
    SUM(CASE WHEN Sales <= 0 THEN 1 ELSE 0 END) AS Invalid_Sales,
    SUM(CASE WHEN `Cost Of Sales` <= 0 THEN 1 ELSE 0 END) AS Invalid_Cost,
    SUM(CASE WHEN `Quantity Sold` <= 0 THEN 1 ELSE 0 END) AS Invalid_Qty
FROM retail.default.sales_case_study_2021;

-- 1.9 Year summary
SELECT 
    YEAR(Date) AS Year,
    COUNT(*) AS Days,
    ROUND(SUM(Sales), 0) AS Total_Sales,
    ROUND(AVG(Sales), 0) AS Avg_Sales,
    SUM(`Quantity Sold`) AS Total_Units,
    ROUND((SUM(Sales) - SUM(`Cost Of Sales`)) / NULLIF(SUM(Sales), 0) * 100, 2) AS GP_Pct
FROM retail.default.sales_case_study_2021
GROUP BY YEAR(Date)
ORDER BY Year;

-- 1.10 Quick unit price check
SELECT 
    ROUND(MIN(Sales / NULLIF(`Quantity Sold`, 0)), 2) AS Min_Price,
    ROUND(MAX(Sales / NULLIF(`Quantity Sold`, 0)), 2) AS Max_Price,
    ROUND(AVG(Sales / NULLIF(`Quantity Sold`, 0)), 2) AS Avg_Price
FROM retail.default.sales_case_study_2021
WHERE `Quantity Sold` > 0;


-- ============================================================
-- PART 2: CREATE CLEANED VIEW WITH ALL METRICS
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_analytics AS
SELECT 
    Date,
    Sales,
    `Cost Of Sales`,
    `Quantity Sold`,
    
    -- METRIC 1: Daily Unit Price
    ROUND(Sales / NULLIF(`Quantity Sold`, 0), 2) AS Unit_Price,
    
    -- Helper: Unit Cost
    ROUND(`Cost Of Sales` / NULLIF(`Quantity Sold`, 0), 2) AS Unit_Cost,
    
    -- Helper: Gross Profit Rands
    ROUND(Sales - `Cost Of Sales`, 2) AS Gross_Profit_Rands,
    
    -- METRIC 3: Daily % Gross Profit
    ROUND((Sales - `Cost Of Sales`) / NULLIF(Sales, 0) * 100, 2) AS Gross_Profit_Pct,
    
    -- METRIC 4: Daily % Gross Profit Per Unit
    ROUND(
        ((Sales / NULLIF(`Quantity Sold`, 0)) - (`Cost Of Sales` / NULLIF(`Quantity Sold`, 0))) 
        / NULLIF((Sales / NULLIF(`Quantity Sold`, 0)), 0) * 100, 
    2) AS GP_Per_Unit_Pct,
    
    -- Time dimensions
    YEAR(Date) AS Year,
    MONTH(Date) AS Month,
    DATE_FORMAT(Date, 'MMMM') AS Month_Name,
    DATE_FORMAT(Date, 'EEEE') AS Day_Name,
    DAYOFWEEK(Date) AS Day_Of_Week,
    QUARTER(Date) AS Quarter,
    
    -- Categories for insights
    CASE 
        WHEN ROUND(Sales / NULLIF(`Quantity Sold`, 0), 2) <= 20 THEN 'Budget'
        WHEN ROUND(Sales / NULLIF(`Quantity Sold`, 0), 2) <= 35 THEN 'Mid-Range'
        WHEN ROUND(Sales / NULLIF(`Quantity Sold`, 0), 2) <= 50 THEN 'Premium'
        ELSE 'Luxury'
    END AS Price_Category

FROM retail.default.sales_case_study_2021
WHERE `Quantity Sold` > 0 
  AND Sales > 0 
  AND `Cost Of Sales` > 0;

-- Verify view
SELECT * FROM vw_sales_analytics LIMIT 10;


-- ============================================================
-- PART 3: REQUIRED METRICS
-- ============================================================

-- METRIC 1: Daily Unit Price (sample)
SELECT 
    Date,
    Unit_Price AS Daily_Sales_Price_Per_Unit
FROM vw_sales_analytics
LIMIT 10;

-- METRIC 2: Average Unit Sales Price
SELECT 
    'Overall Average' AS Metric,
    ROUND(SUM(Sales) / NULLIF(SUM(`Quantity Sold`), 0), 2) AS Avg_Unit_Price
FROM vw_sales_analytics;

-- Average by Year
SELECT 
    Year,
    ROUND(SUM(Sales) / NULLIF(SUM(`Quantity Sold`), 0), 2) AS Avg_Unit_Price,
    COUNT(*) AS Days
FROM vw_sales_analytics
GROUP BY Year
ORDER BY Year;

-- METRIC 3: Daily Gross Profit % (sample)
SELECT 
    Date,
    Gross_Profit_Pct AS Daily_GP_Pct
FROM vw_sales_analytics
LIMIT 10;

-- METRIC 4: Daily GP % Per Unit (sample)
SELECT 
    Date,
    GP_Per_Unit_Pct AS Daily_GP_Per_Unit
FROM vw_sales_analytics
LIMIT 10;


-- ============================================================
-- PART 4: PROMOTIONS & ELASTICITY
-- ============================================================

-- 4.1 Identify promotion periods
-- FIX: original logic incremented Promo_ID on every single promo day,
-- so a 5-day promo got split into 5 separate groups instead of 1.
-- Rewritten using a gaps-and-islands pattern so consecutive promo
-- days are grouped into a single promo period.
WITH price_analysis AS (
    SELECT 
        Date,
        Unit_Price,
        `Quantity Sold`,
        Sales,
        Gross_Profit_Pct,
        AVG(Unit_Price) OVER (ORDER BY Date ROWS BETWEEN 7 PRECEDING AND 7 FOLLOWING) AS MA15
    FROM vw_sales_analytics
),
flagged AS (
    SELECT 
        *,
        ROUND((Unit_Price - MA15) / NULLIF(MA15, 0) * 100, 2) AS Price_Drop,
        CASE WHEN ROUND((Unit_Price - MA15) / NULLIF(MA15, 0) * 100, 2) < -15 THEN 1 ELSE 0 END AS Is_Promo
    FROM price_analysis
),
islands AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Date) 
            - ROW_NUMBER() OVER (PARTITION BY Is_Promo ORDER BY Date) AS Grp_Key
    FROM flagged
)
SELECT 
    Grp_Key AS Promo_ID,
    MIN(Date) AS Promo_Start,
    MAX(Date) AS Promo_End,
    COUNT(*) AS Days,
    ROUND(AVG(Unit_Price), 2) AS Promo_Price,
    ROUND(AVG(`Quantity Sold`), 0) AS Promo_Qty,
    ROUND(AVG(Price_Drop), 2) AS Avg_Price_Drop_Pct
FROM islands
WHERE Is_Promo = 1
GROUP BY Grp_Key
HAVING COUNT(*) >= 3
ORDER BY Avg_Price_Drop_Pct ASC
LIMIT 5;

-- 4.2 Price Elasticity for Top 3 Promotions
-- IMPORTANT: Replace dates with actual dates from the 4.1 results above
-- Commented out until actual promotion dates are provided
/* WITH selected_promos AS (
    SELECT 1 AS ID, DATE'YYYY-MM-DD' AS Start_Date, DATE'YYYY-MM-DD' AS End_Date, 'Promo 1' AS Name
    UNION ALL
    SELECT 2, DATE'YYYY-MM-DD', DATE'YYYY-MM-DD', 'Promo 2'
    UNION ALL
    SELECT 3, DATE'YYYY-MM-DD', DATE'YYYY-MM-DD', 'Promo 3'
),
baseline AS (
    SELECT 
        p.ID,
        p.Name,
        ROUND(AVG(v.Unit_Price), 2) AS Base_Price,
        ROUND(AVG(v.`Quantity Sold`), 0) AS Base_Qty,
        ROUND(AVG(v.Sales), 0) AS Base_Sales
    FROM selected_promos p
    JOIN vw_sales_analytics v
        ON v.Date BETWEEN DATE_ADD(p.Start_Date, -14) AND DATE_SUB(p.Start_Date, 1)
    GROUP BY p.ID, p.Name
),
promo_data AS (
    SELECT 
        p.ID,
        p.Name,
        ROUND(AVG(v.Unit_Price), 2) AS Promo_Price,
        ROUND(AVG(v.`Quantity Sold`), 0) AS Promo_Qty,
        ROUND(AVG(v.Sales), 0) AS Promo_Sales
    FROM selected_promos p
    JOIN vw_sales_analytics v
        ON v.Date BETWEEN p.Start_Date AND p.End_Date
    GROUP BY p.ID, p.Name
)
SELECT 
    b.ID,
    b.Name,
    b.Base_Price,
    p.Promo_Price,
    ROUND((p.Promo_Price - b.Base_Price) / b.Base_Price * 100, 2) AS Price_Change_Pct,
    b.Base_Qty,
    p.Promo_Qty,
    ROUND((p.Promo_Qty - b.Base_Qty) / b.Base_Qty * 100, 2) AS Qty_Change_Pct,
    ROUND(((p.Promo_Qty - b.Base_Qty) / b.Base_Qty) / ((p.Promo_Price - b.Base_Price) / b.Base_Price), 2) AS Price_Elasticity,
    CASE 
        WHEN ROUND(((p.Promo_Qty - b.Base_Qty) / b.Base_Qty) / ((p.Promo_Price - b.Base_Price) / b.Base_Price), 2) < -1 THEN 'ELASTIC - Product performs WELL on promotion'
        WHEN ROUND(((p.Promo_Qty - b.Base_Qty) / b.Base_Qty) / ((p.Promo_Price - b.Base_Price) / b.Base_Price), 2) BETWEEN -1 AND 0 THEN 'INELASTIC - Product performs WORSE on promotion'
        ELSE 'UNUSUAL - Further analysis needed'
    END AS Performance
FROM baseline b
JOIN promo_data p ON b.ID = p.ID
ORDER BY b.ID; */


-- ============================================================
-- PART 5: ADDITIONAL INSIGHTS
-- ============================================================

-- 5.1 Monthly summary
SELECT 
    Year,
    Month_Name,
    COUNT(*) AS Days,
    ROUND(SUM(Sales), 0) AS Revenue,
    ROUND(AVG(Sales), 0) AS Avg_Daily_Revenue,
    SUM(`Quantity Sold`) AS Units,
    ROUND(AVG(Gross_Profit_Pct), 2) AS Avg_GP_Pct
FROM vw_sales_analytics
GROUP BY Year, Month, Month_Name
ORDER BY Year, Month;

-- 5.2 Day of week analysis
SELECT 
    Day_Name,
    COUNT(*) AS Days,
    ROUND(AVG(Sales), 0) AS Avg_Sales,
    ROUND(AVG(`Quantity Sold`), 0) AS Avg_Qty,
    ROUND(AVG(Gross_Profit_Pct), 2) AS Avg_GP_Pct
FROM vw_sales_analytics
GROUP BY Day_Name, Day_Of_Week
ORDER BY Day_Of_Week;

-- 5.3 Price category performance
SELECT 
    Price_Category,
    COUNT(*) AS Days,
    ROUND(AVG(Unit_Price), 2) AS Avg_Price,
    ROUND(AVG(`Quantity Sold`), 0) AS Avg_Qty,
    ROUND(AVG(Gross_Profit_Pct), 2) AS Avg_GP_Pct,
    ROUND(SUM(Sales), 0) AS Total_Revenue
FROM vw_sales_analytics
GROUP BY Price_Category
ORDER BY AVG(Unit_Price);

-- 5.4 Year summary
-- FIX: `Cost Of Sales`s) had a stray trailing 's' inside/after the
-- backtick-quoted identifier, which is a syntax error.
SELECT 
    Year,
    ROUND(SUM(Sales), 0) AS Total_Revenue,
    ROUND(SUM(Sales) - SUM(`Cost Of Sales`), 0) AS Total_Profit,
    ROUND((SUM(Sales) - SUM(`Cost Of Sales`)) / SUM(Sales) * 100, 2) AS GP_Pct,
    SUM(`Quantity Sold`) AS Total_Units,
    COUNT(DISTINCT Date) AS Trading_Days
FROM vw_sales_analytics
GROUP BY Year
ORDER BY Year;

-- 5.5 Top 10 days
SELECT 
    Date,
    Day_Name,
    ROUND(Sales, 0) AS Sales,
    `Quantity Sold`,
    Unit_Price,
    Gross_Profit_Pct
FROM vw_sales_analytics
ORDER BY Sales DESC
LIMIT 10;

-- 5.6 Bottom 10 days
-- FIX: `Quantity Sold`uantity_Sold was a broken/mangled column reference
SELECT 
    Date,
    Day_Name,
    ROUND(Sales, 0) AS Sales,
    `Quantity Sold`,
    Unit_Price,
    Gross_Profit_Pct
FROM vw_sales_analytics
ORDER BY Sales ASC
LIMIT 10;

-- 5.7 Final summary
SELECT 
    '=== PROJECT SUMMARY ===' AS Section,
    COUNT(*) AS Total_Days,
    ROUND(SUM(Sales), 0) AS Total_Revenue,
    ROUND(SUM(Sales) - SUM(`Cost Of Sales`), 0) AS Total_Profit,
    ROUND((SUM(Sales) - SUM(`Cost Of Sales`)) / NULLIF(SUM(Sales), 0) * 100, 2) AS Overall_GP_Pct,
    SUM(`Quantity Sold`) AS Total_Units,
    ROUND(SUM(Sales) / NULLIF(SUM(`Quantity Sold`), 0), 2) AS Avg_Unit_Price,
    MIN(Date) AS Data_Start,
    MAX(Date) AS Data_End
FROM vw_sales_analytics;


-- ============================================================
-- PART 6: EXPORT FOR DASHBOARDS
-- ============================================================

-- FIX: "TEMP VIEW" is not valid Spark SQL syntax; must be "TEMPORARY VIEW"
CREATE OR REPLACE TEMPORARY VIEW vw_export AS
SELECT 
    Date,
    Sales,
    `Cost Of Sales`,
    `Quantity Sold`,
    Unit_Price,
    Unit_Cost,
    Gross_Profit_Rands,
    Gross_Profit_Pct,
    GP_Per_Unit_Pct,
    Year,
    Month,
    Month_Name,
    Day_Name,
    Day_Of_Week,
    Quarter,
    Price_Category
FROM vw_sales_analytics
ORDER BY Date;

-- Export this result for Power BI / Excel
SELECT * FROM vw_export;


-- ============================================================
-- END OF SCRIPT
-- ============================================================