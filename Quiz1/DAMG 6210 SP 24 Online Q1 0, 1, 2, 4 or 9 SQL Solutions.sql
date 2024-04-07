
-- ONLINE

-- DAMG 6210 SP 24 Q1 Last NUID digit 0, 1, 2, 4 or 9

-- Question 2

with temp1 as (
select p.Color, year(OrderDate) Year, month(OrderDate) Month
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
join Production.Product p
     on od.ProductID = p.ProductID
where color is not null
group by year(OrderDate), month(OrderDate), p.Color),

temp2 as (
select distinct year(OrderDate) Year, month(OrderDate) Month
from Sales.SalesOrderHeader
group by year(OrderDate), month(OrderDate)),

temp3 as (
select p.Color, count(distinct CustomerID) #ofCustomers
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
join Production.Product p
     on od.ProductID = p.ProductID
where color is not null
group by p.Color
having count(distinct CustomerID) > 4000)

select t1.Color, #ofCustomers, count(1) #Months
from temp1 t1
join temp3 t3
on t1.Color = t3.Color
group by t1.Color, #ofCustomers
having count(1) = (select count(1) from temp2)
order by t1.color;


-- Question 3

with t0 as (
select ProductID
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where totaldue < 1000),

t1 as (
select ProductID, 
       count(distinct StateProvinceID) sP,
	   rank() over (order by count(distinct StateProvinceID) desc) BP,
	   sum(UnitPrice * OrderQty) Sales,
	   rank() over (order by sum(UnitPrice * OrderQty) desc) BR
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Person.Address a
on sh.ShipToAddressID = a.AddressID

where ProductID not in (select ProductID from t0)

group by ProductID)

select t1.ProductID, SP, cast(Sales as int) Sales, Name, BP SPR, BR SalesR
from t1
join Production.Product p
on t1.ProductID = p.ProductID
where BR <= 10 and BP <= 10
order by t1.ProductID;

