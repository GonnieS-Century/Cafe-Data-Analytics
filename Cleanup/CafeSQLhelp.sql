Select  * from [dbo].[dirty_cafe_sales] 

SELECT	* FROM	[Clean_Cafe_Data]

--//--

SELECT 
COALESCE(Quantity, (Total_Spent/Price_Per_Unit)) AS Quantity,
COALESCE(Total_Spent, (Price_Per_Unit * Quantity)) AS Total_Spent,
COALESCE(Price_Per_Unit, (Total_Spent/Quantity)) AS Price_Per_Unit
FROM [dbo].[dirty_cafe_sales]  -- equation used to determine the values to replace the nulls in the respective columns, if applicable

SELECT	
dirty.Transaction_ID,
typ.ItemID,
dirty.Quantity,
dirty.Total_Spent,
dirty.Payment_Method,
dirty.Transaction_Date
INTO [Clean_Cafe_Data]
FROM [dirty_cafe_sales] dirty
LEFT JOIN	[Item_type] typ
ON	(dirty.Item = typ.Item_Name)
	AND dirty.Item != 'UNKNOWN' -- joining tables based on the Items that coincide and are not UNKNOWN in order to insert the Item ID column with unique identifiers


SELECT 
c.Transaction_ID,
t.Item_Name,
c.Quantity,    
t.Price_Per_Unit,
c.Total_Spent,
c.Payment_Method,
c.Transaction_Date,
t.ItemID
FROM [Clean_Cafe_Data] AS c
LEFT JOIN [Item_type] AS t
    ON c.ItemID = t.ItemID; -- joining with unique ItemID identifiers

--//--

ALTER TABLE [Clean_Cafe_Data]
ADD Price_Per_Unit DECIMAL(10,2);

UPDATE c
SET c.Price_Per_Unit = t.Price_Per_Unit
FROM [Clean_Cafe_Data] c
INNER JOIN [Item_type] t
    ON c.ItemID = t.ItemID;

update [Clean_Cafe_Data]
set Quantity = coalesce(Quantity, (Total_Spent/Price_Per_Unit)),
Total_Spent = coalesce(Total_Spent, (Price_Per_Unit * Quantity)),
Price_Per_Unit = coalesce(Price_Per_Unit, (Total_Spent/Quantity));

-- Replacing the null values of the respective columns with the equation gathered from prior research
-- May still return null values due to lack of information, unable to logically continue

--//--

UPDATE c
SET 
c.Location = p.Location,
c.Payment_Method = p.Payment_Method
FROM [Clean_Cafe_Data] c
INNER JOIN [dirty_cafe_sales] p
    ON c.Transaction_ID = p.Transaction_ID; -- Joining with Raw data, unable to clean it up further

UPDATE Clean_Cafe_Data
SET Location = 'UNKNOWN'
WHERE Location IS NULL 
   OR Location = 'ERROR'; -- Replacing multiple null value denominations with just one

--//--

SELECT 
c.Transaction_ID,
c.Quantity,    
c.Total_Spent,
c.Payment_Method,
c.Transaction_Date,
c.PaymentID
FROM [Clean_Cafe_Data] AS c
LEFT JOIN [transaction_type] AS t
    ON c.PaymentID = t.PaymentID; -- Checking join results

SELECT 
c.Transaction_ID,
c.Payment_Method AS Old_Payment_Method,
tt.Payment_Method AS New_Payment_Method
FROM Clean_Cafe_Data c
JOIN transaction_type tt 
	ON c.PaymentID = tt.PaymentID -- Previewing before making the join effective. 

UPDATE c
SET c.Payment_Method =
    CASE
        WHEN c.Payment_Method IS NULL 
             OR c.Payment_Method IN ('NULL', 'UNKNOWN', 'ERROR')
        THEN tt.Payment_Method
        ELSE c.Payment_Method
    END
FROM [Clean_Cafe_Data] c
JOIN transaction_type tt 
	ON tt.PaymentID = c.PaymentID;  -- adjust join condition

--//--

select * from Clean_Cafe_Data
where ItemID = '-1'

-- Checking an invalid ItemID issue

select
t.ItemID
FROM [Clean_Cafe_Data] AS c
LEFT JOIN [Item_type] AS t
    ON c.Item_Name = t.Item_Name; -- Checking the join before making it effective

update c
set c.itemID = t.ItemID 
FROM [Clean_Cafe_Data] AS c
JOIN [Item_type] AS t
    ON c.Price_Per_Unit = t.Price_Per_Unit
	AND c.Item_Name = t.Item_Name; -- joining tables to resolve invalid ItemID issue

--//--

select distinct PaymentID, Payment_Method from Clean_Cafe_Data

UPDATE c
SET c.PaymentID = p.PaymentID
FROM [Clean_Cafe_Data] c
Left JOIN [transaction_type] p
    ON c.Payment_Method = p.Payment_Method -- Joining to fill the PaymentID column
											--Reminder to withhold this column when creating the view

alter table [clean_cafe_data]
add Transaction_Date date

UPDATE c
SET c.Transaction_Date = p.Transaction_Date
FROM [Clean_Cafe_Data] c
Left JOIN [dirty_cafe_sales] p
    ON c.Transaction_ID = p.Transaction_ID -- Joining to fill the transaction date column

UPDATE Clean_Cafe_Data
SET Transaction_Date = '2022-01-01'
WHERE Transaction_Date IS NULL -- Replacing the null values in transaction date with 2022, since the table only displays results in 2023
								-- Reminder to filter out 2022 when making the reporting in PowerBI!!!

--//--

WITH UniquePrices AS (
    SELECT 
        Price_Per_Unit,
        MAX(ItemID) AS ItemID,
        MAX(Item_Name) AS Item_Name
    FROM [Clean_Cafe_Data]
    WHERE ItemID IS NOT NULL AND Item_Name IS NOT NULL
    GROUP BY Price_Per_Unit
    HAVING COUNT(DISTINCT Item_Name) = 1
)

-- This common table expression is to set the distinct items with the respective prices assigned to them, and to make it easier for future updates and corrections

SELECT *
FROM [Clean_Cafe_Data] c1
LEFT JOIN UniquePrices u
    ON c1.Price_Per_Unit = u.Price_Per_Unit
WHERE c1.ItemID IS NULL OR c1.Item_Name IS NULL; -- joining table with CTE

UPDATE c1
SET		c1.ItemID = 
        CASE 
            WHEN u.ItemID IS NOT NULL THEN u.ItemID 
            ELSE NULL 
        END,
		c1.Item_Name = 
        CASE 
            WHEN u.Item_Name IS NOT NULL THEN u.Item_Name 
            ELSE 'UNKNOWN'
        END
FROM [Clean_Cafe_Data] c1
LEFT JOIN UniquePrices u
    ON c1.Price_Per_Unit = u.Price_Per_Unit
	WHERE c1.ItemID IS NULL OR c1.Item_Name IS NULL;  -- This script is to replace null values in Item ID and Item_Name with corresponding values derived from Price column.


update Clean_Cafe_Data 
SET PaymentID =
	CASE	
		WHEN PaymentID IS NOT NULL THEN PaymentID
		ELSE 1
	END -- Filling in the null values to remove one of the paymentID types and to make it easier for future data updates and corrections

--//--

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Item_type' -- For schema checking when adding and updating columns 

