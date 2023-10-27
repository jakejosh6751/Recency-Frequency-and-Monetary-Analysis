# Recency, Frequency, and Monetary (RFM) Analysis
## Tools and Skills:
Microsoft SQL Server Management Studio, String, Date, Math/Numeric, Aggregate & Window Functions, Subqueries, CTEs.
## Objective:
Our major concern is to gain actionable insights into our customer base to know the most profitable, loyal and most recent customers to enhance our marketing and customer relationship strategies.
## Dataset Overview:
We have a dataset for US regional sales data for orders between year 2018 and 2020. The data set contains 7,991 entries and 16 features that include Order Number, Sales Channel, Order Date, Customer ID, Order Quantity, Discount Applied, Unit Price, and Unit Cost.
## Data Cleaning:
The data has no null entries. No duplicates too.
## Data Exploration:
The following discoveries were made from the data;
- 7991 total orders
-	Total of 50 customers
-	$73,143,380 in revenue
-	$27,291,402 in profits
-	May 31st 2018 was the first order date
-	December 30th 2020 was the last order date
-	47 product types were sold
-	There are 4 Sales Channels;
    -	Online
    -	Wholesale
    -	Distributor
    -	In-Store
## RFM Analysis:
1.	Create a View (VWrfm_scores) to get RFM Scores.
2.	Create a View (VWrfm_segments) to segment customers into 5 categories base on their profitability - Most Valuable, Valuable, Average, Below Average, and At Risk.
## Insights:
- 70% of our customers make up the average, valuable and most valuable rfm categories. 8% are considered 'at risk' customers.
- We have 7 highly esteemed customers with Recency, Frequency, and Monetary designation of 4 and 5. These customers should never be lost.
- Our most profitable customers with Monetary designation of 5 happen to be the most loyal (frequent) with F designation between 3 and 5.
