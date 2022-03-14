-- Case Study #1 - Danny's Diner -- 

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id,
       SUM(m.price) AS total_spent
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
GROUP  BY s.customer_id


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
       COUNT(DISTINCT order_date) AS total_days_visited
FROM   sales
GROUP  BY customer_id


-- 3. What was the first item from the menu purchased by each customer?

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

					         
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name,
       COUNT(s.product_id) AS times_purchased
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
WHERE  s.product_id = (
                       SELECT MAX(product_id) 
					   FROM   sales
					   )
GROUP  BY m.product_name

-- OR

SELECT TOP 1
       m.product_name,
       COUNT(s.product_id) AS times_purchased
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
GROUP  BY product_name
ORDER  BY COUNT(s.product_id) DESC


-- 5. Which item was the most popular for each customer?

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


-- 6. Which item was purchased first by the customer after they became a member?

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


-- 7. Which item was purchased just before the customer became a member?

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


-- 8. What is the total items and amount spent for each member before they became a member?

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


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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


-- Bonus Questions

-- Join All The Things

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

-- OR

SELECT s.customer_id,
       s.order_date,
	   m.product_name,
	   m.price,
	   CASE 
	       WHEN s.order_date >= c.join_date
		   THEN 'Y'
		   ELSE 'N'
	   END AS member
FROM   sales AS s
JOIN   menu AS m
ON     s.product_id = m.product_id
LEFT   JOIN members AS c
ON     s.customer_id = c.customer_id


-- Rank All The Things

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
