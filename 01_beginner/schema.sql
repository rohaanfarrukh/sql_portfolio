CREATE DATABASE sql_portfolio;
USE sql_portfolio;

CREATE TABLE retail_sales (
  order_id VARCHAR(10),
  order_date DATE,
  product VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(10,2),
  quantity INT,
  region VARCHAR(20)
);
