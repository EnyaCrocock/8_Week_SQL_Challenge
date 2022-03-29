# 🥑 A. Customer Journey Solutions

<p align="right"> Using PostgreSQL </p>

#
## Question
Based off the 8 sample customers provided in the sample from the subscriptions table (customer_id 1, 2, 11, 13, 15, 16, 18, 19), write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

#### SQL Query

- To see a customers jouney we want to SELECT the customer_id, the plan_name (to see the different plans they have subscribed to) and the start_date (to see when). 
- We can also add a column to show how long it took them to change, upgrade or cancel their subscription. 
  - For this we can use the `LAG()` Window Function:
  
    > `LAG()` let's you compare the current row to the previous row (or row above). It lets you access the value on the previous row from the current row. 

    - We want to know the difference in DAYS between the start_date of each plan and the start_date of the previous plan:
      - start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) 
    - We can also add a column with the difference in MONTHS:
      - As PostgreSQL doesn't have DATEDIFF() I multiplied the days by 0.0329 to convert them to months.
      - start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) * 0.0329


```sql
SELECT s.customer_id,
       p.plan_name,
       s.start_date,
       start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS days_difference,
       ROUND((start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date)) * 0.0329, 0) AS months_difference
FROM   subscriptions AS s
JOIN   plans AS p
ON     s.plan_id = p.plan_id
WHERE  s.customer_id IN (1,2,11,13,15,16,18,19)
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/160461248-689ee96a-fbeb-44dc-8275-89a078dfba6e.png)

- Customer 1 signed up for a free trial on the 1st of August 2020 and decided to subscribe to the basic monthly plan right after it ended. 
- Customer 2 signed up for a free trial on the 20th of September 2020 and decided to upgrade to the pro annual plan right after it ended.
- Customer 11 signed up for a free trial on the 19th of November 2020 and decided to cancel their subscription on the billing date. 
- Customer 13 signed up for a free trial on the 15th of December 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro monthly plan three months later. 
- Customer 15 signed up for a free trial on the 17th of March 2020 and then decided to upgrade to the pro monthly plan right after it ended for one month before cancelling it. 
- Customer 16 signed up for a free trial on the 31st of May 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro annual plan four months later.
- Customer 18 signed up for a free trial on the 6th of July 2020 and then went on to pay for the pro monthly plan right after it ended. 
- Customer 19 signed up for a free trial on the 22nd of June 2020, went on to pay for the pro monthly plan right after it ended and upgraded to the pro annual plan two months in. 
