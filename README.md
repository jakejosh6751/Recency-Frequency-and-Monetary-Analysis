# Recency, Frequency, and Monetary (RFM) Analysis
![](rfm_banner.jpg)

### Project Overview:
This data analysis project seeks to segment customers base on their latest transaction dates, the rate of transactions, and their profitability to the business. The major concern is to gain actionable insights into the customer base to know the most profitable, loyal and most recent customers to enhance marketing and customer relationship strategies.
### Data Source:
The dataset from [data.world](https://data.world/dataman-udit/us-regional-sales-data) is an excel file for US regional sales for orders between year 2018 and 2020. It has 7,991 entries and 16 features that include Order Number, Sales Channel, Order Date, Customer ID, Order Quantity, Discount Applied, Unit Price, and Unit Cost.
### Tools and Skills:
Microsoft SQL Server Management Studio, String, Date, Math/Numeric, Aggregate & Window Functions, Subqueries, CTEs, Views.
### Data Cleaning:
```sql
-- Preview dataset
select * from sales_data;
```
![dataset](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/da7e2ac4-a825-4aff-aa07-433427367193)
```sql
-- Null Values = 0
select
	count(*) as Nulls
from sales_data
where OrderNumber is null;

-- No Duplicate Rows
select * from (
		select	*,
				row_number() over (partition by OrderNumber order by OrderNumber) as rn
		from sales_data) x
where x.rn > 1;

-- Delete Duplicates if they exist
delete from sales_data
where OrderNumber in (
		select OrderNumber from (
			select	*,
					row_number() over (partition by OrderNumber order by OrderNumber) as rn
			from sales_data) x
		where x.rn > 1);
```
### Data Exploration:
```sql
-- Total Orders = 7991
select
	count(distinct(OrderNumber))  as total_orders
from sales_data;

-- Total Customers = 50
select
	count(distinct(_CustomerID))  as total_customers
from sales_data;

-- Total Revenue = $73,143,380 and Total Profit = $27,291,402
select
	format(round(sum([Unit Price] * (1 - [Discount Applied]) * [Order Quantity]), 0), 'C') as total_revenue,
	format(round(sum(([Unit Price] - [Unit Cost]) * (1 - [Discount Applied]) * [Order Quantity]), 0), 'C') as total_profit
from sales_data;

-- Minimum Oder Date = 2018-05-31 and Maximum Order Date = 2020-12-30
select  
	min(OrderDate) as min_order_date,
	max(OrderDate) as max_order_date
from sales_data;

-- Total Number of Distinct Products = 47
select
	count(distinct(_ProductID)) as total_products
from sales_data;

-- Sales Channels ---> -- Online, Wholesale, Distributor, In-Store
select
	distinct "Sales Channel"
from sales_data;
```
### RFM Analysis:
```sql
-- Create a View to get RFM Scores
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

--Show View VWrfm_scores
select * from VWrfm_scores;
```
![VWrfm_scores](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/61b64b67-8597-4251-b52b-dd0150d89e43)

```sql
-- Create a View for RFM Customer Segments
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

-- Show View VWrfm_segments
select * from VWrfm_segments;
```
![VWrfm_segments](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/76b7cba6-a548-490b-99a8-9e4c757a23f5)

```sql
-- Get customer counts and percentages for different categories of segmentation
select 
	rfm_segment,
	count(customer_id)  as customer_count,
	format(count(customer_id) / (select cast(count(customer_id) as decimal) from VWrfm_segments), 'P') as customer_percent
	--count(customer_id) / (select count(distinct customer_id) from VWrfm_segments)
from VWrfm_segments
group by rfm_segment
order by customer_count desc;
```
![Get customer counts and percentage for different categories of segmentation](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/e3e5fb90-5053-44fd-b9dc-d9117a40a052)

```sql
-- Most Recent customers with high Frequency and Monetary Scores
select *
from VWrfm_scores
where R>=4 and F>=4 and M >=4
order by R desc;
```
![Most Recent customers with high Frequency and Monetary Scores](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/ce3dbbc3-bb7d-4477-9150-34593b676e68)

```sql
-- Most Profitable Customers
select *
from VWrfm_scores
where M=5
order by monetary_score desc;
```
![Most Profitable Customers](https://github.com/jakejosh6751/Recency-Frequency-and-Monetary-Analysis/assets/148710647/ad85bf46-c639-4ae4-91b6-66cb6ba2c396)

## Insights:
1. 70% of our customers make up the average, valuable and most valuable rfm categories. 8% are considered 'at risk' customers.
2. We have 7 highly esteemed customers with Recency, Frequency, and Monetary designation of 4 and 5. These customers should never be lost.
3. Our most profitable customers with Monetary designation of 5 happen to be the most loyal (frequent) with F designation between 3 and 5.
