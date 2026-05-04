SELECT * 
FROM [Clean_Cafe_Data]

SELECT 
MIN(Transaction_Date) Oldest_Transaction,
MAX(Transaction_Date) Recent_Transaction,
COUNT(Quantity) Orders_Made,
SUM(Quantity) Items_Sold,
MONTH(Transaction_Date) Month
FROM Cafe_Analysis
WHERE Transaction_Date != '2022'
GROUP BY MONTH(Transaction_Date)
ORDER BY MONTH(Transaction_Date) ASC 

--Finding the total numbers of orders made each month
--As well as the first and last order ever made during the same periods

WITH TopSales AS (
    SELECT
        Quantity,
		Transaction_Date,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(Transaction_Date), MONTH(Transaction_Date)
            ORDER BY Quantity DESC
        ) AS rn
    FROM Cafe_Analysis
	WHERE Transaction_Date != '2022'
)
SELECT *
FROM TopSales
WHERE rn <= 5
ORDER BY YEAR(Transaction_Date), 
MONTH(Transaction_Date), 
rn; --Checking the days where the 5 highest number of sales were made

-----////-----

SELECT *
FROM (
	SELECT
		Payment_Method,
		FORMAT(Transaction_Date, 'yyyy-MM') MONTH,
		Total_Spent
	FROM Cafe_Analysis
) AS Date_Metric_Source
PIVOT (
	SUM(Total_Spent)
	FOR MONTH IN ([2023-01], [2023-02], [2023-03], [2023-04], [2023-05], [2023-06],
	[2023-07], [2023-08], [2023-09], [2023-10], [2023-11], [2023-12]
)) AS Month_Lookup
ORDER BY Payment_Method
--Using Static Pivot table to check the payment method of purchases monthly



DECLARE @cols NVARCHAR(MAX);
DECLARE @sql  NVARCHAR(MAX);

-- Step 1: Build column list dynamically
SELECT @cols = STRING_AGG(QUOTENAME(m), ',')
FROM (SELECT DISTINCT FORMAT(Transaction_Date, 'yyyy-MM') AS m FROM Cafe_Analysis) d;

-- Step 2: Build the pivot query
SET @sql = '
SELECT *
FROM (
    SELECT 
        Payment_Method,
        FORMAT(Transaction_Date, ''yyyy-MM'') AS SaleMonth,
        Total_Spent
    FROM Cafe_Analysis
	WHERE Transaction_Date != ''2022''
) AS src
PIVOT (
    SUM(Total_Spent)
    FOR SaleMonth IN (' + @cols + ')
) AS pvt
ORDER BY Payment_Method;
';

-- Step 3: Execute it
EXEC sp_executesql @sql; --Same as above but using Dynamic Pivot Table
