-- B. RUNNER AND CUSTOMER EXPERIENCE --

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SET DATEFIRST 1; -- Making sure Monday is set as the first day of the week 

SELECT DATEPART(WEEK, registration_date) AS week,
	   COUNT(runner_id) AS runners_signed_up
FROM   runners
GROUP  BY DATEPART(WEEK, registration_date)

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT r.runner_id,
       COUNT(DISTINCT r.pickup_time) AS total_pickups,
       CAST(AVG(CAST(DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS DECIMAL)) AS DECIMAL(4,2)) AS average_time_mins
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY r.runner_id

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_by_order AS (
                            SELECT c.order_id,
                                   COUNT(c.pizza_id) AS number_of_pizzas,
	                               CAST(DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS DECIMAL) AS prep_time
                            FROM   ##customer_orders AS c
                            JOIN   ##runner_orders AS r
                            ON     c.order_id = r.order_id
                            GROUP  BY c.order_id, c.order_time, r.pickup_time
                            )
SELECT number_of_pizzas,
        CAST(AVG(prep_time) AS DECIMAL (4,2)) AS average_total_prep_time,
	    CAST(AVG(prep_time) / number_of_pizzas AS DECIMAL (4,2)) AS average_prep_time_per_pizza
FROM   prep_time_by_order
GROUP  BY number_of_pizzas


-- 4. What was the average distance travelled for each customer?

SELECT c.customer_id,
       CAST(AVG(r.distance_km) AS DECIMAL (4,2)) AS average_distance_km
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY c.customer_id

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration_minutes) AS longest_delivery_time_mins,
       MIN(duration_minutes) AS shortest_delivery_time_mins,
	   MAX(duration_minutes) - MIN(duration_minutes) AS difference_mins
FROM   ##runner_orders

-- 6. What was the average speed for each runner for each delivery?

SELECT runner_id,
       order_id,
	   distance_km,
	   duration_minutes,
	   CAST(distance_km / duration_minutes * 60 AS DECIMAL(4,2)) AS speed_km_h
FROM   ##runner_orders 
WHERE  distance_km IS NOT NULL
ORDER  BY runner_id, order_id

-- Average speed by runner 

SELECT runner_id,
       COUNT(pickup_time) AS total_deliveries,
       CAST(MIN(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS min_speed_km_h,
	   CAST(MAX(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS max_speed_km_h,
	   CAST(AVG(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS average_speed_km_h
FROM   ##runner_orders 
WHERE  distance_km IS NOT NULL
GROUP  BY runner_id

-- 6.1. Do you notice any trend for these values?
--      Adding hour of the day and day of the week to the sql query to see if there is any trend visible

SELECT runner_id,
       order_id,
	   distance_km,
	   duration_minutes,
	   DATEPART(HOUR,pickup_time) AS pickup_hour,
	   DATENAME(WEEKDAY,pickup_time) AS pickup_weekday,
	   CAST(distance_km / duration_minutes * 60 AS DECIMAL(4,2)) AS speed_km_h
FROM   ##runner_orders 
WHERE  distance_km IS NOT NULL
ORDER  BY runner_id, order_id

-- 7. What is the successful delivery percentage for each runner?

SELECT runner_id,
	   COUNT(order_id) AS total_orders,
       COUNT(pickup_time) AS successful_deliveries,
	   CAST(COUNT(pickup_time) AS FLOAT) / CAST(COUNT(order_id) AS FLOAT) * 100 AS successful_delivery_percentage
FROM   ##runner_orders
GROUP  BY runner_id
