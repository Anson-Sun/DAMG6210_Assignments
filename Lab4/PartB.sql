USE "AdventureWorks2008R2";


--Part1

WITH CustomerPurchases AS (
    SELECT
        YEAR(SOH.OrderDate) AS OrderYear,
        SOH.CustomerID,
        SUM(SOH.TotalDue) AS TotalPurchase
    FROM Sales.SalesOrderHeader SOH
    GROUP BY YEAR(SOH.OrderDate), SOH.CustomerID
), RankedPurchases AS (
    SELECT
        CP.OrderYear,
        CP.CustomerID,
        CP.TotalPurchase,
        RANK() OVER (PARTITION BY CP.OrderYear ORDER BY CP.TotalPurchase DESC) AS PurchaseRank
    FROM CustomerPurchases CP
), YearlySales AS (
    SELECT
        OrderYear,
        SUM(TotalPurchase) AS TotalSale
    FROM CustomerPurchases
    GROUP BY OrderYear
), TopCustomers AS (
    SELECT
        RP.OrderYear,
        RP.CustomerID,
        RP.TotalPurchase
    FROM RankedPurchases RP
    WHERE RP.PurchaseRank <= 3
)
SELECT
    YS.OrderYear AS Year,
    YS.TotalSale,
    STUFF(
        (SELECT ', ' + CAST(TC.CustomerID AS VARCHAR(MAX))
         FROM TopCustomers TC
         WHERE TC.OrderYear = YS.OrderYear
         ORDER BY TC.TotalPurchase DESC
         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Top3Customers
FROM YearlySales YS
ORDER BY YS.OrderYear;

--Part2

WITH SalespersonOrders AS (
    SELECT
        SP.BusinessEntityID AS SalesPersonID,
        SOH.SalesOrderID,
        SOH.TotalDue
    FROM Sales.SalesPerson SP
    JOIN Sales.SalesOrderHeader SOH ON SP.BusinessEntityID = SOH.SalesPersonID
    WHERE SOH.SalesPersonID IS NOT NULL
),
OrderQuantities AS (
    SELECT
        SOH.SalesOrderID,
        SUM(SOD.OrderQty) AS TotalQuantity
    FROM Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    GROUP BY SOH.SalesOrderID
),
LowestQuantities AS (
    SELECT
        SalesPersonID,
        MIN(TotalQuantity) AS LowestQuantity
    FROM SalespersonOrders SO
    JOIN OrderQuantities OQ ON SO.SalesOrderID = OQ.SalesOrderID
    GROUP BY SalesPersonID
),
RankedOrders AS (
    SELECT
        SO.SalesPersonID,
        SO.SalesOrderID,
        SO.TotalDue,
        OQ.TotalQuantity,
        RANK() OVER (PARTITION BY SO.SalesPersonID ORDER BY SO.TotalDue) AS ValueRank
    FROM SalespersonOrders SO
    JOIN OrderQuantities OQ ON SO.SalesOrderID = OQ.SalesOrderID
),
TopSellingOrders AS (
    SELECT
        SalesPersonID
    FROM RankedOrders
    WHERE ValueRank <= 3
    GROUP BY SalesPersonID
),
Lowest3Values AS (
    SELECT
        SalesPersonID,
        TotalDue,
        ROW_NUMBER() OVER (PARTITION BY SalesPersonID ORDER BY TotalDue ASC) AS ValueRank
    FROM SalespersonOrders
)

SELECT
    TSO.SalesPersonID,
    COUNT(DISTINCT RO.SalesOrderID) AS TotalOrderCount,
    LQ.LowestQuantity,
    STUFF(
         (SELECT ', ' + CAST(L3V.TotalDue AS VARCHAR(MAX))
          FROM Lowest3Values L3V
          WHERE L3V.SalesPersonID = TSO.SalesPersonID AND L3V.ValueRank <= 3
          FOR XML PATH('')), 1, 2, '') AS Lowest3Values
FROM TopSellingOrders TSO
JOIN RankedOrders RO ON TSO.SalesPersonID = RO.SalesPersonID
JOIN LowestQuantities LQ ON TSO.SalesPersonID = LQ.SalesPersonID
GROUP BY TSO.SalesPersonID, LQ.LowestQuantity
ORDER BY TSO.SalesPersonID;