USE AdventureWorks2008R2;

--2.1
SELECT ProductID, Name, Color, ListPrice, cast(SellStartDate as date) 'Date'
FROM Production.Product
WHERE ListPrice > (
    SELECT MAX(ListPrice)
    FROM Production.Product) - 10
ORDER BY SellStartDate;

--2.2
SELECT CustomerID, 
	   OrderDate, 
	   COUNT(CustomerID)AS "Total Number of Order"
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, OrderDate
ORDER BY "Total Number of Order" DESC;

--2.3
SELECT A.TerritoryID,B.[Name] AS TerritoryName,COUNT(A.SalesOrderID)/COUNT(DISTINCT A.CustomerID) AS "Ratio"
FROM Sales.SalesOrderHeader AS A
JOIN Sales.SalesTerritory AS B ON (A.TerritoryID=B.TerritoryID)
GROUP BY A.TerritoryID,B.[Name]
HAVING COUNT(A.SalesOrderID)/COUNT(DISTINCT A.CustomerID)>=5
ORDER BY A.TerritoryID;

--2.4
SELECT CustomerID, FirstName, LastName, EmailAddress
FROM Sales.Customer s
JOIN Person.Person p ON s.CustomerID = p.BusinessEntityID
JOIN person.emailaddress e ON s.CustomerID = e.BusinessEntityID
ORDER BY CustomerID;

--2.5
SELECT Year(OrderDate) AS OrderYear, SUM(OrderQty) AS "Total_Sold"
FROM Sales.SalesOrderHeader AS oh
JOIN Sales.SalesOrderDetail AS od ON oh.SalesOrderID = od.SalesOrderID
GROUP BY Year(OrderDate)
HAVING MAX(TotalDue) <= 150000
ORDER BY Total_Sold DESC;

--2.6
SELECT SOT.TerritoryID, CAST(SUM(SOH.TotalDue) AS INT) AS TotalSales
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Production.Product P ON SOD.ProductID = P.ProductID
INNER JOIN Sales.SalesTerritory SOT ON SOH.TerritoryID = SOT.TerritoryID
WHERE DAY(SOH.OrderDate) = 1 
	  AND MONTH(SOH.OrderDate) = 1
	  AND P.Color = 'Black'
GROUP BY SOT.TerritoryID
HAVING COUNT(DISTINCT SOD.ProductID) > 40
ORDER BY SOT.TerritoryID ASC;
