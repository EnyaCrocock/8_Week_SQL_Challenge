-- DATA CLEANING & TRANSFORMATION --

-- 1. Table: customer_orders 
--    Changing all the NULL and 'null' to blanks

SELECT order_id,
       customer_id,
	   pizza_id,
	   CASE 
	       WHEN exclusions LIKE '%null%' OR exclusions IS NULL
		   THEN '' 
		   ELSE exclusions
	   END AS exclusions,
	   CASE 
	       WHEN extras LIKE '%null%' OR extras IS NULL
		   THEN '' 
		   ELSE extras
	   END AS extras,
	   order_time
INTO   ##customer_orders
FROM   customer_orders

-- 2. Table: runner_orders
--    Changing all the NULL and 'null' to blanks for strings
--    Changing all the 'null' to NULL for non strings
--    Removing 'km' from distance
--    Removing anything after the numbers from duration

SELECT order_id,
       runner_id,
	   CASE 
	       WHEN pickup_time LIKE '%null%' 
		   THEN NULL
		   ELSE pickup_time
		   END AS pickup_time,
	   CASE
	       WHEN distance LIKE '%null%' 
		   THEN NULL
		   ELSE TRIM('%km%' FROM distance) 
	   END AS distance_km,
	   CASE 
	       WHEN duration LIKE '%null%' 
		   THEN NULL
		   ELSE LEFT(duration, 2)
	   END AS duration_minutes,
	   CASE 
	       WHEN cancellation IS NULL OR cancellation LIKE '%null%'
		   THEN ''
		   ELSE cancellation
	   END AS cancellation
INTO   ##runner_orders
FROM   runner_orders

-- 3. Changing data types 

ALTER TABLE ##runner_orders 
ALTER COLUMN pickup_time DATETIME;

ALTER TABLE  ##runner_orders
ALTER COLUMN distance_km FLOAT;

ALTER TABLE  ##runner_orders
ALTER COLUMN duration_minutes INT; 

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(50);

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(50);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name VARCHAR(50);

EXEC TempDB..SP_COLUMNS '##customer_orders'; -- check the data types for the temp table

-----------------------------------------------------------------------------------------------------------

-- FOR PART C. INGREDIENT OPTIMISATION -- 

-- 1. Table: pizza_recipes
--    Splitting comma delimited list into rows

SELECT pizza_id,
       TRIM(value) AS topping_id
INTO   ##pizza_recipes
FROM   pizza_recipes 
CROSS  APPLY STRING_SPLIT(toppings, ',')

-- 2. Table: ##customer_orders
--    Adding an Identity Column

ALTER TABLE  ##customer_orders
ADD          record_id INT IDENTITY (1,1) PRIMARY KEY

-- 3. New Tables: Exclusions & Extras
--    Splitting the exclusions & extras comma delimited lists into rows and storing in new tables

SELECT record_id,
       TRIM(value) AS exclusions_id
INTO   ##exclusions
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(exclusions, ',')

SELECT record_id,
       TRIM(value) AS extras_id
INTO   ##extras
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(extras , ',')
