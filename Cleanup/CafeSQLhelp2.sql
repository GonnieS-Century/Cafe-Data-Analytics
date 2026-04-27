create table Item_type (
ItemID int identity (1,1),
Item_Name varchar (250)
);

--//--


select * 
from [Item_type]

INSERT INTO [Item_type](Item_Name) SELECT DISTINCT Item FROM [dirty_cafe_sales]

DELETE FROM [Item_type] WHERE Item_Name = 'UNKNOWN' OR Item_name = 'ERROR';

UPDATE [Item_type]
SET [Item_Name]= 'UNKNOWN'
WHERE [Item_Name] IS NULL

-- Replacing null values with just UNKNOWN, subject to change

--//--

Alter table [Item_type]
add Price_Per_Unit decimal (18,2) -- Adding the price column after the fact after analysis, realized it was relevant to the item columns


INSERT INTO Item_type ([Price_Per_Unit])
SELECT CONVERT(Decimal(18,2), Price_Per_Unit) 
FROM [dirty_cafe_sales]; --Using insert rather than join due to the convert statement


UPDATE [Item_type]
SET Price_Per_Unit = ip.Price_Per_Unit
FROM [dirty_cafe_sales] ip
WHERE Item_type.Price_Per_Unit = ip.Price_Per_Unit; -- Regular join first

UPDATE it
SET it.Price_Per_Unit = dcs.Price_Per_Unit
FROM Item_type it
JOIN dirty_cafe_sales dcs
  ON it.Item_Name = dcs.Item
WHERE dcs.Price_Per_Unit IS NOT NULL and dcs.Item is NOT NULL; -- Joining the two tables by setting the price per unit of [dcs] for the same item, but only if there is a valid Item name and price

--//--

SELECT 
s.ItemID, 
s.Item_Name AS Old_Name, 
r.Item AS New_Name,
s.Price_Per_Unit AS Old_Price, 
r.Price_Per_Unit AS New_Price
FROM [Item_type] s
JOIN [dirty_cafe_sales] r
    ON s.ItemID = r.Transaction_ID
WHERE s.Item_Name IS NULL OR s.Price_Per_Unit IS NULL;

-- Previewing the changes that will be made

UPDATE t1
SET t1.Item_Name = src.Item_Name
FROM [Item_type] t1
JOIN (
    SELECT 
	Price_Per_Unit, 
	MIN(Item_Name) AS Item_Name
    FROM [Item_type]
    WHERE Item_Name IS NOT NULL AND Item_Name <> 'UNKNOWN'
    GROUP BY Price_Per_Unit
    HAVING COUNT(DISTINCT Item_Name) = 1
) AS src
    ON t1.Price_Per_Unit = src.Price_Per_Unit
WHERE t1.Item_Name IS NULL;

-- This update statement is used to fill missing values by using item names from other rows with the same price, but only when that price identifies a single item

UPDATE [Item_type]
SET Item_Name = 'UNKNOWN'
WHERE Item_Name IS NULL; -- Replacing null value with UNKNOWN

--//--

WITH ToDelete AS (
    SELECT ItemID
    FROM [Item_type]
    WHERE Item_Name = 'UNKNOWN'
      AND ItemID NOT IN (
          SELECT MIN(ItemID)
          FROM [Item_type]
          WHERE Item_Name = 'UNKNOWN'
          GROUP BY Price_Per_Unit
      )
)
DELETE FROM [Item_type]
WHERE ItemID IN (SELECT ItemID FROM ToDelete);

-- This CTE deletes duplicate UNKNOWN values from the table so that only one row per price remains
-- Note that 3 and 4 dollar prices have multiple items corresponding to it

DELETE FROM [Item_type]
WHERE ItemID IN (
    SELECT t1.ItemID
    FROM [Item_type] t1
    JOIN [Item_type] t2
      ON t1.Item_Name = t2.Item_Name
     AND t1.Price_Per_Unit = t2.Price_Per_Unit
     AND t1.ItemID > t2.ItemID
);

-- This statement is used to delete duplicate rows based on Item name + price per unit, while only the smallest itemID remains

