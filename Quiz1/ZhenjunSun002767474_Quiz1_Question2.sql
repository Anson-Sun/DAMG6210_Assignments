USE AdventureWorks2008R2;

WITH MonthCounts AS (
  SELECT COUNT(DISTINCT YEAR(OrderDate) * 100 + MONTH(OrderDate)) AS TotalMonths
  FROM Sales.SalesOrderHeader
),
	 ColorSales AS (
		SELECT P.Color, SOD.SalesOrderID, SOH.OrderDate, SOD.ProductID, C.CustomerID
		FROM Production.Product AS P
		JOIN Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID
		JOIN Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
		JOIN Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
		WHERE P.Color IS NOT NULL
	 ),
ColorMonths AS (
  SELECT Color, CustomerID,
    COUNT(DISTINCT YEAR(OrderDate) * 100 + MONTH(OrderDate)) AS MonthsSold
  FROM ColorSales
  GROUP BY Color, CustomerID
),
ColorCustomerCounts AS (
  SELECT Color, COUNT(DISTINCT CustomerID) AS UniqueCustomers
  FROM ColorSales
  GROUP BY Color
)
SELECT C.Color, C.UniqueCustomers, CM.MonthsSold
FROM ColorCustomerCounts AS C
	JOIN ColorMonths AS CM ON C.Color = CM.Color
	JOIN MonthCounts ON CM.MonthsSold = MonthCounts.TotalMonths
WHERE C.UniqueCustomers > 4000
ORDER BY C.Color;