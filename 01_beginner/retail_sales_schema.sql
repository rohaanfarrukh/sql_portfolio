-- Create schema 
Create database sql_portfolio;
use sql_portfolio;

create table retail_sales (
	order_id varchar(10),
    order_date date,
    product varchar(100),
    category varchar(50),
    price decimal(10,2),
    quantity int,
    region varchar(20)
);

/* ======================================
	Project: Retail Sales Analysis
	Author: Rohaan Farrukh
	Tool: MYSQL
======================================*/

-- 1 Sanity Check
-- Validate row counts and data range
Select 
	Count(*) as total_rows,
    count(distinct order_id) as total_orders,
    min(order_date) as first_order,
    max(order_date) as last_order
from retail_sales;

-- 2. Total Revenue
-- Core business KPI
Select 
	Round(sum(price * quantity),2) as total_revenue
from retail_sales;

-- 3. Revenue by Category
-- Shows which product categories generate the most revenue
select 
	category,
    round(sum(price * quantity)) as revenue
from retail_sales
group by category
order by revenue desc;

-- 4. Top 5 products by units sold
-- Find highest-selling products by volume
select 
	product,
    sum(quantity) as units_sold
from retail_sales
group by product
order by units_sold desc
limit 5;

-- 5. Average order value (AOV)
-- Measure average revenue per order
Select 
	Round(
		Sum(price * quantity) / count(distinct order_id),2
	) as average_order_value
from retail_sales;

-- 6. Revenue by region
-- Analyze geographic sales performance
Select 
	region,
    Round(sum(price * quantity),2) as revenue
from retail_sales
group by region
order by revenue desc;

-- 7. Monthly revenue trend
-- track revenue changes over time
select
	date_format(order_date, '%Y-%m') as month,
    round(sum(price * quantity),2) as revenue
from retail_sales
group by month
order by revenue desc;

-- 8. High performing products
-- identify products generating at least $500 in revenue
select
	product,
    round(sum(price * quantity),2) as revenue
from retail_sales
group by product
having revenue >= 500
order by revenue desc;
