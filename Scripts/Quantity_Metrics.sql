SELECT * 
FROM [Clean_Cafe_Data]

SELECT * 
FROM Cafe_Analysis -- Checking view

SELECT 
Item_Name,
FORMAT(Transaction_Date, 'yyyy-MM') Month,
COUNT(Quantity) Orders_Made,
SUM(Quantity) Items_Sold,
AVG(Quantity) Avg_Quantity,
SUM(Quantity) - 
	LAG(SUM(Quantity)) OVER (PARTITION BY Item_Name 
	ORDER BY FORMAT(Transaction_Date, 'yyyy-MM')
	) AS Quantity_Difference_From_Previous_Month
FROM Cafe_Analysis
WHERE Transaction_Date != '2022'
GROUP BY FORMAT(Transaction_Date, 'yyyy-MM'),
Item_Name 

--Checking to see the monthly numbers of orders made, and the number of items sold for each product
--And the average quantity overall, as well as the difference from previous months

SELECT
COUNT(Item_Name) Items_Sold,
COUNT(Quantity) Quantity_of_Items
FROM Cafe_Analysis
WHERE Item_Name != 'UNKNOWN'
AND Quantity IS NOT NULL --Checking and resolving issue with mismatched counting Quantity and Item Names


SELECT *
FROM (
	SELECT
		Quantity,
		FORMAT(Transaction_Date, 'yyyy-MM') MONTH,
		Item_Name
	FROM Cafe_Analysis
) AS Date_Metric_Source
PIVOT (
	SUM(Quantity)
	FOR MONTH IN ([2023-01], [2023-02], [2023-03], [2023-04], [2023-05], [2023-06],
	[2023-07], [2023-08], [2023-09], [2023-10], [2023-11], [2023-12]
)) AS Month_Lookup
ORDER BY Item_Name --Using Static Pivot table to check the amount of purchases made of each product monthly

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
        Item_Name,
        FORMAT(Transaction_Date, ''yyyy-MM'') AS SaleMonth,
        Quantity
    FROM Cafe_Analysis
	WHERE Transaction_Date != ''2022''
) AS src
PIVOT (
    SUM(Quantity)
    FOR SaleMonth IN (' + @cols + ')
) AS pvt
ORDER BY Item_Name;
';

-- Step 3: Execute it
EXEC sp_executesql @sql;-- Same as above, but with Dynamic Pivot Table