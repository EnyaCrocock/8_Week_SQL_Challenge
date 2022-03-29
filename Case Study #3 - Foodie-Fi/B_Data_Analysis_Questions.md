# 🥑 A. Data Anlysis Questions Solutions

<p align="right"> Using PostgreSQL </p>

#
## Questions


### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM   subscriptions
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160466778-c7c4ce2d-8879-4d9f-a9b8-cb7db9d92c2a.png)

#
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

#### SQL Query 
- We want to know how many people have subscribed for a free trial each month.
- One way to do this is to use `DATE_PART()` to extract the `MONTH` from the start_date and then do a `COUNT` of `customer_id`.
- We need to use a `WHERE` clause because we only want records where the `plan_id is 0` (free trial).

```sql
SELECT DATE_PART('MONTH', start_date) AS month,
       COUNT(customer_id) AS customer_count
FROM   subscriptions 
WHERE  plan_id = 0 
GROUP  BY DATE_PART('MONTH', start_date)
ORDER  BY customer_count DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160467746-591e63aa-e1fe-447c-9814-35f25bf99b64.png)

- March had the most free trial subscriptions with 94.
- February had the least with 68.

#
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

#### SQL Query
- We want to know the events (number of subscriptions) for each plan after 2020.
- In the WHERE clause we will use `DATE_PART()` to specify we want the `YEAR` of star_date to be `after 2020`.

```sql
SELECT p.plan_name,
       COUNT(s.customer_id) AS events
FROM   plans AS p
JOIN   subscriptions AS s
ON     p.plan_id = s.plan_id
WHERE  DATE_PART('YEAR',start_date) > 2020
GROUP  BY p.plan_name
ORDER  BY events DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160468744-b3fe8695-9919-4dee-8cff-48aac581a84b.png)

- After 2020 (So, in 2021) there were 71 plan churns (cancellations)
- 63 upgrades to pro annual plans
- 60 upgrades to pro monthly plans
- 8 subscriptions to the basic monthly plan
- And no subscriptions to free trials 

#
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

#### SQL Query
- One way to achieve this is to create a `CTE`:
  - In this CTE we are going to build a CASE Statement with a SUM function to SUM every record that has the plan_id = 4 (churn), so we can know the total number of churned customers.
  - We are also going to do a COUNT of DISTINCT customer_id to get the total number of customers.
- In the `final SELECT Statement`:
  - SELECT the customers_churned from the CTE`.
  - Calculate the percentage of customers churned, and ROUND to 1 decimal place.


```sql
WITH churned AS (
                 SELECT SUM(CASE
                                WHEN plan_id = 4 
                                THEN 1
                                ELSE 0
                            END) AS customers_churned,
                        COUNT(DISTINCT customer_id) AS total_customers
                 FROM   subscriptions
                )
SELECT customers_churned,
       ROUND(CAST(customers_churned AS DECIMAL) / CAST(total_customers AS DECIMAL) * 100, 1) AS percent_of_total
FROM   churned
```

#### Result
![image](https://user-images.githubusercontent.com/94410139/160470873-ef9840c9-2054-4b4b-9684-2b1eb61a5134.png)

#
### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

#### SQL Query
- We want to know how many people churned (cancelled their subscription) straight after their free trial.
  - One way to do this is by first, creating a `CTE`:
     - In this CTE we are going to SELECT the customer_id (to use later in the calculation) and build a CASE Statement.
	   - The CASE Statement:
	     - Here we want to find out who went from having a free trial directly to a churn. Customers that passed from plan_id 0 directly to plan_id 4.
		   - For this we can use the `LEAD()` Window Function. 
		     > `LEAD()` allows you to compare the current row to the following row (or row below).  
		  - CASE WHEN the plan_id in the current row = 0 (free trial) and the next row has a plan_id of 4 (churn) 
		  - THEN return 1
		  - ELSE 0
- In the `final SELECT Statement`:
   - We are goin to SUM all the 1's from the CASE Satement to get a count of the customers that churned directly after the free trial.
   - And we are going to devide them by the total customers to get the percentage. 

```sql
WITH churned AS ( 
                 SELECT customer_id,
	                    CASE
                          WHEN plan_id = 0 
                               AND LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) = 4
                          THEN 1
                          ELSE 0
                      END AS churned_post_trial
                 FROM  subscriptions
                )
SELECT SUM(churned_post_trial) AS count_churned_post_trial,
       ROUND(CAST(SUM(churned_post_trial) AS DECIMAL) / CAST(COUNT(DISTINCT customer_id) AS DECIMAL) * 100, 0) AS percent_of_total
FROM   churned
```
#### Result 
![image](https://user-images.githubusercontent.com/94410139/160481155-1ad991a5-e5b4-4235-b483-2dbf7962a757.png)

#
### 6. What is the number and percentage of customer plans after their initial free trial?

#### SQL Query
- In this questions we are asked to find out what customers subscribed to after their free trial.
- For each plan_name we want to know: the number of customers that subscribed to it after the free trial and the percentage of the total.
- Let's start by creating a `CTE`:
  - In this CTE we want to build a CASE Statement to tell us what plan each customer subscribed to after the free trial.
	  - CASE WHEN the plan_id = 0 (a free trial) 
		- THEN return the plan_id for the following plan the customer subscribed to
		- ELSE return NULL
  - `Second CTE`:
    - Here we are going to SELECT a COUNT of DISTINCT customer_id to have the total number of customers.
- In the `final SELECT Statement`:
  - We want to SELECT the plan_name (as we want to GROUP BY it).
  - A COUNT of the number of times each plan appeared in the column we created with the CASE Statement.
  - That same COUNT over the total customers from the second CTE, to get the percent of the total.

```sql
WITH customer_plans AS ( 
                        SELECT customer_id,
                               plan_id,
                               CASE
                                   WHEN plan_id = 0 
                                   THEN LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date)
                                   ELSE NULL
                               END AS plan_post_trial
                        FROM   subscriptions
                       ),
   total_customers AS (
                       SELECT COUNT(DISTINCT customer_id) AS total_customers
                       FROM   subscriptions
                      )
SELECT p.plan_name,
       COUNT(c.plan_post_trial) AS customers_post_trial,
       ROUND(CAST(COUNT(c.plan_post_trial) AS DECIMAL) / CAST(t.total_customers AS DECIMAL) * 100, 2) AS percent_of_total 
FROM   total_customers AS t, 
       customer_plans AS c      
JOIN   plans AS p
ON     c.plan_post_trial = p.plan_id
GROUP  BY p.plan_name, t.total_customers
ORDER  BY customers_post_trial DESC
```
#### Fragment of customer_plans CTE output
![image](https://user-images.githubusercontent.com/94410139/160483001-0dcf0665-3efb-4801-9450-671e15f6e32f.png)

#### Final Result
![image](https://user-images.githubusercontent.com/94410139/160483254-288cbe3e-ac7b-4c40-b013-7c773a049baa.png)

#
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

#### SQL Query
- We want to know how many customers were subscribed to each plan on 2020-12-31, and that as a percent of the total. 
- Firstly we need to know what plan each customer was subscribed to on 2020-12-31.
 - Lets create a `CTE`:
   - In it we need to RANK() each clients plans by the start_date in DESCENDING order, as we want the last plan they have subscribed to to rank first. 
   - We also need a WHERE clause to filter only plans started on '2020-12-31' or before.
- `Second CTE`:
   - Here we are going to SELECT a COUNT of DISTINCT customer_id to have the total number of customers.
   - We need a WHERE clause to filter only customers subscribed on the '2020-12-31' or before. 
- In the `final SELECT Statement`:
  - We want to SELECT the plan_name (as we want to GROUP BY it).
  - A COUNT of the customers.  
  - That same COUNT over the total customers from the second CTE, to get the percent of the total.
  - A WHERE clause to filter only plans with the rank = 1 (the lastest plan). 

```sql
WITH customer_plans AS ( 
                        SELECT customer_id,
                               plan_id,
                               start_date,
                               RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rank
                        FROM   subscriptions
                        WHERE  start_date <= '2020-12-31'
                       ),
   total_customers AS (
                       SELECT COUNT(DISTINCT customer_id) AS total_customers
                       FROM   subscriptions
                       WHERE  start_date <= '2020-12-31'
                      )
SELECT p.plan_name,
       COUNT(c.customer_id) AS customer_count,
       ROUND(CAST(COUNT(c.customer_id) AS DECIMAL) / CAST(t.total_customers AS DECIMAL) * 100, 2) AS percent_of_total
FROM   total_customers AS t,
       customer_plans AS c
JOIN   plans AS p
ON     c.plan_id = p.plan_id
WHERE  c.rank = 1
GROUP  BY p.plan_name, t.total_customers
ORDER  BY customer_count DESC
```
#### Fragment of customer_plans CTE output
![image](https://user-images.githubusercontent.com/94410139/160486041-37f7b04c-4f7c-4f0d-867f-930b4af605f0.png)

#### Final Result
![image](https://user-images.githubusercontent.com/94410139/160486300-a61d2a66-73c0-4897-9aa0-2020cbbc774a.png)

#
### 8. How many customers have upgraded to an annual plan in 2020?

#### SQL Query 
- We want a COUNT of customers that have a annual_plan in 2020: 
- WHERE DATE_PART('YEAR', start_date) = 2020 
- AND the plan_id = 3

```sql
SELECT p.plan_name,
       COUNT(s.customer_id) AS customer_count
FROM   plans AS p
JOIN   subscriptions AS s
ON     p.plan_id = s.plan_id
WHERE  DATE_PART('YEAR', start_date) = 2020
AND    s.plan_id = 3
GROUP  BY p.plan_name
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160487017-0acdb645-addb-488c-a32d-58c3501f97fb.png)

#
### 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

#### SQL Query
- We need to find everyones join_date as well as the date that each customer upgraded to the annual plan. 
- We can create `2 CTEs`:
  - join_date CTE:
    - The MIN(start_date) will be their join_date.
  - upgrade_date CTE:
    - The upgrade_date will be the start_date WHERE plan_id = 3 
- `Final Select Statement`:
  - We need the AVERAGE of the differences between the upgrade_date and the join_date. 


```sql
WITH join_date AS ( 
                   SELECT customer_id,
                          MIN(start_date) AS join_date
                   FROM   subscriptions
                   GROUP  BY customer_id
                  ),
  upgrade_date AS (
                   SELECT customer_id,
                          start_date AS upgrade_date
                   FROM   subscriptions
                   WHERE  plan_id = 3
                   GROUP  BY customer_id, start_date
                  )
SELECT ROUND(AVG(CAST(upgrade_date - join_date AS DECIMAL)), 0) AS average_days
FROM   join_date AS j
JOIN   upgrade_date AS u
ON     j.customer_id = u.customer_id
```

#### Result
![image](https://user-images.githubusercontent.com/94410139/160488410-f1be912b-4138-4884-96ef-1889e6c328bd.png)

#
#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

#### SQL Query
- For this question we still want to find the same average as above but we want to break it down into periods. 
  - So we still need the same `join_date and upgrade_date CTEs` and we need to `create a new CTE for the buckets (30 day periods)`. 
  - `buckets CTE`:
    - To create the buckets we can use the WIDTH_BUCKET() Function 
      > This function allows you to divide a range of numbers into equal sized buckets. 
    - We want to divide the list of averages (upgrade_date - join_date) into 30 day periods, so 12 equal sized buckets ranging from 0 to 360. 
    - We also want to know how many customers fall into each bucket, so, COUNT of customer_id. 
    - And we can also find out the average for each period. 
- Final `Select Statement`:
 - The buckets CTE will look like this:

    ![image](https://user-images.githubusercontent.com/94410139/160493303-78a0f419-1eb4-4237-963c-151c15904761.png)
    - We want to rename each bucket to the period of days, so bucket 1 will be 0 - 30 days, bucket 2 will be 31 - 60 days... 
      - For that we need to create a math formula:
        - For the lower bound of the period want (the bucket number - 1) * 30 + 1. Example, Bucket 2 would be: (2 - 1) * 30 + 1 = 31
        - For the upper bound we need the bucket number * 30. Example, Bucket 2 would be: 2 * 30 = 60 
        - For Bucket 1 that does not work as we want the lower bound be stay 0 and not become 1. So, we need to build a Case Statement to separate bucket 1 from the rest.  
      - we also want to use CONCAT() to join the parts of the string together. 

```sql
WITH join_date AS ( 
                   SELECT customer_id,
                          MIN(start_date) AS join_date
                   FROM   subscriptions
                   GROUP  BY customer_id
                  ),
  upgrade_date AS (
                   SELECT customer_id,
                          start_date AS upgrade_date
                   FROM   subscriptions
                   WHERE  plan_id = 3
                   GROUP  BY customer_id, start_date
                   ),
      buckets AS ( 
                  SELECT WIDTH_BUCKET(u.upgrade_date - j.join_date, 0, 360, 12) AS bucket,
                         COUNT(u.customer_id) AS customer_count,
                         ROUND(AVG(CAST(u.upgrade_date - j.join_date AS DECIMAL)), 0) AS average_days
                  FROM   join_date AS j
                  JOIN   upgrade_date AS u
                  ON     j.customer_id = u.customer_id
                  GROUP  BY WIDTH_BUCKET(upgrade_date - join_date, 0, 360, 12)
                 )
SELECT CASE 
           WHEN bucket = 1 
           THEN CONCAT((bucket - 1) * 30,' - ', bucket * 30, ' days') 
           ELSE CONCAT((bucket - 1) * 30 + 1,' - ', bucket * 30, ' days')
       END AS period,
       customer_count,
       average_days
FROM   buckets
GROUP  BY bucket, customer_count, average_days
ORDER  BY bucket 
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160495168-6cb4d013-91e2-4e89-a7d0-9da553140801.png)

- There are 48 customers that took between 0 and 30 days to upgrade to the annual plan. The average for that period was 10 days. 
- There are 25 customers that took between 31 and 60 days to upgrade to the annual plan. The average for that period was 42 days.
- ...  

#
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

#### SQL Query
- We want to know how many customers passed from having a pro monthyl plan (plan_id = 2) to a basic monthly plan (plan_id = 1) in the year 2020.
- We can use the LEAD() Window Function.

```sql
WITH downgrade AS ( 
                   SELECT customer_id,
                          CASE 
                              WHEN plan_id = 2 AND LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) = 1
                              THEN 1
                              ELSE 0
                          END AS downgraded_to_basic
                   FROM subscriptions
                   WHERE DATE_PART('YEAR', start_date) = 2020
                   )
SELECT SUM(downgraded_to_basic) AS customers_downgraded
FROM   downgrade
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160496093-020165ef-0a2e-42b9-b51f-0fc31c1eaec6.png)