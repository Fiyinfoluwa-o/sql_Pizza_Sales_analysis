-- Pizza Sales Analysis

-- 1. DATA CLEANING

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

-- 2. NORMALIZATION

-- Create Orders Table

DROP TABLE IF EXISTS orders;
CREATE TABLE orders 
  (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
  );

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

-- Insert data into order_details table

INSERT INTO order_details (order_id, pizza_id, quantity, unit_price, total_price)
SELECT order_id, 
		pizza_id, 
		quantity, 
		unit_price, 
		total_price
FROM pizza_sales_clean;

-- Validation 
SELECT COUNT(*) AS orphan_records
FROM order_details
WHERE order_id NOT IN (SELECT order_id FROM orders)
   OR pizza_id NOT IN (SELECT pizza_id FROM pizzas);


-- 3. DATA EXPLORATION

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


-- 4. BUSINESS PROBLEMS AND ANSWERS

-- a. What is the total revenue and average order value (AOV)?

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

-- b. How is revenue distributed across pizzas, and what percentage does each contribute?

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

-- c. Which pizzas generate the most revenue (Top 10 best sellers)?

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

-- d. How much of each pizza category was sold, and which categories are the top performers in terms of quantity sold?

SELECT
    pizza_category,
    SUM(quantity) AS total_units_sold
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pizza_category
ORDER BY total_units_sold DESC;

-- e. Which combinations of pizza category and size generate the most revenue?

SELECT
    p.pizza_category,
    p.pizza_size,
    ROUND(SUM(od.total_price)::numeric,2) AS revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_category, p.pizza_size
ORDER BY revenue DESC;

-- f. Which pizzas are underperforming and may need to be reconsidered?

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

-- g. Which ingredients are most common in top-selling and high-revenue pizzas?

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

-- h. Which hours of the day generate the most pizza orders, and how does customer demand differ between peak and off-peak periods?

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

-- i. Which days of the week consistently generate the highest and lowest revenue?

SELECT
    TO_CHAR(o.order_date, 'Day') AS day_of_week,
    ROUND(SUM(od.total_price)::numeric,2) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY day_of_week
ORDER BY total_revenue DESC;

-- j. Are there seasonal patterns in monthly sales trends?

SELECT
    TO_CHAR(o.order_date, 'Month') AS month_name,
    ROUND(SUM(od.total_price)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY month_name, EXTRACT(MONTH FROM o.order_date)
ORDER BY EXTRACT(MONTH FROM o.order_date);

-- k. Which pizzas should be prioritized for marketing and promotions based on a combination of high revenue and consistent order frequency?

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

-- l. How many orders fall into low, medium, and high-value segments, and what does this reveal about customer spending patterns?

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



