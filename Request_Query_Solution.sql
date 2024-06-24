## 01. Request 1

select distinct market
from dim_customer
where region = "APAC"
and customer = "Atliq Exclusive";


## 02. Request 2

with u_prod_20_21 as (
select
count(distinct case when fiscal_year = 2020 then product_code END) as unique_products_20,
count(distinct case when fiscal_year = 2021 then product_code END) as unique_products_21
from fact_sales_monthly
)

select
	unique_products_20, unique_products_21,
    concat(round
		((unique_products_21 - unique_products_20)*100/unique_products_20), "%") as percent_chg
from u_prod_20_21;


## 03. Request 3

select
segment,
count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;


## 04. Request 4

with u_prod_20_21 as (
select
p.segment as segment,
count(distinct case when s.fiscal_year = 2020 then s.product_code END) as unique_products_20,
count(distinct case when s.fiscal_year = 2021 then s.product_code END) as unique_products_21
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
group by segment
)

select
	segment,
	unique_products_20, unique_products_21,
    (unique_products_21 - unique_products_20) as difference
from u_prod_20_21
group by segment
order by difference desc;


## 05. Request 5

select 
	p.product_code,
    p.product,
    concat('$', round(m.manufacturing_cost,2)) as manufacturing_cost
from fact_manufacturing_cost m
join dim_product p
on 
	p.product_code = m.product_code
where m.manufacturing_cost = 
(select max(manufacturing_cost) from fact_manufacturing_cost)
or
m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
order by m.manufacturing_cost desc;


## 06. Request 6

select 
	c.customer_code,
    c.customer,
    concat(round(avg(pre_invoice_discount_pct)*100,2), "%") as avg_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions d
on
	c.customer_code = d.customer_code
where d.fiscal_year = 2021
and market = "India"
group by c.customer, c.customer_code
order by avg(pre_invoice_discount_pct) desc limit 5;


## 07. Request 7

select 
	monthname(s.date) as Month_,
    year(s.date) as Year_,
    concat("$",round(sum(s.sold_quantity * g.gross_price)/1000000,2)) as _Gross_Sales_Amount
from fact_sales_monthly s
join fact_gross_price g
on 
	g.product_code = s.product_code
join dim_customer c
on
	c.customer_code = s.customer_code
where c.customer = "Atliq Exclusive"
group by Month_, Year_;


## 08. Request 8

select
	case
		when month(date) in (9,10,11) then "Q1"
        when month(date) in (12,1,2) then "Q2"
        when month(date) in (3,4,5) then "Q3"
        else "Q4"
	end as Quarter_,
    sum(sold_quantity) as Total_Sold_Quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter_
order by Total_Sold_Quantity desc;
        

## 09. Request 9

with cte_1 as (
select 
	c.channel as Channel_,
	round(sum(s.sold_quantity * g.gross_price)/1000000,2) as gross_sales_mln
from dim_customer c
join fact_sales_monthly s
on
	c.customer_code = s.customer_code
join fact_gross_price g
on
	g.product_code = s.product_code
where s.fiscal_year = 2021
group by c.channel
)

select 
Channel_, concat("$",gross_sales_mln) as Gross_Sales_Mln,
concat(round(gross_sales_mln/sum(gross_sales_mln)over()*100,2), "%") as Percentage_
from cte_1
group by Channel_
order by Percentage_ desc;


## 10. Request 10

with sold_products as(
select 
	p.division as Division_,
    p.product_code as Product_Code, p.product as Product,
    sum(sold_quantity) as Total_Sold_Quantity
from fact_sales_monthly s
inner join dim_product p
on
	s.product_code = p.product_code
where s.fiscal_year = 2021
group by p.division, p.product_code, p.product
order by Total_Sold_Quantity desc)
,
top_products_in_division as(
select 
	Division_,
    Product_Code, Product,
    Total_Sold_Quantity,
	dense_rank() over(partition by Division_ order by Total_Sold_Quantity desc) as Rank_
    from sold_products)
select *
from top_products_in_division where Rank_ <= 3;
        