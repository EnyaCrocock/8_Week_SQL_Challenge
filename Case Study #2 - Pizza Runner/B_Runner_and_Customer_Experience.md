# 🛵 B. Runners and Customer Experience 

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
- We can use `DATEDIFF` to find the difference 
 
```sql
SELECT r.runner_id,
       COUNT(DISTINCT r.pickup_time) AS total_pickups,
       AVG(DATEDIFF(MINUTE, c.order_time, r.pickup_time)) AS average_time_mins
FROM   ##customer_orders AS c
JOIN   ##runner_orders AS r
ON     c.order_id = r.order_id
GROUP  BY r.runner_id
```
