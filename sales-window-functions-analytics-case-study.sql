/*
   ------------------------------
    SQL WINDOW FUNCTIONS ANALYTICS CASE STUDY – POSTGRESQL & MYSQL
   ------------------------------
  Author        : Sudais Shah
  Description   : This case study explores the power of SQL window functions 
                  in generating advanced analytics from a simulated sales database.
                  It covers ranking, running totals, moving averages, partitions, 
                  percentiles, and more.

  Objective     : Demonstrate real-world business use cases using SQL window 
                  functions for performance trends, customer behavior, and 
                  sales segmentation analysis.

  Notes         : All queries are documented with inline comments for clarity.
                  Compatible with both PostgreSQL and MySQL window functions.
 */
--^^^^^^^^^^^^^^^^^^^^^^^^^ Windows Functions **************************************

-- Window Functions Mastery Questions
--Basic Usage
--                                          Ranking:    
-- Q1 - Rank all customers by the total amount of their orders highest to lowest using RANK() and DENSE_RANK().

SELECT customer_id , sum(amount) ,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS ranking ,
       DENSE_RANK() OVER (ORDER BY SUM(amount) DESC)  AS dense_ranking
FROM orders 
GROUP BY customer_id
ORDER BY ranking ASC;

--                                  Row Number:
---- Q2 - Assign a row number to each order for every customer (use ROW_NUMBER()).
SELECT 
    customer_id,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS row_Num
FROM orders
ORDER BY customer_id ASC;


--                                      Cumulative Total:
-- Q3 - Calculate the running total (SUM()) of the order amount for each customer, ordered by order_date.
SELECT customer_id, order_date, amount,
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM Orders
ORDER BY customer_id, order_date;

--                                      Moving Averages:
--Q4 - Calculate the 3 day moving average of the order amount for each customer based on order_date.
SELECT  customer_id , order_date , amount , 
        ROUND(AVG(amount) OVER (PARTITION BY customer_id ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS moving_avg
FROM orders 
ORDER BY customer_id , order_date ASC;

--                                       Percentile:
--Q5 - Use NTILE(4) to divide customers into quartiles based on their total order amounts.
SELECT customer_id, SUM(amount) AS total_order_amount,
        NTILE(4) OVER (ORDER BY SUM(amount) DESC) AS quartile
FROM Orders
GROUP BY customer_id
ORDER BY quartile, total_order_amount DESC;

--                                    Advanced Aggregations
--                                    Difference from Maximum:
--Q6 - Find the difference between each order’s amount and the maximum order amount for that customer.
SELECT customer_id, order_id, amount,
       MAX(amount) OVER (PARTITION BY customer_id) AS max_amount_per_customer,
       MAX(amount) OVER (PARTITION BY customer_id) - amount AS amount_difference
FROM Orders;

--                                     Order Gap Analysis:
--Q7 - Calculate the gap (in days) between consecutive orders for each customer using LAG().
SELECT order_id , customer_id , order_date , 
       order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as day_gap1 ,
       age(order_date ,LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC)) as day_gap -- both are good
FROM orders;

--                                  Cumulative Count:
--Q8 - Count the number of orders placed by each customer up to each order date.
SELECT order_id , customer_id , order_date  ,
       COUNT( order_id) OVER (PARTITION BY customer_id ORDER BY order_date) as total_orders
FROM orders;

--                                  Rank by Partition:
--Q9 - Rank orders within each month for every customer using PARTITION BY.
SELECT order_id , customer_id , order_date  ,
       Dense_Rank() OVER (PARTITION  by customer_id,DATE_TRUNC('month', order_date) order by order_date)
as ORDER_RANK
FROM orders;

--                                 Window-Specific Average:
--Q10 - Calculate the average order amount over the last 5 orders for each customer.
SELECT order_id , customer_id , order_date  , amount,
       AVG(amount) OVER (PARTITION BY customer_id ORDER BY order_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW ) as last_5_order_avg,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date  ) as row_no
FROM orders 
ORDER BY customer_id, order_date;

--                                                Comparisons
--                                                Lead vs. Lag:
-- Q11 - Compare each order amount with the previous and next order to analyze spending trends. 
SELECT customer_id , order_id , order_date , amount AS current_order_amount ,
       LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS previous_order_amount ,
	   LEAD(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_amount
FROM orders ;

--                                               First and Last:
--Q12 - Retrieve the first and last order amount for each customer using FIRST_VALUE() and LAST_VALUE().
SELECT customer_id, order_id, order_date, amount AS current_order_amount,
    FIRST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_value_amount,
    LAST_VALUE(amount) OVER (PARTITION BY customer_id ) AS last_value_amount
FROM Orders;

--                                               Percentage Change:
--Q13 - Calculate the percentage change in the order amount compared to the previous order for each customer.
SELECT customer_id, order_id, order_date, amount AS current_order_amount,
       LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_value ,
	   CASE 
	        WHEN LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) = 0 THEN NULL
	  ELSE (
	        ROUND((amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date)) * 100 /
	        LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date, 2 ))
			)
	END AS Percentage_changes 
FROM Orders;

--                                              Practical Scenarios
--                                              Highest Order per Customer:
--Q14 - Identify the highest order amount for each customer but include all their orders.
SELECT  customer_id, order_id, order_date, amount AS current_order_amount,
        Max(amount) OVER (PARTITION BY customer_id ) AS  highest_order_amount
FROM Orders;

--                                              Cumulative Revenue:
--Q15 - Calculate the cumulative revenue generated by all customers over time.

SELECT  customer_id, order_id, order_date, amount AS current_order_amount,
        sum(amount) OVER (PARTITION BY customer_id order by order_date) AS  highest_order_amount
FROM Orders;

--                                               Sales Growth:
--Q16 - Compute the monthly growth in total order amount for the entire business.
WITH MonthlyTotals AS (
    SELECT DATE_TRUNC('month', order_date) AS month,SUM(amount) AS total_amount
    FROM Orders
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY month
)
SELECT  month, total_amount, 
        LAG(total_amount) OVER (ORDER BY month) AS previous_month_amount,
    CASE 
        WHEN LAG(total_amount) OVER (ORDER BY month) IS NULL THEN NULL
        ELSE ROUND(((total_amount - LAG(total_amount) OVER (ORDER BY month)) 
                    * 100.0 / LAG(total_amount) OVER (ORDER BY month)), 2)
    END AS monthly_growth_percentage
FROM MonthlyTotals;

--                                            Customer Segmentation:
--Q17 - Group customers into deciles based on their total spending using NTILE(10).

SELECT customer_id , SUM(amount) , 
       NTILE(10) OVER (ORDER BY SUM(amount) DESC ) customer_rank_by_total_spending
FROM orders
GROUP BY customer_id
------
WITH CustomerTotals AS (
    SELECT customer_id, SUM(amount) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT  customer_id, total_spending,
        NTILE(10) OVER (ORDER BY total_spending DESC) AS customer_rank_by_total_spending
FROM CustomerTotals;

--                                         Daily Peak Orders:
--Q18 -  For each day, find the time of the peak order amount using RANK().
with cte as(
     SELECT  order_date , order_time , amount ,
     RANK() over (PARTITION BY date_trunc('day',order_date ) order by amount DESC) as ranke
     FROM orders)
Select order_date , order_time , amount   as max_amount from cte
where ranke = 1;

-- both are correct and have same result 

WITH ranked_orders AS (
    SELECT  order_date::date AS order_day,  -- Extract the date part of the order_date
           order_id, order_date,  -- Full timestamp for the order
        amount,
        RANK() OVER (PARTITION BY order_date::date ORDER BY amount DESC) AS rank
    FROM orders 
)
SELECT  order_day, order_date AS peak_time, amount AS peak_order_amount
FROM ranked_orders
WHERE rank = 1;  -- Select only the top-ranked order for each day


--                                                  Edge Cases
--                                              Empty Partitions:
--Q19 - How does a window function behave when there are no rows in a partition? Test it by querying customers with no orders.
SELECT LAG(amount) OVER (PARTITION by customer_id) AS previous_amount
FROM orders
WHERE order_id IS NULL ;

--                                            Complex Partitioning:
--Q20 - Partition the data by order_date and customer_id to calculate the rank of orders based on the amount.
SELECT customer_id , order_date , amount , 
       RANK() OVER (PARTITION BY customer_id,order_date ORDER BY amount DESC) AS order_rank
FROM orders 

SELECT customer_id, order_date, COUNT(*) AS order_count
FROM orders
GROUP BY customer_id, order_date
HAVING COUNT(*) > 1;

--                                             Window Frame Specification:
-- Q21 - Use ROWS BETWEEN or RANGE BETWEEN to calculate a running average of order amounts within a specific date range.
SELECT customer_id, order_date , amount ,
       AVG(amount) OVER (PARTITION BY customer_id ORDER BY order_date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS LAST_7_ORDER
FROM orders;

--                                             Multi-Column Partitioning:
--Q22 - Partition by customer_id and order_date, and rank orders by amount.
SELECT customer_id, order_date , amount ,
       RANK() OVER (PARTITION BY customer_id,order_date ORDER BY amount DESC ) AS rank_by_amount
FROM orders;

--                                              Extra Challenges
--                                              Find Outliers:
--Q23 - Identify orders where the amount is significantly higher or lower than the average for that customer (use STDDEV() or VARIANCE()).

WITH customer_stats AS (
    SELECT  customer_id, order_date, amount,
            AVG(amount) OVER (PARTITION BY customer_id) AS avg_of_customer,
            STDDEV(amount) OVER (PARTITION BY customer_id) AS stddev_of_customer
    FROM orders
)
SELECT customer_id, order_date, amount, avg_of_customer, stddev_of_customer
FROM customer_stats
WHERE 
    amount >= avg_of_customer + 2 * stddev_of_customer
    OR 
    amount <= avg_of_customer - 2 * stddev_of_customer
ORDER BY customer_id, order_date

----  stable 
WITH customer_stats AS (
    SELECT customer_id,AVG(amount) AS avg_amount,STDDEV(amount) AS stddev_amount
    FROM orders
    GROUP BY customer_id )
	
SELECT  o.customer_id, o.order_id, o.order_date, o.amount AS order_amount, cs.avg_amount, cs.stddev_amount,
       CASE 
        WHEN o.amount BETWEEN cs.avg_amount - cs.stddev_amount AND cs.avg_amount + cs.stddev_amount 
        THEN 'Stable'
        WHEN o.amount < cs.avg_amount - cs.stddev_amount 
        THEN 'Low Variability'
        WHEN o.amount > cs.avg_amount + cs.stddev_amount 
        THEN 'High Variability'
    END AS variability
FROM orders o
JOIN customer_stats cs 
    ON o.customer_id = cs.customer_id;

--                                          Churn Prediction:
-- Q24 - Calculate the number of days since the last order for each customer and flag customers who haven’t ordered in the past 90 days.
-- Solution 1
with cte As (
       SELECT order_id , customer_id , order_date ,
              lag(order_date) over (Partition by customer_id order by order_date Desc) as last_order
              FROM orders )
Select order_id , customer_id , order_date , last_order , last_order - order_date  as days_gap
FROM cte 
WHERE last_order - order_date >= 90

-- Solution 2 

WITH cte AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS last_order
    FROM orders
)
SELECT 
    order_id,
    customer_id,
    order_date,
    last_order,
    COALESCE(order_date - last_order, 0) AS days_gap
FROM cte
WHERE COALESCE(order_date - last_order, 0) >= 90
ORDER BY customer_id, order_date;


--                                                   Top N Analysis:
--Q25 - Find the top 3 orders for each customer in terms of amount.
WITH cte AS (
SELECT  order_id, customer_id, order_date, amount ,
	    Rank() OVER (PARTITION BY customer_id ORDER BY amount DESC) as rank_of_orders
FROM orders 
)
Select  order_id, customer_id, order_date, amount , rank_of_orders
FROM cte
WHERE rank_of_orders IN(1,2,3);

--                                                Performance Benchmarking:
--Q26 - Measure the time difference between the first and last order for each customer using window functions.
-- Solution 1 
SELECT customer_id,
       MIN(order_date) OVER (PARTITION BY customer_id) AS first_order_date,
       MAX(order_date) OVER (PARTITION BY customer_id) AS last_order_date,
       MAX(order_date) OVER (PARTITION BY customer_id) - MIN(order_date) OVER (PARTITION BY customer_id) AS time_difference
FROM orders
GROUP BY customer_id , order_date;

-- Solution 2
WITH ranked_orders AS (
    SELECT customer_id,order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS order_rank_asc,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS order_rank_desc
    FROM orders
),
first_last_orders AS (
    SELECT customer_id,
        MAX(CASE WHEN order_rank_asc = 1 THEN order_date END) AS first_order_date,
        MAX(CASE WHEN order_rank_desc = 1 THEN order_date END) AS last_order_date
    FROM ranked_orders
    GROUP BY customer_id
)
SELECT  customer_id, first_order_date, last_order_date, last_order_date - first_order_date AS time_difference
FROM first_last_orders;

-- Solution 3 

SELECT 
    customer_id,
    FIRST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS first_order_date,
    LAST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_order_date
FROM orders
GROUP BY customer_id,order_date;

-------------*****************Key Window Functions COVERED:
Ranking Functions: ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE().
Aggregate Functions: SUM(), AVG(), COUNT(), MAX(), MIN().
Navigation Functions: LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE().
Statistical Functions: STDDEV(), VARIANCE().

/*
  ------------------------------------------------------------
  END OF WINDOW FUNCTIONS ANALYTICS CASE STUDY
  ------------------------------------------------------------

  Summary:
  This file demonstrated various window function techniques for solving
  complex analytical problems using SQL. The case study includes examples of:
    - ROW_NUMBER(), RANK(), DENSE_RANK()
    - NTILE(), LEAD(), LAG()
    - SUM(), AVG() OVER PARTITION
    - FIRST_VALUE(), LAST_VALUE()
    - And more...

  Thank you for reviewing this project!
  For more case studies and projects, visit my GitHub:
  [Add GitHub Repo Link Here]

  Author: Sudais Shah
*/









	