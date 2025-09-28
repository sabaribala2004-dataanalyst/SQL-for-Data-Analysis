CREATE TABLE e_commerce (
  order_date DATE,
  time TIME,        -- Use TIME if only time part; change to TIMESTAMP if date+time
  aging NUMERIC(10,2),
  customer_id int,
  gender VARCHAR(10),
  device_type VARCHAR(50),
  customer_login_type VARCHAR(50),
  product_category VARCHAR(100),
  product VARCHAR(200),
  sales NUMERIC(12,2),
  quantity int,
  discount NUMERIC(5,2),
  profit NUMERIC(12,2),
  shipping_cost NUMERIC(12,2),
  order_priority VARCHAR(20),
  payment_method VARCHAR(50)
);
ALTER TABLE e_commerce
DROP COLUMN id;


copy e_commerce from 'C:\Program Files\PostgreSQL\18\e_commerce.csv' delimiter',' csv header;

select*from e_commerce;
SELECT Order_Date, Customer_Id, Product, Sales, Profit 
FROM  e_commerce
LIMIT 10;

-- 2. Filtering (WHERE)
SELECT Product, Profit, Order_Priority
FROM e_commerce
WHERE Profit > 50.00;

-- 3. Sorting (ORDER BY)
SELECT  Product, Profit, Order_Priority
FROM e_commerce
WHERE Order_Priority = 'Critical'
ORDER BY Profit DESC;

-- 4. Aggregation (SUM, AVG)
SELECT
    SUM(Sales) AS Total_Sales,
    AVG(Profit) AS Average_Profit
FROM e_commerce ;

-- 5. Grouping (GROUP BY)
SELECT
    Product_Category,
    COUNT(*) AS Number_of_Orders,
    AVG(Sales) AS Average_Sales
FROM e_commerce
GROUP BY Product_Category
ORDER BY Average_Sales DESC;

-- 6. Grouping with Filtering (HAVING)
SELECT
    Product_Category,
    AVG(Profit) AS Average_Profit
FROM e_commerce
GROUP BY Product_Category
HAVING AVG(Profit) > 30.00
ORDER BY Average_Profit DESC;

-- Subquery: Finds orders above the average sales
SELECT
    Order_Date,
    Product,
    Sales
FROM e_commerce
WHERE Sales > (
    SELECT AVG(Sales)
    FROM e_commerce
)
ORDER BY Sales DESC;
-- Create a View
CREATE VIEW High_Value_Orders_View AS
SELECT
    Order_Date,
    Customer_Id,
    Product,
    Sales,
    Profit,
    Order_Priority
FROM e_commerce
WHERE Profit > 100.00 AND Order_Priority = 'Critical';

-- Query the View
SELECT *
FROM High_Value_Orders_View
ORDER BY Order_Date DESC;

-- Add an index on Customer_Id for faster lookups based on a specific customer
CREATE INDEX idx_customer_id
ON e_commerce (Customer_Id);

-- Add a composite index on Order_Date and Product_Category for filtering reports
CREATE INDEX idx_date_category
ON  e_commerce (Order_Date, Product_Category);

CREATE TABLE Customers (
    Customer_Id INT PRIMARY KEY,
    Customer_Name VARCHAR(100),
    City VARCHAR(50)
);
select*from e_commerce;

 
	
-- 2) Inner Join
SELECT
    T1.Order_Date,
    T1.Customer_Id,
    T1.Product AS First_Product,
    T2.Product AS Second_Product
FROM 
    e_commerce AS T1
INNER JOIN 
    e_commerce AS T2
    ON T1.Customer_Id = T2.Customer_Id
    AND T1.Order_Date = T2.Order_Date
    AND T1.Product < T2.Product
LIMIT 10;

-- Create a temporary table containing all unique payment methods (and one fictitious one)
CREATE TEMPORARY TABLE T_Methods AS
SELECT DISTINCT Payment_method 
FROM e_commerce
UNION 
SELECT 'bank_transfer' AS Payment_method; -- Add a hypothetical method that might not be in your sales data

 ---- Left Join
SELECT
    T1.Payment_method,
    COUNT(T2.Customer_Id) AS Total_Orders,
    SUM(T2.Sales) AS Total_Sales
FROM
    T_Methods AS T1                                 -- LEFT Table (All Methods)
LEFT JOIN
    e_commerce AS T2                        -- RIGHT Table (Orders)
    ON T1.Payment_method = T2.Payment_method        -- Join condition
GROUP BY
    T1.Payment_method
ORDER BY
    Total_Sales DESC NULLS LAST;

CREATE TEMPORARY TABLE T_Devices (
    Standard_Device_Type VARCHAR(20) PRIMARY KEY
);

-- Create a temporary table containing a complete list of expected device types
CREATE TEMPORARY TABLE T_Devices (
    Standard_Device_Type VARCHAR(20) PRIMARY KEY
);

-- Insert standard device types, including one ('Desktop') that may not exist in your orders.
INSERT INTO T_Devices (Standard_Device_Type) VALUES
('Web'),
('Mobile'),
('Desktop'); -- The unmatched record

--- Right Join
SELECT
    T2.Standard_Device_Type, -- All devices from the right table
    COUNT(T1.Customer_Id) AS Total_Orders,
    SUM(T1.Sales) AS Total_Sales_Value
FROM
     e_commerce AS T1                         -- LEFT Table (Orders)
RIGHT JOIN
    T_Devices AS T2                                 -- RIGHT Table (All Standard Devices)
    ON T1.Device_Type = T2.Standard_Device_Type     -- Joining on the matching device type
GROUP BY
    T2.Standard_Device_Type
ORDER BY
    Total_Sales_Value DESC NULLS LAST;
	
---- aggregiation Functions
SELECT
    Product_Category,
    COUNT(Customer_Id) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Profit) AS Average_Profit
FROM 
     e_commerce
GROUP BY
    Product_Category
ORDER BY
    Total_Sales DESC;

	--final result
 WITH Category_Sales AS (
    -- 1. Calculate the total sales for each product within its category
    SELECT
        Product_Category,
        Product,
        SUM(Sales) AS Total_Product_Sales,
    -- 2 Use the window function RANK() 
        RANK() OVER (
            PARTITION BY Product_Category 
            ORDER BY SUM(Sales) DESC
        ) as Rank_In_Category
    FROM e_commerce
    GROUP BY 
        Product_Category, 
        Product
)
-- 2) Select the final result, top 3 (Rank)
SELECT
    Product_Category,
    Product,
    Total_Product_Sales
FROM Category_Sales
WHERE Rank_In_Category <= 3
ORDER BY 
    Product_Category, 
    Total_Product_Sales DESC;

	