use "RFM Project"

------------------------------------- Data Cleaning ---------------------------------

-- Display dataset
select * from sales_data;

-- Check for Nulls
select
	count(*) as Nulls
from sales_data
where OrderNumber is null;

-- Show Duplicate Rows
select * from (
		select	*,
				row_number() over (partition by OrderNumber order by OrderNumber) as rn
		from sales_data) x
where x.rn > 1;

-- Delete Duplicates
delete from sales_data
where OrderNumber in (
		select OrderNumber from (
			select	*,
					row_number() over (partition by OrderNumber order by OrderNumber) as rn
			from sales_data) x
		where x.rn > 1);

------------------------------------- Data Exploration -------------------------

-- Total Orders
select
	count(distinct(OrderNumber))  as total_orders
from sales_data;

-- Total Customers
select
	count(distinct(_CustomerID))  as total_customers
from sales_data;

-- Total Revenue and Total Profit
select
	format(round(sum([Unit Price] * (1 - [Discount Applied]) * [Order Quantity]), 0), 'C') as total_revenue,
	format(round(sum(([Unit Price] - [Unit Cost]) * (1 - [Discount Applied]) * [Order Quantity]), 0), 'C') as total_profit
from sales_data;

-- Minimum and Maximum Order Dates
select  
	min(OrderDate) as min_order_date,
	max(OrderDate) as max_order_date
from sales_data;

-- Total Products
select
	count(distinct(_ProductID)) as total_products
from sales_data;

-- Sales Channels
select
	distinct "Sales Channel"
from sales_data;

---------------------------------- RFM Calculations ----------------------------

-- Create a View using a CTE to get RFM Scores
create view  VWrfm_scores as 
	with CTErfm_scores as (
			select
				_CustomerID as customer_id,
				--max(OrderDate) most_recent_purchase_date,
				datediff(day, max(OrderDate), getdate()) as recency_score,
				count(OrderNumber) as frequency_score,
				--cast(sum(([Unit Price] - [Unit Cost]) * (1 - [Discount Applied]) * [Order Quantity]) as decimal(16, 0)) as monetary_score
				--cast(sum([Unit Price] * (1 - [Discount Applied]) * [Order Quantity]) as decimal(16, 1)) as monetary_score
				format(round(sum(([Unit Price] - [Unit Cost]) * (1 - [Discount Applied]) * [Order Quantity]),2), 'N') as monetary_score
			from sales_data
			group by _CustomerID
	)
		select
			customer_id,
			recency_score,
			frequency_score,
			monetary_score,
			ntile(5) over (order by recency_score desc) as R,
			ntile(5) over (order by frequency_score asc) as F,
			ntile(5) over (order by monetary_score asc) as M
		from CTErfm_scores;

-- Display View VWrfm_scores
select * from VWrfm_scores;

-- RFM Customer Segmentation
create view VWrfm_segments as
	with CTEavg_rfm_scores as (
			select
				customer_id,
				concat_ws('_', R, F, M) as rfm_cell,
				cast((cast(R as float) + F + M)/3 as decimal(16,2)) as avg_rfm_scores
			from VWrfm_scores
			)
			select	*,
					case
						when avg_rfm_scores >= 4.5 then 'most valuable'
						when avg_rfm_scores >= 3.5 then 'valuable'
						when avg_rfm_scores >= 2.5 then 'average'
						when avg_rfm_scores >= 1.5 then 'below average'
						when avg_rfm_scores < 1.5 then 'at risk'
					end as rfm_segment
			from CTEavg_rfm_scores;

-- Display View VWrfm_segments
select * from VWrfm_segments;

---------------------------------------- Queries for Insights ---------------------------------------------------------

-- Get customer counts and percentage for different categories of segmentation
select 
	rfm_segment,
	count(customer_id)  as customer_count,
	format(count(customer_id) / (select cast(count(customer_id) as decimal) from VWrfm_segments), 'P') as customer_percent
	--count(customer_id) / (select count(distinct customer_id) from VWrfm_segments)
from VWrfm_segments
group by rfm_segment
order by customer_count desc;

-- Most Recent customers with high Frequency and Monetary Scores.
select *
from VWrfm_scores
where R>=4 and F>=4 and M >=4
order by R desc;

-- Most Profitable Customers
select *
from VWrfm_scores
where M=5
order by monetary_score desc;
