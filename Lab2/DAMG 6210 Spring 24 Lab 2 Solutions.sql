USE AdventureWorks2008R2;

--2.1

SELECT ProductID, Name, ListPrice, cast(SellStartDate as date) Date
FROM Production.Product
WHERE ListPrice > 
(
	SELECT MAX(ListPrice) - 10
	FROM Production.Product
)
ORDER BY SellStartDate;


--2.2

SELECT CustomerID, AccountNumber, 
       COUNT(SalesOrderID) AS TotalOrders, 
	   CAST(MAX(OrderDate) AS DATE) AS OrderDate
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, AccountNumber
ORDER BY TotalOrders DESC;


-- 2-3

select h.TerritoryID, t.name
from Sales.SalesOrderHeader h
join Sales.SalesTerritory t
on h.TerritoryID = t.TerritoryID
group by h.TerritoryID, t.name
having (count(SalesOrderID) / count(distinct CustomerID)) >= 5
order by TerritoryID;


--2.4

SELECT c.CustomerID, p.FirstName, p.LastName, e.EmailAddress
FROM Sales.Customer c
LEFT JOIN Person.Person p
     ON (c.PersonID = p.BusinessEntityID)
LEFT JOIN Person.EmailAddress e
     ON (e.BusinessEntityID = p.BusinessEntityID)
WHERE CustomerID BETWEEN 25000 and 27000
ORDER BY c.CustomerID;


-- 2.5

SELECT year(OrderDate) Year,
       sum(OrderQty) TotalProductQuantitySold
FROM Sales.SalesOrderHeader so
JOIN Sales.SalesOrderDetail sd
ON so.SalesOrderID = sd.SalesOrderID
WHERE year(OrderDate) NOT IN
(SELECT year(OrderDate)
 FROM Sales.SalesOrderHeader
 WHERE TotalDue >150000)
GROUP BY year(OrderDate)
ORDER BY TotalProductQuantitySold desc;


-- 2.6

with temp as
(select SalesOrderID
 from Sales.SalesOrderDetail sd
 join Production.Product p
 on p.ProductID = sd.ProductID
 where Color = 'Black'
 group by sd.SalesOrderID),

tmp as
(select SalesOrderID, count(distinct ProductID) up
 from Sales.SalesOrderDetail
 where SalesOrderID in (select * from temp)
 group by SalesOrderID
 having count(distinct ProductID) > 40)

select TerritoryID, cast(sum(TotalDue) as int) TotalSales
from Sales.SalesOrderHeader
where month(OrderDate) = 1 and day(OrderDate) = 1
      and SalesOrderID in (select SalesOrderID from tmp)
group by TerritoryID
order by TerritoryID asc;

