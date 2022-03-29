# 🥑 C. Challenge Payment Question

<p align="right"> Using PostgreSQL </p>

#
## Question
The Foodie-Fi team wants you to create a `new payments table` for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:

- monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

Example outputs for this table might look like the following:

![image](https://user-images.githubusercontent.com/94410139/160450728-3285fc1e-8176-4566-a2bd-07a3cb36441f.png)

#
#### SQL Query
- The first thing we might notice from the screenshot above is that payment_date is a series, it is ongoing until the end of 2020, or until it hits a stop. We need to generate that. 
- Let's create a CTE for the series, where we will also grab all the columns we will need to recreate the final output. 
  - To create the `payment_date series` we will use the `GENERATE_SERIES()` Function. 
    > This function requires you to set a start date and an end date to the series, as well as the interval by which you want to increment the dates. 
    - We want the payment_date to `start` on the start_date (the day the plan starts).
    - For the `end date` we will have to use a `CASE Statement` as the date will be different for different plans.
      - CASE WHEN plan_id is 0, 3 or 4 (trial, annual or churn)
      - THEN end on the start_date (there is no recurring payments for any of them)
      - WHEN the plan_id is 1 or 2 AND the following plan is not the same (the plan changes)
      - THEN end on the day before the plan changes (not on the same day of the change)
        - This is because we dont want this to happen: 
        ![image](https://user-images.githubusercontent.com/94410139/160615865-4f34ae2b-312a-4c27-90d9-e446e53400f5.png)
        - Customer 19 won't be paying for plan 2 on 2020-08-29, only for plan 3. 
        - We can't let end date of one plan coincide with the start date of another. 
        - By making the series stop the day before, there wont be a month by which the date can increase so it will end on the 2020-07-29:
        ![image](https://user-images.githubusercontent.com/94410139/160615189-b5747a96-7345-4b56-b3c7-2202f10107fc.png)
      - ELSE END on '2020-12-31'
      - We want the dates to increment by 1 MONTH each time as plans 1 and 2 are payed monthly. 
  - We will also SELECT the prices as we will need them to calculate the amounts.
- In the `final SELECT statement`:
  - Here we are going to SELECT all the columns that we need from the series CTE for the final table: customer_id, plan_id, plan_name, payment_date, and we are going to calculate the amount and create the rank for payment_order. 
    - To calculate the `amount` we will use a `CASE Statement`:
      - CASE WHEN plan_id = 1 (basic monthly plan)
      - THEN return the normal price
      - WHEN plan_id is 2 or 3 (pro monthly or annual) AND the previous plan is not the same (there was a plan change) AND the change happened before the month ended (before the new billing date)
      - THEN subtract the price payed for the previous plan from the price of the new plan.
      - ELSE return the normal price
    - For the `payment_order` we can use `RANK()`.
  - As free trials and churn plans don't make payments we will filter them out. 



```sql
WITH series AS (
                SELECT s.customer_id,
                       s.plan_id,
                       p.plan_name,
                       CAST(GENERATE_SERIES(s.start_date,
                                            CASE
                                                WHEN s.plan_id IN (0, 3, 4) THEN s.start_date 
                                                WHEN s.plan_id IN (1, 2)
                                                     AND LEAD (s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) <> s.plan_id
                                                THEN LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) - 1 
                                                ELSE '2020-12-31'
                                            END,
                                            '1 MONTH'
                                            ) AS DATE) AS payment_date,
                       p.price
                FROM   subscriptions AS s
                JOIN   plans AS p
                ON     s.plan_id = p.plan_id
                WHERE  DATE_PART('YEAR', s.start_date) = 2020
               )
SELECT customer_id,
       plan_id, 
       plan_name,
       payment_date,
       CASE 
           WHEN plan_id = 1
           THEN price
           WHEN plan_id IN (2, 3)
                AND LAG (plan_id) OVER (PARTITION BY customer_id ORDER BY payment_date) <> plan_id
                AND payment_date - LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) < 30
           THEN price - LAG(price) OVER (PARTITION BY customer_id ORDER BY payment_date)
           ELSE price
       END AS amount,
       RANK () OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order 
INTO   payments
FROM   series
WHERE  plan_id NOT IN (0, 4)
```

#### Result 
(I'm going to select the same customer_ids as there are on the example table) In total there are 4448 rows. 

```sql
SELECT * 
FROM   payments 
WHERE  customer_id IN (1,2,13,15,16,18,19)	 				
```
![image](https://user-images.githubusercontent.com/94410139/160614819-1757b025-f53a-4d84-ba5b-b15951d959ae.png)