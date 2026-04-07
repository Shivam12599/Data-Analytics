use project_1;

/* Q) Write a query to identify the number of duplicates in "sales_transaction" table. Also, create a separate table containing the unique values and remove the the original table from the databases and replace the name of the new table with the original name.*/
select 
sum(count) as count 
FROM(SELECT TransactionID, COUNT(*) - 1 AS count
FROM Sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1) as sub;

CREATE TABLE Sales_transaction_nodup AS
SELECT DISTINCT *
FROM Sales_transaction;

DROP TABLE Sales_transaction;

ALTER TABLE Sales_transaction_nodup
RENAME TO Sales_transaction;
SELECT * from Sales_transaction;

/* Write a query to identify the discrepancies in the price of the same product in "sales_transaction" and "product_inventory" tables. Also, update those discrepancies to match the price in both the tables.*/
select TransactionID,s.price as TransactionPrice,p.price as InventoryPrice
from sales_transaction s 
join product_inventory p 
on s.ProductID = p.ProductID
where s.price != p.price;
update sales_transaction set Price = (
    select price from product_inventory
    where sales_transaction.ProductID = product_inventory.ProductID
)
where price <>(
    select price from product_inventory 
    where sales_transaction.ProductID = product_inventory.ProductID
);
select * from sales_transaction;

/*Write a SQL query to identify the null values in the dataset and replace those by “Unknown”.*/
select count(*) 
from customer_profiles
where location is null;
update customer_profiles set location = 'unknown'
where location is null;
select * from customer_profiles;

/*Write a SQL query to clean the DATE column in the dataset.*/

create table new_st as select * from Sales_transaction;
alter table new_st add TransactionDate_updated date;
update new_st set TransactionDate_updated = str_to_date(TransactionDate,'%Y-%m-%d');
drop table Sales_transaction;
rename table new_st to Sales_transaction; 
select * from Sales_transaction;

/*Write a SQL query to summarize the total sales and quantities sold per product by the company. */
select ProductID,sum(QuantityPurchased) as TotalUnitsSold,sum(QuantityPurchased * Price) as TotalSales
from Sales_transaction
group by ProductID
order by TotalSales desc;

/*Write a SQL query to count the number of transactions per customer to understand purchase frequency.*/
select CustomerID,count(CustomerID) as NumberOfTransactions
from Sales_transaction 
group by CustomerID
order by NumberOfTransactions desc;

/*Write a SQL query to evaluate the performance of the product categories based on the total sales which help us understand the product categories which needs to be promoted in the marketing campaigns.*/
select p.Category,
sum(s.QuantityPurchased) as TotalUnitsSold,
sum(s.QuantityPurchased * s.Price) as TotalSales
from Sales_transaction s 
join product_inventory p 
on p.ProductID = s.ProductID
group by p.Category
order by TotalSales desc;

/*Write a SQL query to find the top 10 products with the highest total sales revenue from the sales transactions. This will help the company to identify the High sales products which needs to be focused to increase the revenue of the company.*/
select ProductID,sum(QuantityPurchased * Price) as TotalRevenue
from Sales_transaction
group by ProductID
order by TotalRevenue desc
limit 10;

/*Write a SQL query to find the ten products with the least amount of units sold from the sales transactions, provided that at least one unit was sold for those products.*/
desc Sales_transaction;
select ProductID,sum(QuantityPurchased) as TotalUnitsSold
from Sales_transaction
group by ProductID
having TotalUnitsSold > 0
order by TotalUnitsSold asc
limit 10;

/*Write a SQL query to identify the sales trend to understand the revenue pattern of the company.*/
select date_format(TransactionDate_updated,'%Y-%m-%d') as DATETRANS,
count(TransactionID) as Transaction_count,
round(sum(QuantityPurchased),2) as TotalUnitsSold,
round(sum(QuantityPurchased * Price),2) as TotalSales
from sales_transaction
group by DATETRANS
order by DATETRANS desc;

/*Write a SQL query to understand the month on month growth rate of sales of the company which will help understand the growth trend of the company.*/

SELECT 
    month,
    ROUND(total_sales,2) as total_sales,
    ROUND(LAG(total_sales, 1) OVER (ORDER BY month),2) AS previous_month_sales,
    ROUND(
        (total_sales - LAG(total_sales, 1) OVER (ORDER BY month)) 
        / LAG(total_sales, 1) OVER (ORDER BY month) * 100, 
        2
    ) AS mom_growth_percentage
FROM (
    SELECT 
        MONTH(transactiondate) AS month,
        SUM(QuantityPurchased * Price) AS total_sales
    FROM sales_transaction
    GROUP BY MONTH(transactiondate)
) AS monthly_sales
ORDER BY month;

/*Write a SQL query that describes the number of transaction along with the total amount spent by each customer which are on the higher side and will help us understand the customers who are the high frequency purchase customers in the company.*/
select CustomerID,
count(*) as NumberOfTransactions,
sum(QuantityPurchased * Price) as TotalSpent
from sales_transaction
group by CustomerID
having count(*) > 10 and sum(QuantityPurchased * Price) > 1000
order by TotalSpent desc;

/*Write a SQL query that describes the number of transaction along with the total amount spent by each customer, which will help us understand the customers who are occasional customers or have low purchase frequency in the company.*/
select CustomerID,
count(*) as NumberOfTransactions,
sum(QuantityPurchased * Price) as TotalSpent
from Sales_transaction 
group by CustomerID
having count(*) <= 2
order by NumberOfTransactions asc,TotalSpent desc;

/*Write a SQL query that describes the total number of purchases made by each customer against each productID to understand the repeat customers in the company.*/
select CustomerID,
ProductID,
count(*) as TimesPurchased
from Sales_transaction
group by CustomerID,ProductID
having count(*) > 1
order by TimesPurchased desc;

/*Write a SQL query that describes the duration between the first and the last purchase of the customer in that particular company to understand the loyalty of the customer.*/
select CustomerID,
min(converted_date) as FirstPurchase,
max(converted_date) as LastPurchase,
datediff(max(converted_date),min(converted_date)) as DaysBetweenPurchases
from(
    (select CustomerID,str_to_date(TransactionDate,'%Y-%m-%d') as converted_date from Sales_transaction) 
) as sub
group by CustomerID
having DaysBetweenPurchases > 0
order by DaysBetweenPurchases desc;

/*Write an SQL query that segments customers based on the total quantity of products they have purchased. Also, count the number of customers in each segment which will help us target a particular segment for marketing.*/
create table customer_Segment as 
select CustomerID,
case
    when TotalQuantity between 1 and 10 then "Low"
    when TotalQuantity between 11 and 30 then "Med"
    else "None" end as CustomerSegment
from
(select a.CustomerID, sum(b.QuantityPurchased)as TotalQuantity
from customer_profiles a
join sales_transaction b 
on a.CustomerID = b.CustomerID 
group by a.CustomerID) as totquant;

select CustomerSegment,count(*)
from customer_Segment
group by CustomerSegment;






