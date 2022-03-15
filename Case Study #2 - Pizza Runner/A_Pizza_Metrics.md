# 🍕 A. Pizza Metrics Solutions

## Questions

### 1. How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) AS total_pizzas_ordered
FROM   ##customer_orders
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158438673-cbd92248-0dac-4f8a-bb77-9caa2d9c4ead.png)

#
### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM   ##customer_orders
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158438937-bd5d7e19-a3d3-4289-8b58-1f5fc15df7ce.png)

#
### 3. How many successful orders were delivered by each runner?
- `Cancelled orders have pickup_time as NULL` so a COUNT of pickup_time will give us the number of successfull orders

```sql
SELECT runner_id,
       COUNT(pickup_time) AS successful_orders
FROM   ##runner_orders
GROUP  BY runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158439630-2cdeb98f-3db1-41a2-86cc-3f0edc884c5e.png)

#
### 4. How many of each type of pizza was delivered?
- Once again, delivered pizzas have a pickup_time 
- So we can `SELECT the pizza_names as well as the COUNT of pickup_time`

```sql
SELECT p.pizza_name,
       COUNT(r.pickup_time) AS total_delivered
FROM   ##customer_orders AS c
JOIN   pizza_names AS p
ON     c.pizza_id = p.pizza_id
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY p.pizza_name 
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158440585-f691cfc3-af8b-4cad-a58c-ed9350c274a2.png)

#
### 5. How many Vegetarian and Meatlovers were ordered by each customer?
- Here we can use the SUM function with a CASE statement

```sql
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
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158441828-e28acc28-9414-4a50-907d-7748fdfe4bee.png)

#
### 6. What was the maximum number of pizzas delivered in a single order?
- Here we want the max number of pizzas `delivered` in a single order
  - So we need a `WHERE` clause to filter only orders where `pickup_time IS NOT NULL` (order was not cancelled)
- Then we can use `SELECT TOP 1`, and `ORDER by the COUNT of pizza_id in DESCENDING order` (largest count first) to get the max count of pizzas delivered.

```sql
SELECT TOP 1
       c.order_id,
       COUNT(c.pizza_id) AS total_pizzas_delivered
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
WHERE  r.pickup_time IS NOT NULL
GROUP  BY c.order_id
ORDER  BY total_pizzas_delivered DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158443761-1c96d733-4619-4199-bd28-96501400c8d9.png)

#
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
- Again, we want delivered pizzas so we need the same WHERE clause as before
- To know if there are changes or not we look at the `exclusions and extras columns` 
  - If both fileds are BLANK ('') then there are no changes
  - If either are populated, so not BLANK ('') then there are changes
  
```sql
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
```
#### Results
![image](https://user-images.githubusercontent.com/94410139/158453312-db8e857c-5bb0-4836-b1a9-13fa1ddb7683.png)

#
### 8. How many pizzas were delivered that had both exclusions and extras?
- This is when `both fields` in the exclusions and extras columns `are populated`, so not BLANK ('')
- Again, we want delivered pizzas so we need the same WHERE clause as before

```sql
SELECT SUM(CASE 
               WHEN c.exclusions <> '' AND c.extras <> ''
               THEN 1
               ELSE 0
           END) AS exclusions_and_extras
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
WHERE  r.pickup_time IS NOT NULL
```
#### Results
![image](https://user-images.githubusercontent.com/94410139/158453808-1e87e231-c739-4ff2-92d6-b1feb51660d1.png)

#
### 9. What was the total volume of pizzas ordered for each hour of the day?
- Here we can use `DATEPART` to `extract the HOUR from order_date`
- Using `DATENAME`would give us the same result
  - The difference is DATEPART returns an intiger, while DATENAME returns a string
  
```sql
SELECT DATEPART(HOUR,order_time) AS hour,
       COUNT(pizza_id) AS pizzas_ordered
FROM   ##customer_orders
GROUP  BY DATEPART(HOUR,order_time) 
ORDER  BY pizzas_ordered DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158454775-c7af2906-f03d-4446-ac43-64e690e42a9b.png)

#
### 10. What was the volume of orders for each day of the week?
- Here we can use `DATENAME` to `extract the WEEKDAY with their actual names (Monday, Tuesday...)` instead of numbers (1, 2...) from order_time
  - Using `DATEPART` here would return the weekday as a number 
  
```sql
SELECT DATENAME(WEEKDAY,order_time) AS weekday,
       COUNT(pizza_id) AS pizzas_ordered
FROM   ##customer_orders
GROUP  BY DATENAME(WEEKDAY,order_time)
ORDER  BY pizzas_ordered DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158483691-1fdae52b-c293-41a6-a7ca-808c43de7ead.png)
