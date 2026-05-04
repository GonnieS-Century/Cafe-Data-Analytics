SELECT * 
FROM [Clean_Cafe_Data]

CREATE VIEW Cafe_Analysis AS 
(
	SELECT 
	Transaction_ID,
	Item_Name,
	Quantity,
	Total_Spent,
	Price_Per_Unit,
	Location, 
	Payment_Method,
	Transaction_Date
	FROM [Clean_Cafe_Data]
) -- Creating View to hide complexities

SELECT * 
FROM Cafe_Analysis -- Checking view



SELECT
Item_Name,
MAX(Total_Spent) Highest_Spent,
MIN(Total_Spent) Lowest_Spent,
MAX(Total_Spent) - MIN(Total_Spent) Difference_Spent,
ROUND(AVG(Total_Spent), 2) Avg_Spent,
COUNT(Total_Spent) All_Spent,
SUM(Total_Spent) AS Sum_of_Total_Spent,
ROUND(SUM(Total_Spent) * 100.0 / SUM(SUM(Total_Spent)) OVER (),2) AS Percentage_of_Total
FROM Cafe_Analysis
WHERE Item_Name != 'UNKNOWN'
GROUP BY Item_Name



-- Finding the maximum and minimum orders of each product
-- As well as the percentage of each product and order made, and their difference

WITH Ranked AS (
    SELECT
        Item_Name,
		Total_Spent,
        ROW_NUMBER() OVER (PARTITION BY Item_Name ORDER BY Total_Spent DESC) AS rn_top,
        ROW_NUMBER() OVER (PARTITION BY Item_Name ORDER BY Total_Spent ASC)  AS rn_bottom
    FROM Cafe_Analysis
	WHERE Total_Spent IS NOT NULL
)
SELECT *
FROM Ranked
WHERE rn_top <= 5 OR rn_bottom <= 5 --Checking the top 5 and bottom 5 total spent for each product



SELECT *
FROM (
	SELECT
		Item_Name,
		FORMAT(Transaction_Date, 'yyyy-MM') MONTH,
		Total_Spent
	FROM Cafe_Analysis
) AS Date_Metric_Source
PIVOT (
	SUM(Total_Spent)
	FOR MONTH IN ([2023-01], [2023-02], [2023-03], [2023-04], [2023-05], [2023-06],
	[2023-07], [2023-08], [2023-09], [2023-10], [2023-11], [2023-12]
)) AS Month_Lookup --Using Static Pivot table to check the total spent on each product monthly

--/////--

DECLARE @cols NVARCHAR(MAX);
DECLARE @sql  NVARCHAR(MAX);

-- Step 1: Build column list dynamically
SELECT @cols = STRING_AGG(QUOTENAME(Month), ',')
FROM (SELECT DISTINCT FORMAT(Transaction_Date, 'yyyy-MM') AS Month FROM Cafe_Analysis) d;

-- Step 2: Build the pivot query
SET @sql = '
SELECT *
FROM (
    SELECT 
        Item_Name,
        FORMAT(Transaction_Date, ''yyyy-MM'') AS SaleMonth,
        Total_Spent
    FROM Cafe_Analysis
	WHERE Transaction_Date != ''2022''
) AS src
PIVOT (
    SUM(Total_Spent)
    FOR SaleMonth IN (' + @cols + ')
) AS pvt
ORDER BY Item_Name;
';

-- Step 3: Execute it
EXEC sp_executesql @sql; --Same as above but using Dynamic Pivot Table