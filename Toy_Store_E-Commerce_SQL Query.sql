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

-- End of the Project.


Select * from website_sessions
order_item_refunds order_items orders products website_pageviews website_sessions

-- Table Relationships

orders = order_id, website_session_id, user_id, primary_product_id
order_items = order_item_id, order_id, product_id
order_item_refunds = Order_item_refund_id, order_item_id, order_id
products = product_id
website_pageviews = website_pageview_id, website_session_id
website_sessions = website_session_id, user_id


