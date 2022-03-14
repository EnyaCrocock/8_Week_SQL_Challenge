# 🍜 Case Study #1 - Danny's Diner Solutions

## Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT s.customer_id,
       SUM(m.price) AS total_spent
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
GROUP  BY s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158030918-7ecba371-4167-4aa3-b352-f4fd5f7cec2a.png)

#

### 2. How many days has each customer visited the restaurant?

```sql
SELECT customer_id,
       COUNT(DISTINCT order_date) AS total_days_visited
FROM   sales
GROUP  BY customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158030978-74727ee7-71c3-4d60-b1a5-b77e99259771.png)

#

### 3. What was the first item from the menu purchased by each customer?


- Create a `CTE`  
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date)` 
    - Rank 1 will be the first item purchased (the one with the earliest date), 2 the second...
    - For this you can use RANK or DENSE_RANK
- From that CTE we then want to `select the first item purchased by each customer` 
  - This is `WHERE rank = 1`

```sql
WITH purchase_order_rank AS (
                             SELECT s.customer_id,
                                    s.order_date,
                                    m.product_name,
                                    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
                             FROM   sales AS s
                             JOIN   menu AS m
                             ON     s.product_id = m.product_id
                             GROUP  BY s.customer_id, s.order_date, m.product_name
                             )
SELECT customer_id,
       product_name AS first_item_purchased,
       order_date
FROM   purchase_order_rank
WHERE  rank = 1
```
#### purchase_order_rank table output:

  ![image](https://user-images.githubusercontent.com/94410139/158033738-ec9f6314-d897-4471-9fd4-156ac67546a5.png)
  
#### Question Result: 

  ![image](https://user-images.githubusercontent.com/94410139/158037120-df2db300-0d37-4b6c-b45e-6795854f41b3.png)

  - Customer A's first orders were Curry & Sushi
  - Customer B's was Curry
  - Customer C's was Ramen 

#

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
 ```sql
SELECT TOP 1
        m.product_name,
        COUNT(s.product_id) AS times_purchased
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
GROUP  BY product_name
ORDER  BY COUNT(s.product_id) DESC
 ```
 #### Result
![image](https://user-images.githubusercontent.com/94410139/158037436-1221ab5d-4e99-4b4f-bcbe-76f4fbbc053b.png)

#

### 5. Which item was the most popular for each customer?

- Create a `CTE`  
- In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the times purchased (COUNT of product_id)` 
  - Rank 1 will be the most purchased item, 2 the second...
  - For this you can use RANK or DENSE_RANK
- From that CTE we then want to `select the most purchased item by each customer` 
  - This is `WHERE rank = 1`

```sql
WITH favourite_item_rank AS (
                             SELECT s.customer_id,
                                    m.product_name,
                                    COUNT(s.product_id) AS times_purchased,
                                    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank
                             FROM   sales AS s
                             JOIN   menu AS m
                             ON     s.product_id = m.product_id
                             GROUP  BY s.customer_id, m.product_name
                             )
SELECT customer_id,
       product_name AS favourite_item,
       times_purchased
FROM   favourite_item_rank
WHERE  rank = 1
```

#### favourite_item_rank table output:
  ![image](https://user-images.githubusercontent.com/94410139/158037640-75e76fcb-31f8-4abf-b4ab-d4cf83775cec.png) 

#### Question Result:
  ![image](https://user-images.githubusercontent.com/94410139/158037660-31e9a5c2-d231-4f54-a140-70f2ffec7a3e.png)

- Customer A's favourite item is Ramen
- Customer B likes all items equally
- Customer C loves Ramen

#

### 6. Which item was purchased first by the customer after they became a member?

- Create a `CTE`
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date)` 
    - Rank 1 will be the first item purchased, 2 the second...
    - For this you can use RANK or DENSE_RANK
  - We need to include a `WHERE clause` in the CTE as we `only want items purchased after they became a member`
    - WHERE order_date >= join_date
- From that CTE we then want to `select the first item purchased by each customer` 
  - This is `WHERE rank = 1`

```sql
WITH purchase_order_rank AS (
                             SELECT s.customer_id,
                                    s.order_date,
                                    m.product_name,
                                    c.join_date,
                                    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
                             FROM   sales AS s
                             JOIN   menu AS m
                             ON     s.product_id = m.product_id
                             JOIN   members AS c
                             ON     s.customer_id = c.customer_id
                             WHERE  s.order_date >= c.join_date
                             )
SELECT customer_id,
       product_name AS first_item_purchased,
       join_date,
       order_date
FROM   purchase_order_rank 
WHERE  rank = 1
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158038017-f42bd6be-0bf4-44af-8251-0d1931edd91b.png)

- Customer A purchased Curry on the day they joined
- Customer B puchased Sushi 2 days after joining

#

### 7. Which item was purchased just before the customer became a member?

- Create a `CTE`
  - In it, create a new column to show a `ranking of the items purchased by each customer (customer_id) based on the date of purchase (order_date) in descending order` 
    - Rank 1 will be the last item purchased (the item purchased on latest date), 2 the second...
    - For this you can use RANK or DENSE_RANK
  - We need to include a `WHERE clause` in the CTE as we `only want items purchased before they became a member`
    - WHERE order_date < join_date
- From that CTE we then want to `select the first item purchased by each customer` 
  - This is `WHERE rank = 1`

```sql
WITH purchase_order_rank AS (
                             SELECT s.customer_id,
                                    s.order_date,
                                    m.product_name,
                                    c.join_date,
                                    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
                             FROM   sales AS s
                             JOIN   menu AS m
                             ON     s.product_id = m.product_id
                             JOIN   members AS c
                             ON     s.customer_id = c.customer_id
                             WHERE  s.order_date < c.join_date
                             )
SELECT customer_id,
       product_name AS last_item_purchased,
       order_date,
       join_date
FROM   purchase_order_rank 
WHERE  rank = 1
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158038173-69c72231-a4bc-4cc8-a0ff-12e0175a2b8d.png)

- Customer A's last item purchased before becoming a member was Sushi & Curry
- Customer B's was Sushi

#

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT s.customer_id,
       COUNT(s.product_id) AS total_items,
       SUM(m.price) AS total_amount_spent
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
JOIN   members AS c
ON     s.customer_id = c.customer_id
WHERE  s.order_date < c.join_date
GROUP  BY s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158038247-42d3c14b-2d0d-47ba-bf40-e82b78b2a39d.png)

#

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

- Every $1 = 10 points
- For sushi $1 = 20 points (2 x 10) 
- We want to SUM each customers points. 
  - One way to do this is using the `SUM funcion with a CASE statement`:
       - When the product name is sushi then multiply the price by 20, when not then multiply it by 10
       - Then sum all the points 

```sql
SELECT s.customer_id,
       SUM(CASE 
               WHEN m.product_name = 'sushi' 
               THEN m.price * 20 
               ELSE m.price * 10 
           END) AS total_points
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
GROUP  BY s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158038528-a4c8f4b2-72cf-4503-9cbb-037d93f2bc18.png)

# 

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

- On the week the customer joins (from join date to 7 days after) $1 = 20 points
- Every other day $1 = 10 points
- For this I created 2 CTE's, one to calculate join week points and another for normal day points 
  - For the `join_week_points CTE`
    - Here we want to calculate the points earned by each customer on their join week
    - Multiply the price x 20 and SUM all the points
    - Use a `WHERE` clause to filter only the items purchased `BETWEEN` the join date and 7 days after (a week)
  - For the `normal_points CTE`
    - Here we want to calculate the points earned by each customer for the month of January, excluding the join week 
    - Use the same SUM function with the CASE statement as for the previous question
    - Use a `WHERE` clause to filter the items puchased on the `month of January` (MONTH(order_date) = 1) 
    - AND the items purchased `NOT BETWEEN` the join date and 7 days after (filter out join week)
- From those CTE's we want to select the customer_id's and the sum of join_week_points and normal_points

```sql
WITH 
     join_week_points AS (
                         SELECT s.customer_id,
                                SUM(m.price * 20) AS join_week_points
                         FROM   sales AS s
                         JOIN   menu AS m
                         ON     s.product_id = m.product_id
                         JOIN   members AS c
                         ON     s.customer_id = c.customer_id
                         WHERE  s.order_date BETWEEN c.join_date AND DATEADD(DAY, 7, c.join_date)
                         GROUP  BY s.customer_id
                         ),

     normal_points   AS (
                         SELECT s.customer_id,
                                SUM(CASE 
                                        WHEN m.product_name = 'sushi' 
                                        THEN m.price * 20 
                                        ELSE m.price * 10 
                                    END) AS normal_points
                         FROM   sales AS s
                         JOIN   menu AS m
                         ON     s.product_id = m.product_id
                         JOIN   members AS c
                         ON     s.customer_id = c.customer_id
                         WHERE  MONTH(s.order_date) = 1
                         AND    s.order_date NOT BETWEEN c.join_date AND DATEADD(DAY, 7, c.join_date)
                         GROUP  BY s.customer_id
                         )
SELECT j.customer_id,
       j.join_week_points + n.normal_points AS total_points_january
FROM   join_week_points AS j
JOIN   normal_points AS n
ON     j.customer_id = n.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158180650-7806642f-356b-4bac-bbae-36d02cc3e0ee.png)

---

## Bonus Questions

### 1. Join All Things

- Replicate this output:

  <img width="300" src="https://user-images.githubusercontent.com/94410139/158183700-39da11dc-067d-42e7-8367-86dc3c182031.png">
#    
- For this I used `CASE WHEN EXISTS`
  - When the `customer_id EXISTS in the members table and the order_date is after or on the join_date` then 'Y' (they are a member at that time), else 'N' (they are not)
 
```sql
SELECT s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE 
           WHEN EXISTS ( 
                        SELECT customer_id
                        FROM   members AS c
                        WHERE  s.customer_id = c.customer_id
                        AND    s.order_date >= c.join_date
                        )
		   THEN 'Y'
		   ELSE 'N'
           END AS member
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158208767-322aa72f-cb40-4f86-9b1b-327625381b52.png)

#

### 2. Rank All Things

- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
- Replicate this output:

  <img width="300" src="https://user-images.githubusercontent.com/94410139/158209150-dc41af27-5565-42b7-9fea-af8f553f6801.png">
#
- For this create a CTE with the joined table from the last question
- Then SELECT everything from that table and add a new column for the ranking 
   - For the RANK we need to `PARTITION by both customer_id and member`
   - You can use RANK or DENSE_RANK
 
 ```sql
 WITH joined_table AS (
                       SELECT s.customer_id,
                              s.order_date,
                              s.product_id,
                              m.product_name,
                              m.price,
                              CASE 
                                  WHEN EXISTS ( 
                                               SELECT customer_id
                                               FROM   members AS c
                                               WHERE  s.customer_id = c.customer_id
                                               AND    s.order_date >= c.join_date
                                               )
                                  THEN 'Y'
                                  ELSE 'N'
                              END AS member			                 
                       FROM   sales AS s
                       JOIN   menu AS m
                       ON     s.product_id = m.product_id
                       )
SELECT customer_id,
        order_date,
        product_name,
        price,
        member,
        CASE  
            WHEN member = 'Y'
            THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
            ELSE NULL
        END AS ranking
FROM   joined_table
 ```
#### Result
![image](https://user-images.githubusercontent.com/94410139/158212209-f8c8a19f-197a-4db0-bb8b-592cb629251a.png)


