# 🍕 Case Study #2 - Pizza Runner Cleaning

## Initial Cleaning:

### 1. Table: `customer_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/94410139/158224356-f289bf32-0cf2-460b-a25b-b27c82bf243d.png)

#### Changes:
- Changing all the NULL and 'null' to blanks
- Creating a clean temp table 

```sql
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
```
#### Cleaned table:
![image](https://user-images.githubusercontent.com/94410139/158224952-dbd73d3f-cde4-4c9a-b066-49907a03b270.png)

#
### 2. Table: `runner_orders`

#### Original Table:
![image](https://user-images.githubusercontent.com/94410139/158225138-f2682329-dc18-4197-ae90-661f87ab7177.png)

#### Changes:
- Changing all the NULL and 'null' to blanks for strings
- Changing all the 'null' to NULL for non strings
- Removing 'km' from distance
- Removing anything after the numbers from duration
- Creating a clean temp table 

```sql
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
```
#### Cleaned Table:
![image](https://user-images.githubusercontent.com/94410139/158225387-ae57ba10-8b79-4afc-ad47-6a3e952ef980.png)

# 
### 3. Changing data types

- For `runner_orders` changed:
  - pickup_time to DATETIME
  - distance_km to FLOAT
  - duration_minutes to INT

- For `customer_orders` changed:
  - order_date was changed to DATETIME when creating the original table
  
- For `pizza_names`, `pizza_recipes` and `pizza_toppings`:
  - The TEXT colums were changed to VARCHAR 
  
---

## For Part C. Ingredient Optimisation

### 1. Table: `pizza_recipes`

#### Original table:
![image](https://user-images.githubusercontent.com/94410139/158227609-4fd32726-4918-4368-918b-c81aa48045db.png)

#### Changes:
- Splitting comma delimited lists into rows
- Creating a clean temp table 

```sql
SELECT pizza_id,
       TRIM(value) AS topping_id
INTO   ##pizza_recipes
FROM   pizza_recipes 
CROSS  APPLY STRING_SPLIT(toppings, ',')
```
#### New table:
![image](https://user-images.githubusercontent.com/94410139/158244909-f46a437b-c658-4c2f-b92c-3ae3c4e0516f.png)

#
### 2. Table: `##customer_orders`

#### Original table: 
![image](https://user-images.githubusercontent.com/94410139/158224952-dbd73d3f-cde4-4c9a-b066-49907a03b270.png)

#### Changes:
- Adding an Identity Column 

```sql
ALTER TABLE  ##customer_orders
ADD          record_id INT IDENTITY (1,1)
```
![image](https://user-images.githubusercontent.com/94410139/158246338-0833d930-6d47-41e9-aadb-26f41c454b0a.png)

#
### 3. New Tables: `Exclusions` & `Extras` 

#### Original table:
![image](https://user-images.githubusercontent.com/94410139/158224356-f289bf32-0cf2-460b-a25b-b27c82bf243d.png)

#### Changes:
- Splitting the exclusions & extras comma delimited lists into rows and storing in new tables

```sql
SELECT record_id,
       TRIM(value) AS exclusions_id
INTO   ##exclusions
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(exclusions, ',')
```
![image](https://user-images.githubusercontent.com/94410139/158248028-26634028-b3c5-4925-b3cd-be622db5e02a.png)

```sql
SELECT record_id,
       TRIM(value) AS extras_id
INTO   ##extras
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(extras , ',')
```
![image](https://user-images.githubusercontent.com/94410139/158248089-507e71f1-e245-4c9a-84fe-6e9c413ff0ef.png)
