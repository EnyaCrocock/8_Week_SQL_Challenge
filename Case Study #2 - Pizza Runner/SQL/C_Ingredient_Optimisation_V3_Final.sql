-- C. INGREDIENT OPTIMISATION --

-- 1. What are the standard ingredients for each pizza?

SELECT n.pizza_name,
       STRING_AGG(t.topping_name, ', ') AS standard_ingredients
FROM   pizza_names AS n
JOIN   ##pizza_recipes AS r
ON     n.pizza_id = r.pizza_id
JOIN   pizza_toppings AS t
ON     r. topping_id = t.topping_id
GROUP  BY n.pizza_name

-- 2. What was the most commonly added extra?

SELECT TOP 1
       t.topping_name, 
	   COUNT(x.extras_id) AS times_added
FROM   pizza_toppings AS t
JOIN   ##extras AS x
ON     t.topping_id = x.extras_id
GROUP  BY t.topping_name 
ORDER  BY times_added DESC

-- 3. What was the most common exclusion?

SELECT TOP 1
       t.topping_name, 
	   COUNT(e.exclusions_id) AS times_removed
FROM   pizza_toppings AS t
JOIN   ##exclusions AS e
ON     t.topping_id = e.exclusions_id
GROUP  BY t.topping_name
ORDER  BY times_removed DESC

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH exclusions AS (
                    SELECT a.record_id,
				           STRING_AGG(t.topping_name, ', ') AS exclusions
				    FROM   ##exclusions AS a
				    JOIN   pizza_toppings AS t
				    ON     a.exclusions_id = t.topping_id
				    GROUP  BY a.record_id
				    ),
		 extras AS ( 
		            SELECT b.record_id,
				           STRING_AGG(t.topping_name, ', ') AS extras
				    FROM   ##extras AS b
				    JOIN   pizza_toppings AS t
				    ON     b.extras_id = t.topping_id
				    GROUP  BY b.record_id
					)
SELECT c.order_id,
       c.customer_id,
	   c.pizza_id,
	   c.exclusions,
	   c.extras,
	   c.order_time,
	   CASE 
	       WHEN c.exclusions = '' AND c.extras = '' 
		   THEN n.pizza_name
		   WHEN c.exclusions <> '' AND c.extras = ''
		   THEN CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions)
		   WHEN c.exclusions = '' AND c.extras <> ''
		   THEN CONCAT(n.pizza_name, ' - Extra', ' ', x.extras)
		   ELSE CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions, ' - Extra', ' ', x.extras) 
	   END AS order_item
FROM  ##customer_orders AS c 
LEFT  JOIN exclusions AS e
ON    c.record_id = e.record_id
LEFT  JOIN extras AS x
ON    c.record_id = x.record_id
LEFT  JOIN  pizza_names AS n
ON    c.pizza_id = n.pizza_id

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH ingredients AS (
                     SELECT c.record_id,
					        n.pizza_name,
					        t.topping_name,
							CASE
						        WHEN t.topping_id IN (
								                      SELECT extras_id 
								                      FROM   ##extras AS x 
													  WHERE  x.record_id = c.record_id
								                      ) 
								THEN '2x'
							    ELSE '' 
						    END AS extra
				     FROM   ##customer_orders AS c
				     JOIN   pizza_names AS n
				     ON     c.pizza_id = n.pizza_id
				     JOIN   ##pizza_recipes AS r
				     ON     n.pizza_id = r.pizza_id
				     JOIN   pizza_toppings AS t
				     ON     r.topping_id = t.topping_id
					 WHERE  t.topping_id NOT IN (
					                             SELECT exclusions_id
												 FROM   ##exclusions AS e
												 WHERE  e.record_id = c.record_id
												 )
					 GROUP  BY c.record_id, n.pizza_name, t.topping_name, t.topping_id
					 )
SELECT c.order_id,
       c.customer_id,
	   c.pizza_id,
	   c.exclusions,
	   c.extras,
	   c.order_time,
	   CONCAT(i.pizza_name, ': ', STRING_AGG(CONCAT(i.extra,i.topping_name),', ')) AS ingredient_list
FROM   ##customer_orders AS c 
JOIN   ingredients AS i
ON     c.record_id = i.record_id
GROUP  BY c.record_id, c.order_id, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, i.pizza_name

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


WITH ingredients AS (
                     SELECT c.record_id,
					        t.topping_name,
							CASE
						        WHEN t.topping_id IN (
								                      SELECT extras_id 
								                      FROM   ##extras AS x 
													  WHERE  x.record_id = c.record_id
								                      ) 
								THEN 2
								WHEN t.topping_id IN (
								                      SELECT exclusions_id 
								                      FROM   ##exclusions AS e 
													  WHERE  e.record_id = c.record_id
								                      )
								THEN 0
							    ELSE 1 
						    END AS times_used
				     FROM   ##customer_orders AS c
				     JOIN   pizza_names AS n
				     ON     c.pizza_id = n.pizza_id
				     JOIN   ##pizza_recipes AS r
				     ON     n.pizza_id = r.pizza_id
				     JOIN   pizza_toppings AS t
				     ON     r.topping_id = t.topping_id
					 GROUP  BY c.record_id, t.topping_name, t.topping_id
					 )
SELECT topping_name,
       SUM(times_used) AS times_used 
FROM   ingredients
GROUP  BY topping_name
ORDER  BY times_used DESC
