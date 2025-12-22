# sql_Pizza_Sales_Analysis

## Project Overview

**Project Title**: Pizza Sales Analysis Using SQL
**Level**: Intermediate
**Database**: 'Pizza_Sales Project SQL.db'

This project analyzes transactional pizza sales data to uncover insights related to revenue performance, product demand, and customer ordering patterns. The goal is to demonstrate strong SQL skills, business reasoning, and the ability to translate raw data into actionable insights for decision-making.
The analysis was performed using postgreSQL, with normalized tables and advanced SQL techniques such as CTEs, CASE statements, window functions, and aggregations.

## Objectives

1. Set up a pizza sales database: Create and populate the pizza sales database with the provided pizza sales data.
2. Normalize raw data: Transform the original flat dataset into multiple related tables following normalization principles, ensuring each table represents a single entity and relationships are clearly defined using primary and foreign keys.
3. Data Cleaning: Identify and remove any records with missing or null values.
4. Exploratory Data Analysis (EDA): Perform basic exploratory data analysis to understand the dataset.
5. Business Analysis: Use SQL to answer specific business questions and derive insights from the sales data.

## Project Structure

### 1. Database Creation

The project starts by creating a database named 'Pizza_Sales Project SQL.db'. A table called 'pizza_sales_clean' is created to store the pizza sales data.
  
```sql
CREATE DATABASE Pizza_Sales Project SQL.db;

-- Create pizza_sales_clean table

DROP TABLE IF EXISTS pizza_sales_clean;
CREATE TABLE pizza_sales_clean
			(
				order_details_id INT,
				order_id INT,
				pizza_id VARCHAR(25),
				quantity INT,
				order_date DATE,
				order_time TIME,
				unit_price FLOAT,
				total_price FLOAT,
				pizza_size VARCHAR(10),
				pizza_category VARCHAR(15),
				pizza_ingredients VARCHAR(255),
				pizza_name VARCHAR(50)
			);
      
SELECT *
FROM pizza_sales_clean;
```

### 2. Data cleaning

Check for any null values in the dataset and delete records with missing data.

```sql
-- Checking for duplicates and null values

SELECT * 
FROM pizza_sales_clean
WHERE
	order_details_id IS NULL
	OR
    order_id IS NULL
	OR
    pizza_id IS NULL
	OR
    pizza_name IS NULL
	OR
    pizza_size IS NULL
	OR
    pizza_category IS NULL
	OR
    pizza_ingredients IS NULL
	OR
    quantity IS NULL
	OR
    unit_price IS NULL
	OR
    total_price IS NULL
	OR
    order_date IS NULL
	OR
    order_time IS NULL;

SELECT COUNT (*)
FROM pizza_sales_clean;
```

### 3. Normalization

The 'pizza_sales_clean' table was normalized into the following tables: 
- **orders**: order_id, order_ date and order_time
- **pizzas**: pizza_id, pizza_name, pizza_size, pizza_category, pizza_ingredients
- **order_details**: order_details, order_id, pizza_id, quantity, unit_price, total_price
- **foreign key**: foreign keys order_id and pizza_id were created on the order_details table
This structure minimizes redundancy and reflects real-world relational database design.

```sql
-- Create Orders Table

DROP TABLE IF EXISTS orders;
CREATE TABLE orders 
  (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
  );
```

```sql
-- Create Pizzas Table

DROP TABLE IF EXISTS pizzas;
CREATE TABLE pizzas
  (
    pizza_id VARCHAR(25) PRIMARY KEY,
    pizza_name VARCHAR(50),
    pizza_size VARCHAR(10),
    pizza_category VARCHAR(15),
    pizza_ingredients VARCHAR(255)
  );
  ```
  
  ```sql
-- Create Order_details Table

DROP TABLE IF EXISTS order_details;
CREATE TABLE order_details (
    order_details_id SERIAL PRIMARY KEY, 
    order_id INT NOT NULL,  
    pizza_id VARCHAR(25) NOT NULL,
    quantity INT,
    unit_price FLOAT,
    total_price FLOAT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)
);
```

```sql
-- Insert data into orders table

INSERT INTO orders (order_id, order_date, order_time)
SELECT DISTINCT
    order_id,
    order_date,
    order_time
FROM pizza_sales_clean;

SELECT *
FROM orders;

SELECT COUNT (*)
FROM orders;
```

```sql
-- Insert data into pizzas table

INSERT INTO pizzas (pizza_id, pizza_name, pizza_size, pizza_category, pizza_ingredients)
SELECT DISTINCT
    pizza_id,
    pizza_name,
    pizza_size,
    pizza_category,
    pizza_ingredients
FROM pizza_sales_clean;

SELECT *
FROM pizzas;
```

```sql
-- Insert data into order_details table

INSERT INTO order_details (order_id, pizza_id, quantity, unit_price, total_price)
SELECT order_id, 
		pizza_id, 
		quantity, 
		unit_price, 
		total_price
FROM pizza_sales_clean;
```

```sql
-- Validation 
SELECT COUNT(*) AS orphan_records
FROM order_details
WHERE order_id NOT IN (SELECT order_id FROM orders)
   OR pizza_id NOT IN (SELECT pizza_id FROM pizzas);
```

### 4. Exploratory Data Analysis

- Record Count: Determine the total number of orders  in the dataset.
- Customer Count: Find out how many unique customers are in the dataset.
- Category Count: Identify all unique pizzas in the dataset.

```sql
-- How many orders did we have in total?

SELECT COUNT(*) AS total_orders 
FROM orders;

-- Total number of unique customers

SELECT COUNT (DISTINCT order_id) AS total_customers
FROM orders;

-- Total pizzas sold

SELECT COUNT(*) AS total_pizzas
FROM pizzas;

-- Total number of unique pizzas

SELECT COUNT (DISTINCT pizza_name) AS total_unique_pizzas
FROM pizzas;
```

### 5. Business Analysis

The following SQL queries were developed to answer specific business questions:

a. **What is the total revenue and average order value (AOV)?**
```sql
WITH order_totals AS 
  (
    SELECT
        order_id,
        ROUND(SUM(total_price)::numeric,2) AS order_value
    FROM order_details
    GROUP BY order_id
  )
SELECT
    SUM(order_value) AS total_revenue,
    ROUND(AVG(order_value)::numeric, 2) AS average_order_value
FROM order_totals;
```

b. **How is revenue distributed across pizzas, and what percentage does each contribute?**
```sql
WITH revenue_by_pizza AS 
  (
    SELECT
        p.pizza_name,
        ROUND(SUM(od.total_price)::numeric,2) AS revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY p.pizza_name
  ),
total_revenue AS 
  (
    SELECT SUM(revenue) AS total_rev
    FROM revenue_by_pizza
  )
SELECT
    r.pizza_name,
    r.revenue,
    ROUND((r.revenue / t.total_rev)::numeric * 100, 2) AS revenue_percentage
FROM revenue_by_pizza r
CROSS JOIN total_revenue t
ORDER BY revenue_percentage DESC;
```

c. **Which pizzas generate the most revenue (Top 10 best sellers)?**
```sql
WITH pizza_revenue AS 
  (
    SELECT
        p.pizza_name,
        ROUND (SUM(od.total_price)::numeric,2) AS revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY p.pizza_name
  )
SELECT *
FROM pizza_revenue
ORDER BY revenue DESC
LIMIT 10;
```

d. **How much of each pizza category was sold, and which categories are the top performers in terms of quantity sold?**
```sql
SELECT
    pizza_category,
    SUM(quantity) AS total_units_sold
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pizza_category
ORDER BY total_units_sold DESC;
```

e. **Which combinations of pizza category and size generate the most revenue?**
```sql
SELECT
    p.pizza_category,
    p.pizza_size,
    ROUND(SUM(od.total_price)::numeric,2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_category, p.pizza_size
ORDER BY revenue DESC;
```

f. **Which pizzas are underperforming and may need to be reconsidered?**
```sql
WITH pizza_performance AS 
  (
    SELECT
        p.pizza_name,
        ROUND(SUM(od.quantity)::numeric,2) AS total_quantity_sold,
        ROUND(SUM(od.total_price)::numeric,2) AS total_revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY p.pizza_name
  )
SELECT *
FROM pizza_performance
WHERE total_revenue < 
  (
    SELECT AVG(total_revenue) FROM pizza_performance
  )
ORDER BY total_revenue;
```

g. **Which ingredients are most common in top-selling and high-revenue pizzas?**
```sql
WITH pizza_revenue AS 
(
    SELECT
        p.pizza_id,
        unnest(string_to_array(p.pizza_ingredients, ', ')) AS ingredient,
        SUM(od.total_price) AS revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY p.pizza_id, ingredient
),
high_revenue_pizzas AS (
    SELECT *
    FROM pizza_revenue
    WHERE revenue >= (
        SELECT AVG(revenue) FROM pizza_revenue
    )
)
SELECT
    ingredient,
    COUNT(*) AS appearance_count
FROM high_revenue_pizzas
GROUP BY ingredient
ORDER BY appearance_count DESC;
```

h. **Which hours of the day generate the most pizza orders, and how does customer demand differ between peak and off-peak periods?**
```sql
WITH hourly_orders AS 
(
    SELECT
        EXTRACT(HOUR FROM o.order_time)::int AS order_hour,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    GROUP BY order_hour
),
hourly_classification AS (
    SELECT
        order_hour,
        total_orders,
        CASE
            WHEN total_orders >= (
                SELECT AVG(total_orders) FROM hourly_orders
            ) THEN 'Peak'
            ELSE 'Off-Peak'
        END AS demand_period
    FROM hourly_orders
)
SELECT *
FROM hourly_classification
ORDER BY total_orders DESC;
```

i. **Which days of the week consistently generate the highest and lowest revenue?**
```sql
SELECT
    TO_CHAR(o.order_date, 'Day') AS day_of_week,
    ROUND(SUM(od.total_price)::numeric,2) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY day_of_week
ORDER BY total_revenue DESC;
```

j. **Are there seasonal patterns in monthly sales trends?**
```sql
SELECT
    TO_CHAR(o.order_date, 'Month') AS month_name,
    ROUND(SUM(od.total_price)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY month_name, EXTRACT(MONTH FROM o.order_date)
ORDER BY EXTRACT(MONTH FROM o.order_date);
```

k. **Which pizzas should be prioritized for marketing and promotions based on a combination of high revenue and consistent order frequency?**
```sql
WITH pizza_metrics AS (
    SELECT
        p.pizza_name,
        SUM(od.total_price) AS revenue,
        COUNT(DISTINCT od.order_id) AS order_frequency
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY p.pizza_name
),
ranked_pizzas AS (
    SELECT
        pizza_name,
        revenue,
        order_frequency,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY order_frequency DESC) AS frequency_rank
    FROM pizza_metrics
)
SELECT *
FROM ranked_pizzas
WHERE revenue_rank <= 10
  AND frequency_rank <= 10
ORDER BY revenue_rank, frequency_rank;
```

l. **How many orders fall into low, medium, and high-value segments, and what does this reveal about customer spending patterns?**
```sql
WITH order_totals AS (
    SELECT
        order_id,
        SUM(total_price) AS order_value
    FROM order_details
    GROUP BY order_id
)
SELECT
    CASE
        WHEN order_value < 20 THEN 'Low Value'
        WHEN order_value BETWEEN 20 AND 40 THEN 'Medium Value'
        ELSE 'High Value'
    END AS order_segment,
    COUNT(*) AS number_of_orders
FROM order_totals
GROUP BY order_segment;
```

## Findings and Business Implications
1. Total revenue for the period was $1,635,720.10, with an average order value of $76.61.
   
- Customers tend to order multiple items per transaction, which presents opportunities to increase revenue through bundle deals, upselling, or promotional offers that encourage higher spend per order.
  
2. A small number of pizzas dominate revenue. The top 8 pizzas alone contribute over 35% of total revenue, with “The Thai Chicken Pizza” generating 5.31% of total sales.
   
- Focusing marketing and promotions on these top performers can maximize returns, while lower-performing pizzas may need re-evaluation or strategic adjustments to improve their contribution.
  
3. The top 10 pizzas collectively generate a significant portion of revenue, with “The Thai Chicken Pizza” leading at $86,868.50 and “The Sicilian Pizza” at $61,881.00.

- These best-sellers should be prioritized in menu placement, marketing campaigns, and inventory management to maintain steady revenue flow.

4. Finding:
The “Classic” category leads in total units sold with 29,776, followed by “Supreme” (23,974), “Veggie” (23,298), and “Chicken” (22,100).

- Classic pizzas are clearly the most popular among customers, suggesting they should remain a focal point for promotions and inventory planning. Other categories like Supreme, Veggie, and Chicken still contribute significantly and can be targeted with marketing campaigns to boost sales further.

5. Large pizzas generate the most revenue across categories. Veggie L leads with $208,405.40, followed closely by Chicken L at $204,678.00. Small and extra-large sizes contribute much less.

- Promotions, production, and inventory planning should focus on large pizzas, while monitoring demand for smaller sizes to ensure the menu caters to different customer preferences.

6. Some pizzas, like “The Brie Carre Pizza” and “The Green Garden Pizza,” generate lower revenue despite reasonable quantities sold.

- Evaluate whether these pizzas should remain on the menu, be re-marketed, or bundled to improve performance.

7. Garlic, tomatoes, and red onions appear most frequently in high-revenue pizzas, while other ingredients like mozzarella, mushrooms, and pepperoni are less common.

- These ingredients reflect strong customer preferences and can guide procurement, recipe development, and promotional strategies.

8. Orders peak between 12 PM–2 PM and 5 PM–8 PM, while off-peak hours (9–11 AM and 10 PM onwards) see minimal activity.

- Staffing, kitchen preparation, and marketing efforts should align with peak hours to optimize operations, reduce wait times, and improve customer experience.

9. Friday ($272,147.80) is the highest revenue day, followed by Thursday and Saturday. Sunday ($198,407.00) consistently generates the lowest revenue.

- Promotional campaigns can target low-performing days like Sunday, while high-volume days may require additional staffing or preparation to meet demand.

10. Monthly sales show consistent activity, with slight peaks in March, May, and July. The holiday periods (January, June, and December) had lower sales.

- These seasonal patterns suggest opportunities for targeted campaigns and inventory planning during high-demand periods to maximize sales.

11. “The Classic Deluxe Pizza” and “The Hawaiian Pizza” are ordered most frequently, while “The Thai Chicken Pizza” and “The Barbecue Chicken Pizza” generate the highest revenue.

- Pizzas that perform well both in revenue and frequency should be prioritized for marketing, bundle deals, and featured promotions to drive consistent revenue growth.

## Conclusion

This analysis highlights clear patterns in pizza sales, showing that revenue is concentrated in a small number of high-performing pizzas and large pizza sizes dominate sales. Peak hours, top-performing days, and seasonal trends provide actionable insights for staffing, promotions, and inventory planning. By leveraging these findings, the business can make data-driven decisions to increase revenue, optimize menu offerings, and better meet customer demand

## Getting Started

- Clone the Repository: Clone this project from GitHub to your local machine.
- Set Up the Database: Run the SQL scripts in Pizza_Sales Project SQL.db to create the database and populate it with the pizza sales data.
- Run the Analysis Queries: Use the queries provided in Pizza_sales_query to reproduce the analysis and insights.
- Explore and Experiment: Feel free to tweak the queries or create new ones to explore other trends, answer additional business questions, or test your own hypotheses.

## Author - Fiyinfoluwa Olusuyi

As part of my portfolio, this project demonstrates my ability to use SQL to analyze data and generate actionable insights. I’d love to hear your thoughts, feedback, or discuss potential collaboration opportunities.

Stay Updated and Join the Community
For more content on SQL, data analysis, and other data-related topics, make sure to follow me on social media and join our community:

LinkedIn:[Connect with me professionally](https://www.linkedin.com/in/yourprofile)

I look forward to connecting with you!
