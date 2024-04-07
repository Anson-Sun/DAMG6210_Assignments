
--Lab 3-1

SELECT c.CustomerID, c.TerritoryID, FirstName, LastName,
COUNT(o.SalesOrderid) [Total Orders],
	   CASE
		  WHEN COUNT(o.SalesOrderID) = 0
			 THEN 'No Order'
		  WHEN COUNT(o.SalesOrderID) = 1
			 THEN 'One Time'
		  WHEN COUNT(o.SalesOrderID) BETWEEN 2 AND 5
			 THEN 'Regular'
		  WHEN COUNT(o.SalesOrderID) BETWEEN 6 AND 10
			 THEN 'Often'
		  ELSE 'Loyal'
	   END AS [Order Frequency]
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o
   ON c.CustomerID = o.CustomerID
JOIN Person.Person p
   ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;


-- Lab 3-2

SELECT o.TerritoryID, s.Name, year(o.OrderDate) Year,
	   COUNT(o.SalesOrderid) [Total Orders],
	   DENSE_RANK() OVER (PARTITION BY o.TerritoryID ORDER BY COUNT(o.SalesOrderid) DESC) [Rank]
FROM Sales.SalesTerritory s 
JOIN Sales.SalesOrderHeader o
	  ON s.TerritoryID = o.TerritoryID
GROUP BY o.TerritoryID, s.Name, year(o.OrderDate)
ORDER BY o.TerritoryID;


-- Lab 3-3

select Year, CustomerID, cast(TotalSale as int) [Total Sales], OrderCount 'Order Count' from
(
  select year(OrderDate) Year, CustomerID, sum(TotalDue) TotalSale, count(SalesOrderID) OrderCount,
         rank() over (partition by year(OrderDate) order by sum(TotalDue) desc) as rank
  from Sales.SalesOrderHeader
  group by year(OrderDate), CustomerID) temp
where rank =1
order by Year;


-- Lab 3-4

select sh.CustomerID
   from Sales.SalesOrderHeader sh
   join Sales.SalesOrderDetail sd
   on sh.SalesOrderID = sd.SalesOrderID
   join Production.Product p
   on sd.ProductID = p.ProductID
   where sh.OrderDate > '5-1-2008'
         and p.Color = 'Red'
intersect
   select sh.CustomerID
   from Sales.SalesOrderHeader sh
   join Sales.SalesOrderDetail sd
   on sh.SalesOrderID = sd.SalesOrderID
   join Production.Product p
   on sd.ProductID = p.ProductID
   where sh.OrderDate > '5-1-2008'
         and p.Color = 'Yellow'
order by CustomerID;


-- Lab 3-5

WITH TEMP AS
(SELECT Color, TerritoryID, SUM(UnitPrice * OrderQty) AS TotalSales
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod
ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p
ON sod.ProductID = p.ProductID
WHERE Color IS NOT NULL AND TotalDue > 65000
GROUP BY Color, TerritoryID),

T1 AS
(SELECT TerritoryID,  
        CAST(MAX(TotalSales) AS INT)  Highest, 
        CAST(MIN(TotalSales) AS INT) Lowest,
        CAST(MAX(TotalSales) - MIN(TotalSales) AS INT) AS Difference,
        RANK() OVER (ORDER BY (MAX(TotalSales) - MIN(TotalSales))) AS Rank
FROM TEMP GROUP BY TerritoryID)

SELECT * from T1 WHERE Rank = 1
                 OR Rank = (SELECT TOP 1 Rank FROM T1 ORDER BY Rank DESC)
ORDER BY TerritoryID;

