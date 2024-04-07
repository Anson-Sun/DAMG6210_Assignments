USE AdventureWorks2008R2;

WITH SalesAmount AS (
  SELECT SOD.ProductID, SUM(SOD.UnitPrice * SOD.OrderQty) AS TotalSalesAmount
  FROM Sales.SalesOrderDetail SOD
	JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
  WHERE SOH.TotalDue >= 1000
  GROUP BY SOD.ProductID
),
StatesSold AS (
  SELECT SOD.ProductID, COUNT(DISTINCT Address.StateProvinceID) AS UniqueStates
  FROM Sales.SalesOrderDetail SOD
	JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
	JOIN Person.Address ON Address.AddressID = SOH.ShipToAddressID
  WHERE SOH.TotalDue >= 1000
  GROUP BY SOD.ProductID
),
RankedSales AS (
  SELECT ProductID, DENSE_RANK() OVER (ORDER BY TotalSalesAmount DESC) AS SalesRank
  FROM SalesAmount
),
RankedStates AS (
  SELECT ProductID, DENSE_RANK() OVER (ORDER BY UniqueStates DESC) AS StatesRank
  FROM StatesSold
)
SELECT P.ProductID, SS.UniqueStates, 
	   CAST(SA.TotalSalesAmount AS INT) AS TotalSalesAmount, P.Name
FROM Production.Product P
	JOIN SalesAmount SA ON P.ProductID = SA.ProductID
	JOIN StatesSold SS ON P.ProductID = SS.ProductID
	JOIN RankedSales RS ON P.ProductID = RS.ProductID
	JOIN RankedStates RST ON P.ProductID = RST.ProductID
WHERE RS.SalesRank < 10 AND RST.StatesRank < 10
ORDER BY P.ProductID;