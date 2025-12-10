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

select count(*) from retail_sales;
select * from retail_sales;
Select 
	Count(*) as total_rows,
    count(distinct order_id) as total_orders,
    min(order_date) as first_order,
    max(order_date) as last_order
from retail_sales;

Select 
	Round(sum(price * quantity),2) as total_revenue
from retail_sales;

select 
	category,
    round(sum(price * quantity)) as revenue
from retail_sales
group by category
order by revenue desc;

select 
	product,
    sum(quantity) as units_sold
from retail_sales
group by product
order by units_sold desc
limit 5;

Select 
	Round(
		Sum(price * quantity) / count(distinct order_id),2
	) as average_order_value
from retail_sales;

Select 
	region,
    Round(sum(price * quantity),2) as revenue
from retail_sales
group by region
order by revenue desc;

select
	date_format(order_date, '%Y-%m') as month,
    round(sum(price * quantity),2) as revenue
from retail_sales
group by month
order by revenue desc;

select
	product,
    round(sum(price * quantity),2) as revenue
from retail_sales
group by product
having revenue >= 500
order by revenue desc;