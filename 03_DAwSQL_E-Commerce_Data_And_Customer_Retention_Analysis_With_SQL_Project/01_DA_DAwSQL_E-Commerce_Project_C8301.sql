-- First, I created a database named 'Project_M1_E_Commerce' for this project.

CREATE DATABASE Project_M1_E_Commerce;

-- I was given 3 csv files and 2 excell files for this project as tables.
-- I loaded the csv tables easily by using the left side menu. 
-- But, I could not succeed in loadin the excell files and couln not find a solution. Then I converted them to csv files and loaded them. 
-- After converting excell files to csv, I came across with column name problem. To solve this 

sp_help 'market_fact'
sp_help 'prod_dimen'

-- Rename the table shipping_dimen column Order_Id as Ord_id

EXEC sp_RENAME 'shipping_dimen.Order_Id' , 'Ord_id', 'COLUMN'

-- 

SELECT FORMAT(Order_Date,'yyyy-MM-dd')
FROM orders_dimen

SELECT FORMAT(Ship_Date,'yyyy-MM-dd') as 'Ship_Date'
FROM shipping_dimen;

SELECT CONVERT(Ship_Date,'yyyy-MM-dd') as 'Ship_Date'

--DAwSQL Session -8 

--E-Commerce Project Solution

--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)								YAPILDI

SELECT DISTINCT * FROM cust_dimen
SELECT DISTINCT * FROM orders_dimen
SELECT DISTINCT * FROM prod_dimen
SELECT DISTINCT * FROM shipping_dimen
SELECT DISTINCT * FROM market_fact



SELECT 	A.Ord_id, A.Prod_id, A.Ship_id, A.Cust_id, A.Product_Base_Margin, 
		FORMAT(B.Order_Date,'yyyy-MM-dd') AS Order_Date, B.Order_Priority,
		A.Order_Quantity, A.Sales, A.Discount
INTO combined_1
FROM market_fact A
FULL OUTER JOIN orders_dimen B
ON A.Ord_id = B.Ord_id;
	
SELECT * FROM combined_1;



SELECT 	A.Ord_id, A.Prod_id, A.Ship_id, A.Cust_id, A.Product_Base_Margin,
		B.Product_Category, B.Product_Sub_Category,
		A.Order_Date, A.Order_Priority,
		A.Order_Quantity, A.Sales, A.Discount
INTO combined_2
FROM combined_1 A
FULL OUTER JOIN prod_dimen B
ON A.Prod_id = B.Prod_id;

SELECT * FROM combined_2



SELECT 	A.*,
		B.Customer_Name, B.Province, B.Region, B.Customer_Segment
INTO combined_3
FROM combined_2 A
FULL OUTER JOIN cust_dimen B
ON A.Cust_id = B.Cust_id;

SELECT * FROM combined_3



SELECT 	A.*,
		B.Ship_Mode, FORMAT(B.Ship_Date,'yyyy-MM-dd') AS Ship_Date
INTO combined_table
FROM combined_3 A
FULL OUTER JOIN shipping_dimen B
ON A.Ship_id = B.Ship_id;

SELECT * FROM combined_table


	
--///////////////////////

--2. Find the top 3 customers who have the maximum count of orders.																										YAPILDI

SELECT TOP 3
			Cust_id, Customer_Name, COUNT(DISTINCT Ord_id) AS 'Count_of_Orders'
FROM		combined_table
GROUP BY	Cust_id, Customer_Name
ORDER BY	COUNT(Ord_id) DESC;



--/////////////////////////////////

--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.										YAPILDI
--Use "ALTER TABLE", "UPDATE" etc.

SELECT	DATEDIFF(DAY, Order_Date, Ship_Date) AS 'DaysTakenForDelivery'
FROM	combined_table;

ALTER TABLE		combined_table
ADD				DaysTakenForDelivery INT NULL;

UPDATE	combined_table
SET		DaysTakenForDelivery = DATEDIFF(DAY, Order_Date, Ship_Date)

SELECT * FROM combined_table



--////////////////////////////////////

--4. Find the customer whose order took the maximum time to get delivered.																								YAPILDI
--Use "MAX" or "TOP"

SELECT DISTINCT TOP 1 Ord_id, Cust_id, Customer_Name, Order_Date, Ship_Date, MAX(DaysTakenForDelivery) AS 'MAX_DaysTakenForDelivery'
FROM				combined_table
GROUP BY			Ord_id, Cust_id, Customer_Name, Order_Date, Ship_Date
ORDER BY			MAX(DaysTakenForDelivery) DESC;



--////////////////////////////////

--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011?								         YAPILDI
--You can use such date functions and subqueries

--1.YOL
SELECT		YEAR(Order_Date) AS 'Year', MONTH(Order_Date) AS 'Month', COUNT(DISTINCT Cust_id) AS 'Revisit_Following_Months'
FROM		combined_table
WHERE		YEAR(Order_Date) = 2011 
			AND Cust_id IN (
						SELECT DISTINCT	Cust_id
						FROM			combined_table
						WHERE			YEAR(Order_Date) = 2011
						AND				MONTH(Order_Date) = 1)
GROUP BY	YEAR(Order_Date), MONTH(Order_Date)

-- 2. YOL
WITH CUST_JAN AS
(
	SELECT DISTINCT Cust_id
	FROM			combined_table
	WHERE			MONTH(Order_Date)=01 AND YEAR(Order_Date) = 2011)

SELECT DISTINCT [MONTH],COUNT(AA.Cust_id) OVER(PARTITION BY[MONTH])
FROM(
	SELECT DISTINCT B.Cust_id,MONTH(B.Order_Date) AS [MONTH]
	FROM CUST_JAN A
	LEFT JOIN combined_table B
		ON A.Cust_id=B.Cust_id
		AND YEAR(B.Order_Date)='2011')AA


-- PIVOT TABLE
CREATE VIEW VIEW_5 AS
SELECT	Cust_id, Customer_Name, Ord_id, Order_Date, Year, Month
FROM
	(
	SELECT DISTINCT Cust_id, Customer_Name, Ord_id, Order_Date, YEAR(Order_Date) AS 'Year', MONTH(Order_Date) AS 'Month'
	FROM combined_table
	WHERE YEAR(Order_Date) = 2011 AND Cust_id IN (
					SELECT DISTINCT Cust_id
					FROM combined_table
					WHERE YEAR(Order_Date) = 2011
					AND MONTH(Order_Date) = 1)
	) A
;

SELECT * FROM VIEW_5

SELECT *
FROM (
		SELECT	Cust_id, Customer_Name, Year, Month, COUNT(Cust_id) AS 'Order_Monthly_2011' 
		FROM	VIEW_5
		GROUP BY Year, Month, Cust_id, Customer_Name
		) A
PIVOT
(
COUNT(Order_Monthly_2011)
FOR	Month
IN	(
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12]
		)
) AS PIVOT_TABLE


--////////////////////////////////////////////

--6. write a query to return for each user the time elapsed between the first purchasing and the third purchasing,														YAPILDI
--in ascending order by Customer ID
--Use "MIN" with Window Functions   -- BU SORUDA JULIANDAY KULANILIP KULLANILAMAYACAÐINA BAK

-- 1.YOL
SELECT DISTINCT
		cust_id,
		order_date,
		dense_number,
		FIRST_ORDER_DATE,
		DATEDIFF(day, FIRST_ORDER_DATE, order_date) DAYS_ELAPSED
FROM	
		(
		SELECT	Cust_id, ord_id, order_DATE,
				MIN (Order_Date) OVER (PARTITION BY cust_id) FIRST_ORDER_DATE,
				DENSE_RANK () OVER (PARTITION BY cust_id ORDER BY Order_date) dense_number
		FROM	combined_table
		) A
WHERE	dense_number = 3

-- 2. YOL
CREATE VIEW VIEW_6 AS
SELECT	Cust_id AS Cust_1, Cust_id AS Cust_3, Order_Date, Occurence
FROM
	(
		SELECT Cust_id, Order_Date, ROW_NUMBER () OVER (PARTITION BY Cust_id order by Order_Date) AS 'Occurence'            
		FROM combined_table
		GROUP BY Cust_id, Order_Date
	) A
;

SELECT * FROM VIEW_6

SELECT Cust_1, Order_Date AS Occ_1
INTO Time_Gap_13
FROM VIEW_6
WHERE Occurence = 1
GROUP BY Cust_1, Order_Date;

SELECT Cust_3, Order_Date AS Occ_3
INTO Time_Gap_31
FROM VIEW_6
WHERE Occurence = 3
GROUP BY Cust_3, Order_Date;

SELECT	Occ_1, Occ_3, coalesce(Cust_1, Cust_3) AS "Cust_id", 
		DATEDIFF(DAY, Occ_1, Occ_3) AS Time_Gap_13 
FROM Time_Gap_13 A
FULL JOIN Time_Gap_31 B
ON A.Cust_1 = B.Cust_3
WHERE DATEDIFF(DAY, Occ_1, Occ_3) IS NOT NULL
ORDER BY Cust_id ASC;

SELECT Cust_id, Order_Date FROM combined_table WHERE Cust_id = 'Cust_1000' ORDER BY Order_Date



--//////////////////////////////////////

--7. Write a query that returns customers who purchased both product 11 and product 14,																	         YAPILMADI HENÜZ                
--as well as the ratio of these products to the total number of products purchased by the customer.
--Use CASE Expression, CTE, CAST AND such Aggregate Functions

SELECT DISTINCT	Cust_id, Customer_Name, 
FROM			combined_table
WHERE			Cust_id IN (
							SELECT	Cust_id
							FROM	combined_table
							WHERE	Prod_id = 'Prod_11' OR Prod_id = 'Prod_14')


WITH T1 AS
(
SELECT	Cust_id,
		SUM (CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) P11,
		SUM (CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) P14,
		SUM (Order_Quantity) TOTAL_PROD
FROM	combined_table
GROUP BY Cust_id
HAVING
		SUM (CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) >= 1 AND
		SUM (CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) >= 1
)
SELECT	Cust_id, P11, P14, TOTAL_PROD,
		CAST (1.0*P11/TOTAL_PROD AS NUMERIC (3,2)) AS RATIO_P11,
		CAST (1.0*P14/TOTAL_PROD AS NUMERIC (3,2)) AS RATIO_P14
FROM T1



--/////////////////

--CUSTOMER RETENTION ANALYSIS

--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)									     YAPILDI
--Use such date functions. Don't forget to call up columns you might need later.

CREATE VIEW CUST_RET_ANA_VIEW_1 AS
SELECT	Cust_id, Customer_Name, Ord_id, Order_Date, Year, Month
FROM (
      SELECT DISTINCT Cust_id, Customer_Name, Ord_id, Order_Date, Year(Order_Date) AS 'Year', Month(Order_Date) AS 'Month' 
      FROM combined_table
	) A
;

SELECT * FROM CUST_RET_ANA_VIEW_1

-- OWEN HOCA
CREATE VIEW customer_logs AS
SELECT cust_id,
YEAR (ORDER_DATE) [YEAR],
MONTH (ORDER_DATE) [MONTH]
FROM combined_table





--//////////////////////////////////

--2. Create a view that keeps the number of monthly visits by users. (Separately for all months from the business beginning)									         YAPILDI
--Don't forget to call up columns you might need later.

CREATE VIEW CUST_RET_ANA_VIEW_2 AS
SELECT	Month, Monthly_Visits
FROM (
		SELECT		MONTH(Order_Date) AS 'Month', COUNT(DISTINCT Cust_id) AS 'Monthly_Visits'
		FROM		combined_table
		WHERE		Cust_id IN (
								SELECT DISTINCT Cust_id
								FROM combined_table
								)
GROUP BY	MONTH(Order_Date)
	) A
;

SELECT * FROM CUST_RET_ANA_VIEW_2

-- OWEN HOCA
CREATE VIEW NUMBER_OF_VISITS AS
SELECT	Cust_id, [YEAR], [MONTH], COUNT(*) NUM_OF_LOG
FROM	customer_logs
GROUP BY Cust_id, [YEAR], [MONTH]

SELECT  *,
		DENSE_RANK () OVER (PARTITION BY Cust_id ORDER BY [YEAR] , [MONTH])
		
FROM	NUMBER_OF_VISITS

SELECT  *,
		DENSE_RANK () OVER (PARTITION BY Cust_id ORDER BY [YEAR] , [MONTH])
		
FROM	NUMBER_OF_VISITS




--//////////////////////////////////

--3. For each visit of customers, create the next month of the visit as a separate column.																	             YAPILDI
--You can number the months with "DENSE_RANK" function.
--then create a new column for each month showing the next month using the numbering you have made. (use "LEAD" function.)
--Don't forget to call up columns you might need later.

SELECT *, LEAD(Month, 1) OVER(PARTITION BY Cust_id ORDER BY Order_Date) AS 'Next_Month_Visit'
FROM	(
		SELECT DISTINCT Cust_id, Customer_Name, Ord_id, Order_Date, Year(Order_Date) AS 'Year', MONTH(Order_Date) 'Month', DENSE_RANK() OVER (PARTITION BY Cust_id ORDER BY Order_Date) AS 'Dense_Rank'
		FROM combined_table
		) A

select * from combined_table where Cust_id = 'Cust_1'

SELECT *, LEAD(Month, 1) OVER(PARTITION BY Customer_Name ORDER BY Order_Date) AS 'Next_Month_Visit'
FROM	(
		SELECT DISTINCT Cust_id, Customer_Name, Ord_id, Order_Date, MONTH(Order_Date) 'Month', DENSE_RANK() OVER (PARTITION BY Customer_Name ORDER BY MONTH(Order_Date) ) AS 'Dense_Rank'
		FROM combined_table
		) A

select * from combined_table where Cust_id = 'Cust_1'

-- OWEN HOCA
CREATE VIEW NEXT_VISIT AS
SELECT *,
		LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY Cust_id ORDER BY CURRENT_MONTH) NEXT_VISIT_MONTH
FROM
(
SELECT  *,
		DENSE_RANK () OVER (ORDER BY [YEAR] , [MONTH]) CURRENT_MONTH
		
FROM	NUMBER_OF_VISITS
) A


--/////////////////////////////////

--4. Calculate the monthly time gap between two consecutive visits by each customer.																	-		YAPILMADI HENÜZ
--Don't forget to call up columns you might need later.

-- OWEN HOCA
CREATE VIEW time_gaps AS
SELECT *,
		NEXT_VISIT_MONTH - CURRENT_MONTH time_gaps
FROM	NEXT_VISIT



--/////////////////////////////////////////

--5.Categorise customers using time gaps. Choose the most fitted labeling model for you.
--  For example: 
--	Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
--	Labeled as regular if the customer has made a purchase every month.
--  Etc.

SELECT cust_id, avg_time_gap,
		CASE WHEN avg_time_gap = 1 THEN 'retained'
			WHEN avg_time_gap > 1 THEN 'irregular'
			WHEN avg_time_gap IS NULL THEN 'Churn'
			ELSE 'UNKNOWN DATA' END CUST_LABELS
FROM
		(
		SELECT Cust_id, AVG(time_gaps) avg_time_gap
		FROM	time_gaps
		GROUP BY Cust_id
		) A


--/////////////////////////////////////

--MONTH-WÝSE RETENTÝON RATE

--Find month-by-month customer retention rate  since the start of the business.

--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps

SELECT	DISTINCT cust_id, [YEAR],
		[MONTH],
		CURRENT_MONTH,
		NEXT_VISIT_MONTH,
		time_gaps,
		COUNT (cust_id)	OVER (PARTITION BY NEXT_VISIT_MONTH) RETENTITON_MONTH_WISE
FROM	time_gaps
where	time_gaps =1
ORDER BY cust_id, NEXT_VISIT_MONTH



--//////////////////////

--2. Calculate the month-wise retention rate.

--Basic formula: Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Next Nonth / Total Number of Customers in The Previous Month
--It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
--You can also use CTE or Subquery if you want.

--You should pay attention to the join type and join columns between your views or tables.

CREATE VIEW CURRENT_NUM_OF_CUST AS
SELECT	DISTINCT cust_id, [YEAR],
		[MONTH],
		CURRENT_MONTH,
		COUNT (cust_id)	OVER (PARTITION BY CURRENT_MONTH) RETENTITON_MONTH_WISE
FROM	time_gaps

SELECT *
FROM	CURRENT_NUM_OF_CUST
---
DROP VIEW NEXT_NUM_OF_CUST

CREATE VIEW NEXT_NUM_OF_CUST AS
SELECT	DISTINCT cust_id, [YEAR],
		[MONTH],
		CURRENT_MONTH,
		NEXT_VISIT_MONTH,
		COUNT (cust_id)	OVER (PARTITION BY NEXT_VISIT_MONTH) RETENTITON_MONTH_WISE
FROM	time_gaps
WHERE	time_gaps = 1
AND		CURRENT_MONTH > 1

SELECT DISTINCT
		B.[YEAR],
		B.[MONTH],
		B.CURRENT_MONTH,
		B.NEXT_VISIT_MONTH,
		1.0 * B.RETENTITON_MONTH_WISE / A.RETENTITON_MONTH_WISE RETENTION_RATE
FROM	CURRENT_NUM_OF_CUST A LEFT JOIN NEXT_NUM_OF_CUST B
ON		A.CURRENT_MONTH + 1 = B.NEXT_VISIT_MONTH



---///////////////////////////////////
--Good luck!