-- C. Challenge Payment Question -- 

WITH series AS (
                SELECT s.customer_id,
	               s.plan_id,
	               p.plan_name,
	               CAST(GENERATE_SERIES(s.start_date,
					    CASE
					        WHEN s.plan_id IN (0, 3, 4)
					        THEN s.start_date
					        WHEN s.plan_id IN (1, 2)
					             AND LEAD (s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) <> s.plan_id
					        THEN LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) - 1
					        ELSE '2020-12-31'
					    END,
					    '1 MONTH'
					    ) AS DATE) AS payment_date,
	                p.price
	         FROM   subscriptions AS s
	         JOIN   plans AS p
	         ON     s.plan_id = p.plan_id
	         WHERE  DATE_PART('YEAR', s.start_date) = 2020
                )
SELECT customer_id,
       plan_id,
       plan_name,
       payment_date,
       CASE 
           WHEN plan_id = 1
	   THEN price
	   WHEN plan_id IN (2, 3)
	        AND LAG (plan_id) OVER (PARTITION BY customer_id ORDER BY payment_date) <> plan_id
		AND payment_date - LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) < 30
	   THEN price - LAG(price) OVER (PARTITION BY customer_id ORDER BY payment_date)
	   ELSE price
       END AS amount,
       RANK () OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order
INTO   payments
FROM   series
WHERE  plan_id NOT IN (0, 4)


-- To view the same customers as in the example table:
SELECT * 
FROM   payments 
WHERE  customer_id IN (1,2,13,15,16,18,19)	 				
