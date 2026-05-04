SELECT * 
FROM [Clean_Cafe_Data]

SELECT * 
FROM Cafe_Analysis

SELECT 
Payment_Method, 
COUNT(Payment_Method) PM_Count,
CAST(
	ROUND(COUNT(Payment_Method) * 100.0 / SUM(COUNT(Payment_Method)) OVER (), 2) 
	AS DECIMAL (5,2)
) AS Percentage_of_Total
FROM Cafe_Analysis
GROUP BY Payment_Method -- Checking the percent of the different payment methods used, and the amount

SELECT 
Payment_Method, 
COUNT(Payment_Method) PM_Count,
CAST(
	ROUND(COUNT(Payment_Method) * 100.0 / SUM(COUNT(Payment_Method)) OVER (), 2) 
	AS DECIMAL (5,2)
) AS Percentage_of_Total
FROM Cafe_Analysis
WHERE Payment_Method != 'UNKNOWN'
GROUP BY Payment_Method -- Same as above, but without null values

-----///-----

SELECT *
FROM (
    SELECT 
	Location, 
	Payment_Method
    FROM Cafe_Analysis
) AS PaymentsEffected
PIVOT (
    COUNT(Payment_Method)
    FOR Payment_Method IN ([Cash], [Credit Card], [Digital Wallet], [UNKNOWN])
) AS PivotTable; --Checking the payment methods used in the different locations using a pivot table
				--Cleaner than CASE statements, but potentially harder to debug

DECLARE @cols NVARCHAR(MAX);
DECLARE @sql  NVARCHAR(MAX);

-- Step 1: Build column list dynamically
SELECT @cols = STRING_AGG(QUOTENAME(Payment_Method), ',')
FROM (SELECT DISTINCT Payment_Method FROM Cafe_Analysis) AS x;

-- Step 2: Build the pivot query
SET @sql = '
SELECT *
FROM (
    SELECT Location, 
	Payment_Method
    FROM Cafe_Analysis
) AS src
PIVOT (
    COUNT(Payment_Method)
    FOR Payment_Method IN (' + @cols + ')
) AS pvt
ORDER BY Location;
';

-- Step 3: Execute it
EXEC sp_executesql @sql; --Checking the payment methods used in each type of location with Dynamic Pivot Table



SELECT
    Location,
    SUM(CASE WHEN Payment_Method = 'Cash' THEN 1 ELSE 0 END) AS Cash,
    SUM(CASE WHEN Payment_Method = 'Credit Card' THEN 1 ELSE 0 END) AS CreditCard,
    SUM(CASE WHEN Payment_Method = 'Digital Wallet' THEN 1 ELSE 0 END) AS DigitalWallet,
    SUM(CASE WHEN Payment_Method = 'UNKNOWN' THEN 1 ELSE 0 END) AS Unknown
FROM Cafe_Analysis
GROUP BY Location; --Same as above, but with CASE statements
					--Easier to debug, but wordier

-----///-----





