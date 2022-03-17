# 🛵 B. Runner and Customer Experience Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Questions

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SET DATEFIRST 1; -- To make sure Monday is set as the first day of the week

SELECT DATEPART(WEEK, registration_date) AS week,
       COUNT(runner_id) AS runners_signed_up
FROM   runners
GROUP  BY DATEPART(WEEK, registration_date)
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158663164-32f6107f-e2a2-4cb1-af62-7ef0c6eeb6e0.png)

#
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
- We can use `DATEDIFF` to find the difference between order_time and pickup_time in `MINUTES`, and then we can average it with the `AVG` function.
  - The CAST's were used to transform the numbers into decimals and to be able to round the numbers correctly. Doing it with ROUND wasn't working.  
 
```sql
SELECT r.runner_id,
       COUNT(DISTINCT r.pickup_time) AS total_pickups,
       CAST(AVG(CAST(DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS DECIMAL)) AS DECIMAL(4,2)) AS average_time_mins
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY r.runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158877089-fc65ba5e-de25-4cd8-aff8-ba02d8cc4c26.png)

- Runner 1's average is 16 mins with a total of 4 pickups
- Runner 2's average is 24 mins with a total of 3 pickups
- Whilst runner 3's average is 10 mins but has only done 1 pickup

#
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
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
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158878946-32d78818-0567-46f4-bcde-81085b805ddd.png)

- Here we can see that as the number of pizzas in an order goes up, so does the total prep time for that order, as you would expect.
- But then we can also notice that the average preparation time per pizza is higher when you order 1 than when you order multiple. 

#
### 4. What was the average distance travelled for each customer?

```sql
SELECT c.customer_id,
       CAST(AVG(r.distance_km) AS DECIMAL (4,2)) AS average_distance_km
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY c.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158879503-7b12d8fe-6909-4f4e-a31b-320cf347bb55.png)

#
### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration_minutes) AS longest_delivery_time_mins,
       MIN(duration_minutes) AS shortest_delivery_time_mins,
       MAX(duration_minutes) - MIN(duration_minutes) AS difference_mins
FROM   ##runner_orders
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158880153-643226c2-6c31-46ef-9ed7-17def74d20aa.png)

- The difference between the longest and shortest delivery was 30 mins. 

#
### 6. What was the average speed for each runner for each delivery?
- Let's see the `speed for each runner for each delivery`:

```sql
SELECT runner_id,
       order_id,
       distance_km,
       duration_minutes,
       CAST(distance_km / duration_minutes * 60 AS DECIMAL(4,2)) AS speed_km_h
FROM   ##runner_orders 
WHERE  distance_km IS NOT NULL
ORDER  BY runner_id, order_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158884570-5a70d20e-52b2-4cbc-b36c-09ca1198d825.png)

- Now let's see the `average speed for each runner in total`: 

```sql
SELECT runner_id,
       COUNT(pickup_time) AS total_deliveries,
       CAST(MIN(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS min_speed_km_h,
       CAST(MAX(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS max_speed_km_h,
       CAST(AVG(distance_km / duration_minutes * 60) AS DECIMAL (4,2)) AS average_speed_km_h
FROM   ##runner_orders 
WHERE  distance_km IS NOT NULL
GROUP  BY runner_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158885838-d8cda150-9a39-4a50-b647-71e80a1acaf6.png)

### 6.1. Do you notice any trend for these values?

- We can add the hour of the day and day of the week to the sql query to see if there is any trend visible:

```sql
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
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158887983-37f06b42-ff62-4f89-b4e4-fe17d790b162.png)

- It is a very small dataset but:
  - Runner 1 tends to go at their average speed of around 40km/h, and went a bit faster on a Saturday evening. 
  - Runner 2 tends to drive the fastest, and does so when the orders are at night. Their fastest speed was on a Friday at midnight (So Thursday to Friday), a weekday with probably no traffic and late at night so might have wanted to finish faster. 
  - Runner 3 has just had one delivery and drove at 40km/h.

