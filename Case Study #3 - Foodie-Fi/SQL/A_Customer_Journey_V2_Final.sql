-- A. Customer Journey -- 

SELECT s.customer_id,
	   p.plan_name,
	   s.start_date,
	   start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS days_difference,
	   ROUND((start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date)) * 0.0329, 0) AS months_difference
FROM   subscriptions AS s
JOIN   plans AS p
ON     s.plan_id = p.plan_id
WHERE  s.customer_id IN (1,2,11,13,15,16,18,19)

-- Customer 1 signed up for a free trial on the 1st of August 2020 and decided to subscribe to the basic monthly plan right after it ended. 
-- Customer 2 signed up for a free trial on the 20th of September 2020 and decided to upgrade to the pro annual plan right after it ended.
-- Customer 11 signed up for a free trial on the 19th of November 2020 and decided to cancel their subscription on the billing date. 
-- Customer 13 signed up for a free trial on the 15th of December 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro monthly plan three months later. 
-- Customer 15 signed up for a free trial on the 17th of March 2020 and then decided to upgrade to the pro monthly plan right after it ended for one month before cancelling it. 
-- Customer 16 signed up for a free trial on the 31st of May 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro annual plan four months later.
-- Customer 18 signed up for a free trial on the 6th of July 2020 and then went on to pay for the pro monthly plan right after it ended. 
-- Customer 19 signed up for a free trial on the 22nd of June 2020, went on to pay for the pro monthly plan right after it ended and upgraded to the pro annual plan two months in.  

