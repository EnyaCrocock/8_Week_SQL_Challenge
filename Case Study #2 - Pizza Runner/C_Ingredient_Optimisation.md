# 🧀🥓 C. Ingredient Optimisation Solutions

<p align="right"> Using Microsoft SQL Server </p>

## Contents:
- [Data Cleaning Solutions](#data-cleaning-for-this-section)
- [Question Solutions](#questions)

## Data Cleaning for this section 
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
- Adding an Identity Column (to be able to uniquely identify every single pizza ordered) 

```sql
ALTER TABLE  ##customer_orders
ADD          record_id INT IDENTITY (1,1)
```
![image](https://user-images.githubusercontent.com/94410139/158246338-0833d930-6d47-41e9-aadb-26f41c454b0a.png)

#
### 3. New Tables: `Exclusions` & `Extras` 

#### Original table ##customer_orders:
![image](https://user-images.githubusercontent.com/94410139/158246338-0833d930-6d47-41e9-aadb-26f41c454b0a.png)

#### Changes:
- Splitting the exclusions & extras comma delimited lists into rows and storing in new tables

#### New Exclusions Table:
```sql
SELECT record_id,
       TRIM(value) AS exclusions_id
INTO   ##exclusions
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(exclusions, ',')
```
![image](https://user-images.githubusercontent.com/94410139/158248028-26634028-b3c5-4925-b3cd-be622db5e02a.png)

#### New Extras Table:
```sql
SELECT record_id,
       TRIM(value) AS extras_id
INTO   ##extras
FROM   ##customer_orders
CROSS  APPLY STRING_SPLIT(extras , ',')
```
![image](https://user-images.githubusercontent.com/94410139/158248089-507e71f1-e245-4c9a-84fe-6e9c413ff0ef.png)

#
## Questions
### 1. What are the standard ingredients for each pizza?
- We can use `STRING_AGG()` to create a comma delimited list of the topping names.

```sql
SELECT n.pizza_name,
       STRING_AGG(t.topping_name, ', ') AS standard_ingredients
FROM   pizza_names AS n
JOIN   ##pizza_recipes AS r
ON     n.pizza_id = r.pizza_id
JOIN   pizza_toppings AS t
ON     r. topping_id = t.topping_id
GROUP  BY n.pizza_name
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/159054821-ad6bde37-8b7f-412f-951f-dc85158dbd37.png)

#
### 2. What was the most commonly added extra?
- We can `SELECT` the `topping_name`, as well as a `COUNT of extras_id` (this gives us the times that topping was added as an extra).
- If we use `SELECT TOP 1` and `order by the COUNT of extras_id in DESCENDING order` (largest count first), we get the most added extra.

```sql
SELECT TOP 1
       t.topping_name, 
       COUNT(x.extras_id) AS times_added
FROM   pizza_toppings AS t
JOIN   ##extras AS x
ON     t.topping_id = x.extras_id
GROUP  BY t.topping_name 
ORDER  BY times_added DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/159057448-d09b53c2-4e90-46e9-84c0-a02de0b753b8.png)

#
### 3. What was the most common exclusion?
- Same as the question above but using the `COUNT of exclusions_id`.

```sql
SELECT TOP 1
       t.topping_name, 
       COUNT(e.exclusions_id) AS times_removed
FROM   pizza_toppings AS t
JOIN   ##exclusions AS e
ON     t.topping_id = e.exclusions_id
GROUP  BY t.topping_name
ORDER  BY times_removed DESC
```
#### Result
![image](https://user-images.githubusercontent.com/94410139/159057816-1a7819bf-7c2c-47cf-a077-604011b66d20.png)

#
These next few questions did give me a headache... but I'm going to try to explain how I got the solutions. 

#
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


#### Explanation
- What this question is asking is for you to create a column in the customer_orders table where, for every record, it tells you the name of the pizza ordered as well as the names of any toppings added as extras or exclusions.

#### One way to achieve this
- Create `2 CTE's`: One for exclusions and one for extras.
  - We want to know what was excluded or added to each pizza.
  - In these CTE's we are going to SELECT the record_id (The unique identifier for every pizza ordered, [that we created in the data cleaning section](#2-table-customer_orders)) and the topping_name for those extras or exclusions.
    - We are using `STRING_AGG` to show those topping names in a comma delimited list (as that is how we need them in the final output).
    
- In the `final SELECT Statement` we are going to want to SELECT every column in the customer_orders table and create a CASE Statement to create that order_item column we want.
  - This is the example of the output we want to replicate with the CASE Statement:
  
     ```sql 
        - Meat Lovers
        - Meat Lovers - Exclude Beef
        - Meat Lovers - Extra Bacon
        - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
     ```
  - `Case Statment`:
    - CASE WHEN the pizza ordered didn't have any exclusions or extras (when they were both blank ('')) 
      - THEN return the pizza name
    - WHEN it did have exclusions but no extras (exclusions was not blank and extras was)
      - THEN return the pizza name, the string ' - Exclude', and the topping names for those exclusions (from the exclusions CTE)
      - <i>To join those three parts we need we use `CONCAT()`</i> 
    - WHEN it did have extras but no exclusions (exclusions was blank and extras wasn't) 
      - THEN return the pizza name, the string ' - Extra', and the topping names for those extras (from the extras CTE)
    - ELSE (when the pizza has both exclusions and extras)
      - return the pizza name, the string ' - Exclude', the topping names for those exclusions (from the exclusions CTE), the string ' - Extra', and the topping names for those extras (from the extras CTE)  

```sql
WITH exclusions AS (
                    SELECT a.record_id,
                           STRING_AGG(t.topping_name, ', ') AS exclusions
                    FROM   ##exclusions AS a
                    JOIN   pizza_toppings AS t
                    ON     a.exclusions_id = t.topping_id
                    GROUP  BY a.record_id
                    ),
         extras AS ( 
                    SELECT b.record_id,
                           STRING_AGG(t.topping_name, ', ') AS extras
                    FROM   ##extras AS b
                    JOIN   pizza_toppings AS t
                    ON     b.extras_id = t.topping_id
                    GROUP  BY b.record_id
                    )
SELECT c.order_id,
       c.customer_id,
       c.pizza_id,
       c.exclusions,
       c.extras,
       c.order_time,
       CASE 
           WHEN c.exclusions = '' AND c.extras = '' 
           THEN n.pizza_name
           WHEN c.exclusions <> '' AND c.extras = ''
           THEN CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions)
           WHEN c.exclusions = '' AND c.extras <> ''
           THEN CONCAT(n.pizza_name, ' - Extra', ' ', x.extras)
           ELSE CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions, ' - Extra', ' ', x.extras) 
       END AS order_item
FROM  ##customer_orders AS c 
LEFT  JOIN exclusions AS e
ON    c.record_id = e.record_id
LEFT  JOIN extras AS x
ON    c.record_id = x.record_id
LEFT  JOIN  pizza_names AS n
ON    c.pizza_id = n.pizza_id
```
#### exclusions CTE output
![image](https://user-images.githubusercontent.com/94410139/159073315-ced0617a-f633-44ee-81b7-e9467e937869.png)

#### extras CTE output
![image](https://user-images.githubusercontent.com/94410139/159073380-08a01502-6e4f-4574-b684-e84bcb134c1f.png)

#### Final Result
![image](https://user-images.githubusercontent.com/94410139/159073730-2c39a908-1659-459f-a0dc-24cdec72f03a.png)

#
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


#### Explanation
- Here we want to create a new column in the customer_orders table in which it tells us, for each record, the pizza name as well as a list of the ingredients to use. 
- In the ingredient list we want to exclude the toppings the customer excluded (we dont want them to appear on the list) and add a '2x' infront of the toppings the customer added as extras. 

#### One way to achieve this
- Create a `CTE` for the ingredients
  - We want to know what ingredients made each pizza as well as if anything had to be doubled. 
  - In this CTE we are going to SELECT the record_id, the pizza_name, the topping_name, create a CASE Statement to show the '2x' and add a WHERE clause to exclude all the exclusions from the list of ingredients.
    - `The CASE Statement`:
    - We want to generate a column (I called it extras) where it shows a '2x' by any record (so, any pizza) that has a topping in its list of ingredients (topping_id) that exists in the extras_id column in the [##extras table](#new-extras-table) (so, when that topping was added as an extra). 
      - CASE WHEN the topping (topping_id) is found IN the extras_id column in the ##extras table WHERE the records are the same
      - THEN return '2x' 
      - ELSE return blank ('') 
    - the `WHERE clause`:
      - for every record (every pizza) we only want to include the toppings (topping_id) that are NOT IN the exclusions_id column in the [##exclusions table](#new-exclusions-table) for that same record (we dont want to show the toppings that where excluded in the final ingredient list). 
- In the `final SELECT Statement`:
  - We are going to SELECT every record in the cutomer_orders table
  - We are going to generate a new column where for every record it tells us the pizza_name, as well as a comma delimited list of the ingredients (the topping names) with a '2x' infront of any extras (using the extras column we created in the CTE). 
    - For this we will use CONCAT(), to join the parts of the string, and STRING_AGG() to create the comma delimited list. 
    - It will look like this:
      - CONCAT(i.pizza_name, ': ', STRING_AGG(CONCAT(i.extra,i.topping_name),', ')) AS ingredient_list

```sql
WITH ingredients AS (
                     SELECT c.record_id,
                            n.pizza_name,
                            t.topping_name,
                            CASE
                                WHEN t.topping_id IN (
                                                      SELECT extras_id 
                                                      FROM   ##extras AS x 
                                                      WHERE  x.record_id = c.record_id
                                                      ) 
                                THEN '2x'
                                ELSE '' 
                            END AS extra
                     FROM   ##customer_orders AS c
                     JOIN   pizza_names AS n
                     ON     c.pizza_id = n.pizza_id
                     JOIN   ##pizza_recipes AS r
                     ON     n.pizza_id = r.pizza_id
                     JOIN   pizza_toppings AS t
                     ON     r.topping_id = t.topping_id
                     WHERE  t.topping_id NOT IN (
                                                 SELECT exclusions_id
                                                 FROM   ##exclusions AS e
                                                 WHERE  e.record_id = c.record_id
                                                 )
                     GROUP  BY c.record_id, n.pizza_name, t.topping_name, t.topping_id
                     )
SELECT c.order_id,
       c.customer_id,
       c.pizza_id,
       c.exclusions,
       c.extras,
       c.order_time,
       CONCAT(i.pizza_name, ': ', STRING_AGG(CONCAT(i.extra,i.topping_name),', ')) AS ingredient_list
FROM   ##customer_orders AS c 
JOIN   ingredients AS i
ON     c.record_id = i.record_id
GROUP  BY c.record_id, c.order_id, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, i.pizza_name
```
#### Fragment of the ingredients CTE output
![image](https://user-images.githubusercontent.com/94410139/159129563-8910064b-9f76-413a-8747-dd3b60273de1.png)

#### Final Result
![image](https://user-images.githubusercontent.com/94410139/159129594-273154df-5386-4df0-b145-b9280899ff36.png)

#
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

#### Explanation
- Here we want a list of the all the ingredients and a SUM of how many times each one has been used, in DESCENDING order (most used first).

#### One way to achieve this
- Create a `CTE`:
- We want to know what ingredients as well as what quantity of each ingredient was needed to make each pizza (was the ingredient removed? was it doubled?). 
- In this CTE we are going to SELECT the record_id, the pizza_name, the topping_name, create a CASE Statement to show the times every ingredient was used in each pizza.
  - The `CASE Statemet`:
    - We want to generate a column (I called it times_used) where it shows a 2 by any record (so, any pizza) that has a topping in its list of ingredients (topping_id) that exists in the extras_id column in the [##extras table](#new-extras-table) (so, when that topping was added as an extra). Then a 0 by any record (so, any pizza) that has a topping in its list of ingredients (topping_id) that exists in the exclusions_id column in the [##exclusions table](#new-exclusions-table) (so, when that topping was removed). And a 1 by anythig else. 
      - CASE WHEN the topping (topping_id) is found IN the extras_id column in the ##extras table WHERE the records are the same
      - THEN return 2
      - WHEN the topping (topping_id) is found IN the exclusions_id column in the ##exclusions table WHERE the records are the same
      - THEN return 0
      - ELSE return 1
- In the `final SELECT Statement`:
  - SELECT the topping_name
  - And a SUM of the times_used
  - ORDER BY the times_used in DESCENDING order (most frequently used first)

```sql
WITH ingredients AS (
                     SELECT c.record_id,
                            t.topping_name,
                            CASE
                                WHEN t.topping_id IN (
                                                      SELECT extras_id 
                                                      FROM   ##extras AS x 
                                                      WHERE  x.record_id = c.record_id
                                                      ) 
                                THEN 2
                                WHEN t.topping_id IN (
                                                      SELECT exclusions_id 
                                                      FROM   ##exclusions AS e 
                                                      WHERE  e.record_id = c.record_id
                                                      ) 
                                THEN 0
                                ELSE 1 
                            END AS times_used
                     FROM   ##customer_orders AS c
                     JOIN   pizza_names AS n
                     ON     c.pizza_id = n.pizza_id
                     JOIN   ##pizza_recipes AS r
                     ON     n.pizza_id = r.pizza_id
                     JOIN   pizza_toppings AS t
                     ON     r.topping_id = t.topping_id
                     GROUP  BY c.record_id, t.topping_name, t.topping_id
                     )
SELECT topping_name,
       SUM(times_used) AS times_used 
FROM   ingredients
GROUP  BY topping_name
ORDER  BY times_used DESC
```
#### Fragment of ingredients CTE
![image](https://user-images.githubusercontent.com/94410139/159130685-830be392-b6ff-4ffb-be7f-581e1dd60d86.png)

#### Final Result
![image](https://user-images.githubusercontent.com/94410139/159130603-d3489b87-ab4c-4463-993b-25b017942c31.png)
