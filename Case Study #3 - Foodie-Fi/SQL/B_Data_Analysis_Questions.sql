-- B. Data Analysis Questions --

-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM   subscriptions

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT DATE_PART('MONTH', start_date) AS month,
       COUNT(customer_id) AS customer_count
FROM   subscriptions 
WHERE  plan_id = 0 
GROUP  BY DATE_PART('MONTH', start_date)
ORDER  BY customer_count DESC

-- 3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT p.plan_name,
       COUNT(s.customer_id) AS events
FROM   plans AS p
JOIN   subscriptions AS s
ON     p.plan_id = s.plan_id
WHERE  DATE_PART('YEAR',start_date) > 2020
GROUP  BY p.plan_name
ORDER  BY events DESC

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

WITH churned AS (
                 SELECT SUM(CASE
						        WHEN plan_id = 4 
						        THEN 1
						        ELSE 0
						    END) AS customers_churned,
	                    COUNT(DISTINCT customer_id) AS total_customers
	             FROM   subscriptions
	            )
SELECT customers_churned,
       ROUND(CAST(customers_churned AS DECIMAL) / CAST(total_customers AS DECIMAL) * 100, 1) AS percent_of_total
FROM   churned
	
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH churned AS ( 
                 SELECT customer_id,
	                    CASE
                            WHEN plan_id = 0 AND LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) = 4
	 					    THEN 1
	                        ELSE 0
	                    END AS churned_post_trial
	             FROM  subscriptions
	            )
SELECT SUM(churned_post_trial) AS count_churned_post_trial,
       ROUND(CAST(SUM(churned_post_trial) AS DECIMAL) / CAST(COUNT(DISTINCT customer_id) AS DECIMAL) * 100, 0) AS percent_of_total
FROM   churned
	               	 
-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH customer_plans AS ( 
                        SELECT customer_id,
							   plan_id,
							   CASE
                                   WHEN plan_id = 0 
                                   THEN LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date)
      							   ELSE NULL
							   END AS plan_post_trial
					    FROM   subscriptions
                       ),
   total_customers AS (
                       SELECT COUNT(DISTINCT customer_id) AS total_customers
                       FROM   subscriptions
   					  )
SELECT p.plan_name,
       COUNT(c.plan_post_trial) AS customers_post_trial,
	   ROUND(CAST(COUNT(c.plan_post_trial) AS DECIMAL) / CAST(t.total_customers AS DECIMAL) * 100, 2) AS percent_of_total 
FROM   total_customers AS t, 
       customer_plans AS c      
JOIN   plans AS p
ON     c.plan_post_trial = p.plan_id
GROUP  BY p.plan_name, t.total_customers
ORDER  BY customers_post_trial DESC


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
	 
WITH customer_plans AS ( 
                        SELECT customer_id,
	                           plan_id,
							   start_date,
							   RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rank
					    FROM   subscriptions
	 					WHERE  start_date <= '2020-12-31'
                       ),
   total_customers AS (
                       SELECT COUNT(DISTINCT customer_id) AS total_customers
                       FROM   subscriptions
	   				   WHERE  start_date <= '2020-12-31'
   					  )
SELECT p.plan_name,
	   COUNT(c.customer_id) AS customer_count,
	   ROUND(CAST(COUNT(c.customer_id) AS DECIMAL) / CAST(t.total_customers AS DECIMAL) * 100, 2) AS percent_of_total
FROM   total_customers AS t,
	   customer_plans AS c
JOIN   plans AS p
ON     c.plan_id = p.plan_id
WHERE  c.rank = 1
GROUP  BY p.plan_name, t.total_customers
ORDER  BY customer_count DESC

-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT p.plan_name,
       COUNT(s.customer_id) AS customer_count
FROM   plans AS p
JOIN   subscriptions AS s
ON     p.plan_id = s.plan_id
WHERE  DATE_PART('YEAR', start_date) = 2020
AND    s.plan_id = 3
GROUP  BY p.plan_name

-- 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

WITH join_date AS ( 
	               SELECT customer_id,
					      MIN(start_date) AS join_date
				   FROM   subscriptions
				   GROUP  BY customer_id
	              ),
  upgrade_date AS (
                   SELECT customer_id,
  					      start_date AS upgrade_date
  				   FROM   subscriptions
  				   WHERE  plan_id = 3
  				   GROUP  BY customer_id, start_date
  				  )
SELECT ROUND(AVG(CAST(upgrade_date - join_date AS DECIMAL)), 0) AS average_days
FROM   join_date AS j
JOIN   upgrade_date AS u
ON     j.customer_id = u.customer_id

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH join_date AS ( 
	               SELECT customer_id,
					      MIN(start_date) AS join_date
				   FROM   subscriptions
				   GROUP  BY customer_id
	              ),
  upgrade_date AS (
                   SELECT customer_id,
  					      start_date AS upgrade_date
  				   FROM   subscriptions
  				   WHERE  plan_id = 3
  				   GROUP  BY customer_id, start_date
  				  ),
      buckets AS ( 
		          SELECT WIDTH_BUCKET(upgrade_date - join_date, 0, 360, 12) AS bucket,
		  				 COUNT(u.customer_id) AS customer_count,
                         ROUND(AVG(CAST(u.upgrade_date - j.join_date AS DECIMAL)), 0) AS average_days
				  FROM   join_date AS j
			      JOIN   upgrade_date AS u
			      ON     j.customer_id = u.customer_id
				  GROUP  BY WIDTH_BUCKET(upgrade_date - join_date, 0, 360, 12)
				  ORDER BY bucket
		         )
SELECT CASE 
           WHEN bucket = 1 
		   THEN CONCAT((bucket - 1) * 30,' - ', bucket * 30, ' days') 
		   ELSE CONCAT((bucket - 1) * 30 + 1,' - ', bucket * 30, ' days')
	   END AS period,
	   customer_count,
       average_days
FROM   buckets
GROUP  BY bucket, customer_count, average_days
ORDER  BY bucket 

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH downgrade AS ( 
                   SELECT customer_id,
                   CASE 
                       WHEN plan_id = 2 AND LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) = 1
	                   THEN 1
		               ELSE 0
	               END AS downgraded_to_basic
                   FROM subscriptions
				   WHERE DATE_PART('YEAR', start_date) = 2020
				  )
SELECT SUM(downgraded_to_basic) AS customers_downgraded
FROM   downgrade


