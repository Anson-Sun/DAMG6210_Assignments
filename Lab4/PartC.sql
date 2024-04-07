USE "AdventureWorks2008R2";

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel, ListPrice) AS
(
    -- Anchor member definition
    SELECT 
        b.ProductAssemblyID, 
        b.ComponentID, 
        b.PerAssemblyQty,
        b.EndDate, 
        0 AS ComponentLevel,
        pr.ListPrice
    FROM Production.BillOfMaterials AS b
    INNER JOIN Production.Product AS pr ON b.ComponentID = pr.ProductID
    WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL AND pr.ListPrice > 0
    
    UNION ALL
    
    -- Recursive member definition
    SELECT 
        bom.ProductAssemblyID, 
        bom.ComponentID, 
        bom.PerAssemblyQty,
        bom.EndDate, 
        ComponentLevel + 1,
        pr.ListPrice
    FROM Production.BillOfMaterials AS bom
    INNER JOIN Parts AS p ON bom.ProductAssemblyID = p.ComponentID
    INNER JOIN Production.Product AS pr ON bom.ComponentID = pr.ProductID
    WHERE bom.EndDate IS NULL AND pr.ListPrice > 0
),
RankedParts AS (
    SELECT *,
        RANK() OVER (PARTITION BY ComponentLevel ORDER BY ListPrice DESC) AS PriceRank
    FROM Parts
)
SELECT 
    AssemblyID, 
    ComponentID, 
    PerAssemblyQty, 
    ComponentLevel,
    ListPrice
FROM RankedParts
WHERE PriceRank = 1
ORDER BY ComponentLevel, ListPrice DESC;