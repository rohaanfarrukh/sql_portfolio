use sql_portfolio;


SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

-- show the first 10 customers
SELECT * FROM customers LIMIT 10;

-- count customers per country
SELECT country, COUNT(*) AS total_customers
FROM customers
GROUP BY country;

-- total numbers of orders
SELECT COUNT(*) AS total_orders FROM orders;

-- find top 10 biggest orders
SELECT * 
FROM orders
ORDER BY order_amount DESC
LIMIT 10;

-- get all orders with customer names
SELECT 
    o.order_id,
    o.order_date,
    o.order_amount,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LIMIT 20;

-- customers lifetime value(total spent per customer)

select
	c.customer_id,
    concat(c.first_name, ' ', c.last_name) as customer_name,
    count(o.order_id) as num_orders,
    round(coalesce(sum(o.order_amount), 0),2) as total_spent,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date
from customers c
left join orders o on c.customer_id = o.customer_id
group by c.customer_id
order by total_spent desc
limit 50;

-- first and last order date per customer(useful for retention)
select
	customer_id,
    min(order_date) as first_order,
    max(order_date) as last_order,
    datediff(max(order_date), min(order_date)) as days_between_first_order
from orders
group by customer_id
order by first_order;

-- repeat purchase rate
with orders_per_customer as(
	select customer_id, count(*) as order_count
    from orders
    group by customer_id
)
select 
	sum(case when order_count > 1 then 1 else 0 end) *100/ count(*) as pct_repeat_customers,
    avg(order_count) as avg_orders_per_customer
from orders_per_customer;

-- orders per month and month over month growth
with monthly as(
	select date_format(order_date, '%y-%m') as ym,
		sum(order_amount) as revenue
	from orders
    group by ym
)
select
	ym,
    round(revenue,2) as revenue,
    round(lag(revenue) over (order by ym),2) as prev_revenue,
    round( case when lag(revenue) over (order by ym) is null then null
				when lag(revenue) over (order by ym) = 0 then null
                else (revenue - lag(revenue) over (order by ym)) / lag(revenue) over (order by ym) * 100 end,2) as pct_mom_change
from monthly
order by ym;

-- cohort analysis
with first_order as(
	select customer_id, min(order_date) as first_order_date
    from orders
    group by customer_id
),
cohort as(
	select
		c.customer_id,
        date_format(c.created_at, '%Y-%m') as cohort_month,
        date_format(o.order_date, '%Y-%m') as order_month
	from customers c
    left join orders o on c.customer_id = o.customer_id
)
select
	cohort_month,
    order_month,
    count(distinct customer_id) as customers_in_month
from cohort
group by cohort_month, order_month
order by cohort_month, order_month
limit 200;

-- RFm analysis

set @today := curdate();

with cust_metrics as (
	select
		c.customer_id,
        concat(c.first_name, ' ', c.last_name) as name,
        max(o.order_date) as last_order_date,
        count(o.order_id) as frequency,
        coalesce(sum(o.order_amount),0) as monetary
	from customers c
    left join orders o on c.customer_id = o.customer_id
    group by c.customer_id
),
rfm as(
	select *,
		datediff(@today, last_order_date) as recency_days
	from cust_metrics
)
select
	customer_id,
    name,
    recency_days,
    frequency,
    monetary,
    ntile(3) over (order by recency_days desc) as recency_score,
    ntile(3) over (order by frequency) as frequency_score,
    ntile(3) over (order by monetary) as monetary_score
from rfm
order by monetary desc
limit 200;

-- customer lifetime value funnel
with orders_aug as(
	select
		o.*,
        date_format(o.order_date, '%Y-%m') as order_month,
        date_format(c.created_at, '%Y-%m') as cohort_month
	from orders o
    join customers c on o.customer_id = c.customer_id
),
monthly_cohort as (
	select
		cohort_month,
        order_month,
        sum(order_amount) as revenue
	from orders_aug
    group by cohort_month, order_month
)
select
	cohort_month,
    order_month,
    round(revenue,2) as revenue,
    round(sum(revenue) over (partition by cohort_month order by order_month rows between unbounded preceding and current row),2) as cumulative_revenue
from monthly_cohort
order by cohort_month, order_month;

-- product level revenue and top products per customer
select
	product_name,
    sum(quantity * price) as total_revenue,
    sum(quantity) as units_sold
from order_items
group by product_name
order by total_revenue desc
limit 20;

with cust_product_spend as(
	select oi.*, o.customer_id,
		sum(oi.quantity * oi.price) over (partition by o.customer_id, oi.product_name) as prod_spend
	from order_items oi
    join orders o on oi.order_id = o.order_id
)
select distinct customer_id, product_name, prod_spend
from cust_product_spend
where (customer_id, prod_spend) in(
	select customer_id, max(prod_spend)
    from cust_product_spend
    group by customer_id
)
order by prod_spend desc
limit 100;

-- rolling 3-month revenue
with monthly as(
	select date_format(order_date, '%Y-%m') as ym, sum(order_amount) as revenue
    from orders
    group by ym
)
select
	ym,
    revenue,
    round(avg(revenue) over (order by ym rows between 2 preceding and current row),2) as rolling_3mo_avg
from monthly
order by ym;