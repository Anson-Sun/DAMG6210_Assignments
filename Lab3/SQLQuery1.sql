USE AdventureWorks2008R2;

--Lab 3.1

SELECT 
    c.CustomerID, 
    c.TerritoryID, 
    FirstName, 
    LastName,
    COUNT(o.SalesOrderID) AS [Total Orders],
    CASE
        WHEN COUNT(o.SalesOrderID) = 0 THEN 'No Order'
        WHEN COUNT(o.SalesOrderID) = 1 THEN 'One Time'
        WHEN COUNT(o.SalesOrderID) BETWEEN 2 AND 5 THEN 'Regular'
        WHEN COUNT(o.SalesOrderID) BETWEEN 6 AND 10 THEN 'Often'
        WHEN COUNT(o.SalesOrderID) > 10 THEN 'Loyal'
    END AS [Customer Frequency]
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o ON c.CustomerID = o.CustomerID
JOIN Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;

--Lab 3.2

SELECT 
    o.TerritoryID, 
    s.Name, 
    YEAR(o.OrderDate) AS Year,
    COUNT(o.SalesOrderID) AS [Total Orders],
    DENSE_RANK() OVER (PARTITION BY o.TerritoryID ORDER BY COUNT(o.SalesOrderID) DESC) AS [Rank]
FROM Sales.SalesTerritory s 
JOIN Sales.SalesOrderHeader o ON s.TerritoryID = o.TerritoryID
GROUP BY o.TerritoryID, s.Name, YEAR(o.OrderDate)
ORDER BY o.TerritoryID, [Rank];

--Lab3.3

WITH CustomerPurchases AS (
    SELECT 
        YEAR(o.OrderDate) AS OrderYear,
        c.CustomerID,
        CAST(SUM(o.TotalDue) AS INT) AS TotalPurchase,
        COUNT(o.SalesOrderID) AS TotalOrders,
        DENSE_RANK() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY SUM(o.TotalDue) DESC) AS PurchaseRank
    FROM Sales.SalesOrderHeader o
    JOIN Sales.Customer c ON o.CustomerID = c.CustomerID
    GROUP BY YEAR(o.OrderDate), c.CustomerID
)
SELECT 
    OrderYear,
    CustomerID,
    TotalPurchase,
    TotalOrders
FROM CustomerPurchases
WHERE PurchaseRank = 1
ORDER BY OrderYear;

--Lab 3.4
SELECT DISTINCT c.CustomerID
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Color IN ('Red', 'Yellow')
  AND soh.OrderDate > '2008-05-01'
GROUP BY c.CustomerID
HAVING COUNT(DISTINCT CASE WHEN p.Color = 'Red' THEN sod.ProductID END) > 0
   AND COUNT(DISTINCT CASE WHEN p.Color = 'Yellow' THEN sod.ProductID END) > 0
ORDER BY c.CustomerID;

--Lab 3.5
WITH ColorSales AS (
    SELECT 
        soh.TerritoryID,
        p.Color,
        CAST(SUM(sod.UnitPrice * sod.OrderQty) AS INT) AS TotalColorValue
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
    INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE soh.TotalDue > 65000
    AND p.Color IS NOT NULL
    GROUP BY soh.TerritoryID, p.Color
),
TerritoryColorStats AS (
    SELECT 
        TerritoryID,
        MAX(TotalColorValue) AS HighestTotal,
        MIN(TotalColorValue) AS LowestTotal,
        MAX(TotalColorValue) - MIN(TotalColorValue) AS Difference
    FROM ColorSales
    GROUP BY TerritoryID
),
RankedTerritories AS (
    SELECT 
        TerritoryID,
        HighestTotal,
        LowestTotal,
        Difference,
        RANK() OVER (ORDER BY Difference ASC) AS RankAsc,
        RANK() OVER (ORDER BY Difference DESC) AS RankDesc
    FROM TerritoryColorStats
)
SELECT 
    TerritoryID,
    HighestTotal,
    LowestTotal,
    Difference
FROM RankedTerritories
WHERE RankAsc = 1 OR RankDesc = 1
ORDER BY TerritoryID;