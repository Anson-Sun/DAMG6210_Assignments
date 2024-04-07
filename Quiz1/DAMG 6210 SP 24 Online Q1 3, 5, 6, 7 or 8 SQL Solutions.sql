
-- ONLINE

-- DAMG 6210 SP 24 Q1 Last NUID digit 3, 5, 6, 7 or 8

-- Question 2 

with temp1 as (
select od.ProductID, year(OrderDate) Year, datepart(qq, OrderDate) Quarter,
       sum(od.UnitPrice * od.OrderQty) Sales
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
group by year(OrderDate), datepart(qq, OrderDate), od.ProductID),

temp2 as (
select distinct year(OrderDate) Year, datepart(qq, OrderDate) Quarter
from Sales.SalesOrderHeader
group by year(OrderDate), datepart(qq, OrderDate)),

temp3 as (
select ProductID, count(distinct CustomerID) #ofCustomers
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
group by ProductID
having count(distinct CustomerID) > 2000)

select t1.ProductID, count(1) #Quarters, cast(sum(Sales) as int) TotalSales 
from temp1 t1
join temp3 t3
on t1.ProductID = t3.ProductID
group by t1.ProductID
having count(1) = (select count(1) from temp2)
order by ProductID;


-- Question 3

with t0 as
(select distinct SalesPersonID
 from Sales.SalesOrderHeader
 where SalesPersonID is not null and TotalDue < 10),

t1 as (
select SalesPersonID, 
       year(OrderDate) Year, 
       count(distinct StateProvinceID) sc,
	   rank() over (partition by year(OrderDate) order by count(distinct StateProvinceID) desc) SR,
	   sum(TotalDue) Sales,
	   rank() over (partition by year(OrderDate) order by sum(TotalDue) desc) BR
from Sales.SalesOrderHeader sh
join Person.Address a
on sh.ShipToAddressID = a.AddressID
where SalesPersonID is not null and SalesPersonID not in (select SalesPersonID from t0)
group by sh.SalesPersonID, year(OrderDate)
)

select SalesPersonID, Year, SC, cast(Sales as int) Sales, sr, br
from t1
where SR <= 5 and BR <= 5
order by Year;


