# 💵⭐ D. Pricing and Ratings Solutions

<p align="right"> Using Microsoft SQL Server </p>

#
## Questions

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
- Here we will want to use a SUM function with a CASE Statement.
  - The `SUM` with `Case Statement`: 
    - WHEN the pizza name is Meatlovers 
    - THEN add 12 (dollars)
    - ELSE add 10

```sql
SELECT SUM( 
           CASE
		           WHEN n.pizza_name = 'Meatlovers' 
               THEN 12
               ELSE 10
           END 
           ) AS total_earned
FROM  pizza_names AS n
JOIN  ##customer_orders AS c
ON    c.pizza_id = n.pizza_id
JOIN  ##runner_orders AS r
ON    c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
```

