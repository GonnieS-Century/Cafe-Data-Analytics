SELECT * 
FROM [Clean_Cafe_Data]

SELECT * 
FROM Cafe_Analysis -- Checking view

SELECT 
Location, 
COUNT(Location) Location_Count,
CAST(
	ROUND(COUNT(Location) * 100.0 / SUM(COUNT(Location)) OVER (), 2) 
	AS DECIMAL (5,2)
) AS Percentage_of_Total
FROM Cafe_Analysis
GROUP BY Location -- Checking the percentage of each location type, as well as the amount

SELECT 
Location, 
COUNT(Location) Location_Count,
CAST(
	ROUND(COUNT(Location) * 100.0 / SUM(COUNT(Location)) OVER (), 2) 
	AS DECIMAL (5,2)
) AS Percentage_of_Total
FROM Cafe_Analysis
WHERE Location != 'UNKNOWN'
GROUP BY Location -- Same as above, but without null values

SELECT *
FROM (
	SELECT
		Location,
		FORMAT(Transaction_Date, 'yyyy-MM') MONTH,
		Total_Spent
	FROM Cafe_Analysis
) AS Date_Metric_Source
PIVOT (
	SUM(Total_Spent)
	FOR MONTH IN ([2023-01], [2023-02], [2023-03], [2023-04], [2023-05], [2023-06],
	[2023-07], [2023-08], [2023-09], [2023-10], [2023-11], [2023-12]
)) AS Month_Lookup
ORDER BY Location --Using Static Pivot table to check the locations of purchases of each product monthly

--/////--

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
        Location,
        FORMAT(Transaction_Date, ''yyyy-MM'') AS SaleMonth,
        Total_Spent
    FROM Cafe_Analysis
	WHERE Transaction_Date != ''2022''
) AS src
PIVOT (
    SUM(Total_Spent)
    FOR SaleMonth IN (' + @cols + ')
) AS pvt
ORDER BY Location;
';

-- Step 3: Execute it
EXEC sp_executesql @sql; --Same as above but using Dynamic Pivot Table