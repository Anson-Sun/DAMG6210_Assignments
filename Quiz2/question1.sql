USE "AdventureWorks2008R2";

WITH QuarterlySales AS (
    SELECT 
        p.ProductID,
        p.Name,
        YEAR(soh.OrderDate) AS Year,
        DATEPART(QUARTER, soh.OrderDate) AS Quarter,
        SUM(sod.UnitPrice * sod.OrderQty) AS TotalQuarterlySales
    FROM 
        Sales.SalesOrderDetail sod
        JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
        JOIN Production.Product p ON sod.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.Name,
        YEAR(soh.OrderDate),
        DATEPART(QUARTER, soh.OrderDate)
),
RankedQuarters AS (
    SELECT *,
           RANK() OVER (PARTITION BY ProductID ORDER BY TotalQuarterlySales DESC) AS SalesRank
    FROM QuarterlySales
),
OrdersPerQuarter AS (
    SELECT 
        sod.ProductID,
        YEAR(soh.OrderDate) AS Year,
        DATEPART(QUARTER, soh.OrderDate) AS Quarter,
        soh.SalesOrderID,
        soh.TotalDue,
        COUNT(*) OVER (PARTITION BY sod.ProductID, YEAR(soh.OrderDate), DATEPART(QUARTER, soh.OrderDate)) AS OrderCount,
        MAX(sod.UnitPrice * sod.OrderQty) OVER (PARTITION BY sod.ProductID, YEAR(soh.OrderDate), DATEPART(QUARTER, soh.OrderDate)) AS MaxProductSales
    FROM 
        Sales.SalesOrderDetail sod
        JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE 
        soh.TotalDue < 45000
),
FilteredOrders AS (
    SELECT *
    FROM OrdersPerQuarter
    WHERE OrderCount <= 5
),
FinalData AS (
    SELECT 
        rq.ProductID,
        rq.Name,
        rq.Year,
        rq.Quarter,
        fo.MaxProductSales / NULLIF(rq.TotalQuarterlySales, 0) * 100 AS PercentageOfTotalSales
    FROM 
        RankedQuarters rq
        JOIN FilteredOrders fo ON rq.ProductID = fo.ProductID AND rq.Year = fo.Year AND rq.Quarter = fo.Quarter
    WHERE 
        rq.SalesRank <= 2
)
SELECT 
    ProductID,
    Name,
    Year,
    Quarter,
    PercentageOfTotalSales
FROM 
    FinalData
ORDER BY 
    ProductID, Year DESC, Quarter DESC;