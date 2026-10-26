-- Create Tables & Import Dataset
Create Table products (
	product_id Int PRIMARY KEY,
	created_at Timestamp NOT NULL,
	product_name Varchar (50)
);
Create Table website_sessions (
	website_session_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    user_id BIGINT NOT NULL,
    is_repeat_session SMALLINT NOT NULL DEFAULT 0,
    utm_source VARCHAR(50),
    utm_campaign VARCHAR(50),
    utm_content VARCHAR(50),
    device_type VARCHAR(20),
    http_referer VARCHAR(255)
);
Create Table order_items (
	order_item_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    is_primary_item SMALLINT NOT NULL DEFAULT 1,
    price_usd DECIMAL(10, 2) NOT NULL,
    cogs_usd DECIMAL(10, 2) NOT NULL
);
Create Table website_pageviews (
	website_pageview_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    website_session_id BIGINT NOT NULL REFERENCES website_sessions(website_session_id),
    pageview_url VARCHAR(255) NOT NULL
);
Create Table orders (
	order_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
	website_session_id BIGINT NOT NULL REFERENCES website_sessions(website_session_id),
    user_id BIGINT NOT NULL,
    primary_product_id BIGINT NOT NULL REFERENCES products(product_id),
    items_purchased INTEGER NOT NULL CHECK (items_purchased > 0),
    price_usd NUMERIC(10, 2) NOT NULL CHECK (price_usd >= 0),
    cogs_usd NUMERIC(10, 2) NOT NULL CHECK (cogs_usd >= 0)
);
Create Table order_item_refunds	(
	order_item_refund_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    order_item_id BIGINT NOT NULL REFERENCES order_items(order_item_id),
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    refund_amount_usd NUMERIC(10, 2) NOT NULL CHECK (refund_amount_usd >= 0)
);

-- Data Cleaning

Select * from order_item_refunds
where
	order_item_refund_id is null
	or
	created_at is null
	or
	order_item_id is null
	or
	order_id is null
	or
	refund_amount_usd is null

Select * from order_items
where
	order_item_id is null
	or
	created_at is null
	or
	order_id is null
	or
	product_id is null
	or
	is_primary_item is null
	or
	price_usd is null
	or
	cogs_usd is null

Select * from orders
where
	order_id is null
	or
	created_at is null
	or
	website_session_id is null
	or
	user_id is null
	or
	primary_product_id is null
	or
	items_purchased is null
	or
	price_usd is null

Select * from order_items
where
	order_item_id is null
	or
	created_at is null
	or
	order_id is null
	or
	product_id is null
	or
	is_primary_item is null
	or
	price_usd is null
	or
	cogs_usd is null

Select * from website_pageviews
where
	website_pageview_id is null
	or
	created_at is null
	or
	website_session_id is null
	or
	pageview_url is null

Select * from website_sessions
where
	website_session_id is null
	or
	created_at is null
	or
	user_id is null
	or
	is_repeat_session is null
	or
	utm_source is null
	or
	utm_campaign is null
	or
	utm_content is null
	or
	device_type is null
	or
	http_referer is null

-- Data Exploaration

-- Q1. How many records are in each table?

select count(*) from order_item_refunds;
select count(*) from order_items;
select count(*) from orders;
select count(*) from products;
select count(*) from website_pageviews;
select count(*) from website_sessions;

-- Q2. What is the minimum and maximum date in each table?

Select 
	min(created_at) as First_Date,
	max(created_at) as Last_Date
from order_item_refunds

union all

Select 
	min(created_at) as First_Date,
	max(created_at) as Last_Date
from order_items

union all

Select 
	min(created_at) as First_Date,
	max(created_at) as Last_Date
from orders

union all

Select 
	min(created_at) as First_Date,
	max(created_at) as Last_Date
from products;

-- Q3. How many unique users are there?

Select count(distinct(user_id))
from orders;

Select count(distinct(user_id))
from website_sessions;

-- Q4. How many unique orders are there?

Select count(distinct(order_id))
from orders;

Select count(distinct(order_id))
from order_item_refunds;

Select count(distinct(order_id))
from order_items;

-- Q5. How many products are there?

Select count(distinct(product_id))
from products;

-- Q6. How many orders were placed each month?

Select
	DATE_TRUNC('month', created_at) as Month,
	count(order_id) as Total_Orders
from orders
group by month
order by month;

-- Q7. What is the total revenue?

Select
	sum(price_usd) as Total_Revenue
from orders;

-- Q8. What is the average order value?

Select
	avg(price_usd) as Average_Order
from orders;

-- Q9. What is the minimum and maximum order value?

Select 
	min(price_usd) as Minimum_Order_Value,
	max(price_usd) as Maximum_Order_Value
from orders;

-- Q10. How many items are purchased per order on average?

Select 
	count(items_purchased) as Purchased_Items,
	avg(items_purchased) as Avg_Item_Per_Order
from orders;

-- Q11. How many orders came from repeat vs new sessions?

Select
	ws.is_repeat_session,
	count(distinct(o.order_id)) as Total_Unique_Orders
from orders o
inner join website_sessions ws
	on o.website_session_id = ws.website_session_id
group by ws.is_repeat_session;

-- Q12. What is the revenue generated by repeat vs non-repeat sessions?

Select
	ws.is_repeat_session,
	count(distinct(o.order_id)) as Total_Orders,
	sum(o.price_usd) as Total_Revenue,
	avg(o.price_usd) as Average_Order_Value
from orders o
inner join website_sessions ws
	on o.website_session_id = ws.website_session_id
group by ws.is_repeat_session;


-- Data Analysis & Business Key Problems and Solutions

-- Q1, Which customers generated the highest total revenue,and how many orders did each customer place?

Select
	user_id,
	sum(price_usd) as Total_Revenue,
	count(order_id) as Total_Orders
from orders
group by user_id
order by Total_Revenue desc;

-- Q2, Which customers have spent more than the average customer revenue?

Select
	user_id,
	sum(price_usd) as Total_Revenue
from orders
group by user_id
having sum(price_usd) >
(
	Select avg (Customer_Revenue)
	from
	(
		Select
			user_id,
			sum(price_usd) as Customer_Revenue
		from orders
		group by user_id
	) as Customer_Total
)
order by Total_Revenue desc;

-- Q3, Which products generated the highest:
	-- Revenue 	
	-- Profit
	-- Number of Orders

select
    p.product_id,
    p.product_name,
    count(distinct(oi.order_id)) as total_orders,
    sum(oi.price_usd) as total_revenue,
    sum(oi.price_usd - oi.cogs_usd) as total_profit
from products p
inner join order_items oi
    on p.product_id = oi.product_id
group by p.product_id, p.product_name
order by total_revenue desc;

-- Q4, Find products where revenue is above the average product revenue AND they have refunds.

select
    p.product_id,
    p.product_name,
    sum(oi.price_usd) as overall_revenue
from products p
inner join order_items oi
    on p.product_id = oi.product_id
inner join order_item_refunds r
    on oi.order_item_id = r.order_item_id
group by p.product_id, p.product_name
having sum(oi.price_usd) >
(
    select avg (total_revenue)
    from
    (
        select
            oi.product_id,
            sum(oi.price_usd) as total_revenue
        from order_items oi
        group by oi.product_id
    ) as average_revenue
)
order by overall_revenue desc;

-- Q5, Which utm_source generates:
	-- Most Seesions
	-- Most Orders
	-- Highest Revenue
	-- Highest Average

select
	ws.utm_source,
	count(distinct(ws.website_session_id)) as Total_Sessions,
	count(distinct(o.order_id)) as Total_Orders,
	sum(o.price_usd) as Total_Revenue,
	avg(o.price_usd) as Average_Revenue	
from orders o
left join website_sessions ws
	on o.website_session_id = ws.website_session_id
group by ws.utm_source
order by Total_Revenue desc, Average_Revenue desc;
	
-- Q6, Which device type has the highest session-to-order conversion rate?

Select
	ws.device_type,
	count(distinct (ws.website_session_id)) as Total_Sessions,
	count(distinct (o.order_id)) as Total_Orders,
	count(distinct (o.order_id)) * 100 / count(distinct (ws.website_session_id)) as Conversion_Rate
from website_sessions ws
left join orders o
	on o.user_id = ws.user_id
group by ws.device_type
order by Conversion_Rate desc;

-- Q7, Compare repeat sessions vs non-repeat sessions based on:
	-- Sessions
	-- Orders
	-- Revenue
	-- Conversion Rate

select
    ws.is_repeat_session,
    count(distinct ws.website_session_id) as total_sessions,
    count(distinct o.order_id) as total_orders,
    coalesce(sum(o.price_usd), 0) as total_revenue,
    count(distinct o.order_id) * 100.0
        / nullif(count(distinct ws.website_session_id), 0)
        as conversion_rate
from website_sessions ws
left join orders o
    on ws.website_session_id = o.website_session_id
group by ws.is_repeat_session
ORDER BY ws.is_repeat_session;

-- Q8, Find each customer's first order date and first order amount.

with Customer_Order as
(
Select
	user_id,
	created_at,
	price_usd,
	row_number() over(
	partition by user_id
	order by created_at asc
	) as Order_Rank
from orders
)

Select
	user_id,
	created_at as First_Date,
	price_usd as First_Order
from Customer_Order
where Order_Rank = 10;

-- Q9, Find the top 2 products by revenue within each product category.

with Product_Table as
(
select
	p.product_id,
	p.product_name,
	sum(oi.price_usd) as Total_Revenue,
	row_number() over (
	partition by p.product_name
	order by sum(oi.price_usd) desc
	) as Product_Rank
from order_items oi
inner join products p
	on oi.product_id = p.product_id
group by p.product_id, p.product_name
)

select *
from Product_Table
where Product_Rank <= 2
order by Product_Rank;

-- Q10, For every customer, show:
	-- user_id
	-- order_date
	-- order_amount
	-- previous_order_amount
	-- difference_from_previous_order

with Order_Table as
(
Select
	user_id,
	created_at as Order_Date,
	price_usd as Order_Amount,
	lag(price_usd) over (
	partition by user_id
	order by created_at 
	) as Previous_Order_Amount
from orders
)

Select
	user_id,
	Order_Date,
	Order_Amount,
	Previous_Order_Amount,
	Order_Amount - Previous_Order_Amount as Order_Difference	
from Order_Table
order by user_id, Order_Date;

-- Q11, Customer Segmentation: Classify customers

Select 
	user_id,
	sum(price_usd) as Revenue,
	case
		when sum(price_usd) >= 1000000 then 'Preimum'
		when sum(price_usd) >= 100000 then 'High'
		when sum(price_usd) >= 50000 then 'Medium'
		else 'Low'
	end as Customer_Classification
from orders
group by user_id
order by Revenue desc;

-- Q12, Rank customers by revenue:

Select 
	user_id,
	sum(price_usd) as Revenue,
	rank() over(
	order by sum(price_usd) desc
	) as Customer_Rank
from orders
group by user_id;

or 

Select 
	user_id,
	sum(price_usd) as Revenue,
	dense_rank() over(
	order by sum(price_usd) desc
	) as Customer_Rank
from orders
group by user_id;

-- Q13, Show cumulative revenue over time.

Select
	created_at as Date,
	sum(price_usd) as Daily_Revenue,
	sum(sum(price_usd)) over (
	order by created_at
	) as Running_Revenue
from orders
group by created_at
order by Date;

-- Q14, Find customers who:
	-- Have generated significant revenue
	-- But haven't purchased recently

Select
	user_id,
	sum(price_usd) as Total_Revenue,
	max(created_at) as Last_Purchase_Date
from orders
group by user_id
having sum(price_usd) > 500
	and max(created_at) < '2026-07-01'
order by Total_Revenue desc;

-- Q15, Calculate:
	-- Product
	-- Revenue
	-- Refund Amount
	-- Refund %

Select
	count(distinct oi.product_id) as Total_Products,
	sum(oi.price_usd) as Total_Revenue,
	sum(oir.refund_amount_usd) as Total_Refund_Amount,
	round(
		sum(oir.refund_amount_usd) * 100
		/ nullif(sum(oi.price_usd),0),2
	) as Refund_Percentage
from order_items oi
left join order_item_refunds oir
	on oi.order_item_id = oir.order_item_id;

-- Q16, Identify which marketing source ultimately generates the most revenue for each product.

select
    ws.utm_source,
    p.product_name,
    sum(oi.price_usd) as total_revenue
from orders o
inner join order_items oi
    on o.order_id = oi.order_id
inner join products p
    on oi.product_id = p.product_id
inner join website_sessions ws
    on o.website_session_id = ws.website_session_id
group by ws.utm_source, p.product_name
order by p.product_name, total_revenue desc;

-- Q17, Rank utm_source by total revenue and show:

select
	ws.utm_source,
	sum(o.price_usd) as Total_Revenue,
	rank() over(
	partition by ws.utm_source
	order by sum(o.price_usd)
	) as Rank_UTM_Source
from website_sessions ws
inner join orders o
	on ws.user_id = o.user_id
group by ws.utm_source
order by Total_Revenue desc;

	
-- End of the Project.

-- Table Relationships

orders = order_id, website_session_id, user_id, primary_product_id
order_items = order_item_id, order_id, product_id
order_item_refunds = Order_item_refund_id, order_item_id, order_id
products = product_id
website_sessions = website_session_id, user_id
website_pageviews = website_pageview_id, website_session_id

