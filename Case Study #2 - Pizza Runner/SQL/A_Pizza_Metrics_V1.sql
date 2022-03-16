-- A. PIZZA METRICS --

-- 1. How many pizzas were ordered?

SELECT COUNT(pizza_id) AS total_pizzas_ordered
FROM   ##customer_orders

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM   ##customer_orders

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id,
       COUNT(pickup_time) AS successful_orders
FROM   ##runner_orders
GROUP  BY runner_id

-- 4. How many of each type of pizza was delivered?

SELECT p.pizza_name,
       COUNT(r.pickup_time) AS total_delivered
FROM   ##customer_orders AS c
JOIN   pizza_names AS p
ON     c.pizza_id = p.pizza_id
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY p.pizza_name 

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?


SELECT c.customer_id,
       SUM(CASE 
	           WHEN p.pizza_name LIKE'%Meatlovers%' 
		       THEN 1
		       ELSE 0
	       END) AS meatlovers,
       SUM(CASE 
	           WHEN p.pizza_name LIKE'%Vegetarian%' 
		       THEN 1
		       ELSE 0
	       END) AS vegetarian
FROM   ##customer_orders AS c
JOIN   pizza_names AS p
ON     c.pizza_id = p.pizza_id
GROUP  BY c.customer_id

-- OR

SELECT c.customer_id,
	   p.pizza_name,
	   COUNT(p.pizza_name) AS total_orders
FROM   ##customer_orders AS c
JOIN   pizza_names AS p
ON     c.pizza_id = p.pizza_id
GROUP  BY c.customer_id, p.pizza_name
ORDER  BY c.customer_id

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT TOP 1
       c.order_id,
       COUNT(c.pizza_id) AS total_pizzas_delivered
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
WHERE  r.pickup_time IS NOT NULL
GROUP  BY c.order_id
ORDER  BY total_pizzas_delivered DESC

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT c.customer_id,
       SUM(CASE 
	           WHEN c.exclusions <> '' OR c.extras <> ''
			   THEN 1
			   ELSE 0
		    END) AS at_least_1_change,
	   SUM(CASE 
	           WHEN c.exclusions = '' AND c.extras = ''
			   THEN 1
			   ELSE 0
		    END) AS no_changes
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
WHERE  r.pickup_time IS NOT NULL
GROUP  BY customer_id

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(CASE 
	           WHEN c.exclusions <> '' AND c.extras <> ''
			   THEN 1
			   ELSE 0
		    END) AS exclusions_and_extras
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
WHERE  r.pickup_time IS NOT NULL

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(HOUR,order_time) AS hour,
       COUNT(pizza_id) AS pizzas_ordered
FROM   ##customer_orders
GROUP  BY DATEPART(HOUR,order_time) 
ORDER  BY pizzas_ordered DESC

-- 10. What was the volume of orders for each day of the week?

SELECT DATENAME(WEEKDAY,order_time) AS weekday,
	   COUNT(pizza_id) AS pizzas_ordered
FROM   ##customer_orders
GROUP  BY DATENAME(WEEKDAY,order_time)
ORDER  BY pizzas_ordered DESC