-- create table orders
-- (
--     order_id     int primary key,
--     order_date   date,
--     ship_mode    varchar(20),
--     segment      varchar(20),
--     country      varchar(20),
--     city         varchar(20),
--     state        varchar(20),
--     postal_code  varchar(20),
--     region       varchar(20),
--     category     varchar(20),
--     sub_category varchar(20),
--     product_id   varchar(50),
--     quantity     int,
--     discount     decimal(7, 2),
--     sale_price   decimal(7, 2),
--     profit       decimal(7, 2)
-- );

select * from orders;

select distinct(orders.category)
from orders;

select distinct(orders.sub_category)
from orders;


-- Finding top 10 highest revenue generating products
select product_id, sum(sale_price) as sales
from orders
group by product_id
order by sales DESC
LIMIT 10;

-- find top 10 highest selling products in each region
with cte as(
    select region, product_id, sum(sale_price) as sales
    from orders
    group by product_id, region
)
select * from(
    select *, row_number() over (partition by region order by sales DESC) as rn
    from cte) A
where rn <=5;

-- find month over month growth comparison for 2022 and 2023
with cte as (
    select date_part('year', order_date)  as year,
    date_part('month', order_date) as month,
    sum(sale_price) as sales
    from orders
    group by date_part('year', order_date), date_part('month', order_date)
    --order by date_part('year', order_date), date_part('month', order_date)
    )
select month,
       sum(case when year = 2022 then sales else 0 end) as sales_2022,
       sum(case when year = 2023 then sales else 0 end) as sales_2023
from cte
group by month
order by month;

-- for each category which month had the highest sales

with cte as(
    select category, date_part('month', order_date) as month, sum(sale_price) as total_sales
    from orders
    group by category, month
)
select * from(
    select *,
    row_number() over (partition by category order by total_sales desc) as rnk
    from cte
    ) a
where rnk = 1;

-- which sub-category has the highest sales compared to 2022 and 2023

with cte as (
    select date_part('year', order_date)  as year,
    sub_category,
    sum(sale_price) as sales
    from orders
    group by date_part('year', order_date), sub_category
    --order by date_part('year', order_date), date_part('month', order_date)
    ),
    cte2 as (
            select sub_category,
            sum(case when year = 2022 then sales else 0 end) as sales_2022,
            sum(case when year = 2023 then sales else 0 end) as sales_2023
            from cte
            group by sub_category)
select *,
       round((sales_2023-sales_2022)/sales_2022*100, 2) as total_diff,
       case when (sales_2023-sales_2022)/sales_2022*100 > 0 then 'Positive' else 'Negative' end as growth_status
 from cte2
order by total_diff DESC