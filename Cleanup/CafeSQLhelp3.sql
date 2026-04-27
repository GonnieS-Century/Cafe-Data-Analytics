create table transaction_type (
PaymentID int identity(1,1),
Payment_Method varchar(250),
);

--//--

select * from [transaction_type]

DELETE
FROM [transaction_type] 
WHERE PaymentID = '10031'
	AND PaymentID = '10032'; -- Deleting empty values

UPDATE transaction_type
SET Payment_Method = 'UNKNOWN'
WHERE Payment_Method IS NULL 
   OR Payment_Method = 'ERROR';

-- Replacing multiple null value denominations with just one 

--//--

WITH Duplicates AS (
    SELECT
        PaymentID,
        Payment_Method,
        ROW_NUMBER() OVER (
            PARTITION BY Payment_Method
            ORDER BY PaymentID
        ) AS rn
    FROM transaction_type
)
delete FROM Duplicates
WHERE rn > 1;

-- Removing duplicates from table, CTE used for potential views

  