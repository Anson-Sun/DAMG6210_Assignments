-- Part A
create database Spring24_Lab4;
use Spring24_Lab4;

CREATE TABLE Person (
PersonID int IDENTITY NOT NULL PRIMARY KEY,
LastName varchar(26) NOT NULL,
FirstName varchar(26) NOT NULL,
DateOfBirth datetime
);

CREATE TABLE Specialty(
SpecialtyID INT IDENTITY NOT NULL PRIMARY KEY,
NAME varchar(26) NOT NULL,
DESCRIPTION varchar(60) NOT NULL
);

CREATE TABLE Organization(
OrganizationID INT IDENTITY NOT NULL PRIMARY KEY,
Name varchar(26) NOT NULL,
MainPhone int NOT NULL
);

CREATE TABLE Volunteering(
VolunteeringID int IDENTITY NOT NULL PRIMARY KEY,
OrganizationID INT NOT NULL REFERENCES Organization(OrganizationID),
SpecialtyID INT NOT NULL REFERENCES Specialty(SpecialtyID),
PersonID INT NOT NULL REFERENCES Person(PersonID)
);



-- Part B-1 (2 points)

WITH Temp AS

   (select year(OrderDate) Year, CustomerID, cast(sum(TotalDue) as int) ttl,
    rank() over (partition by year(OrderDate) order by sum(TotalDue) desc) as TopCustomer
    from Sales.SalesOrderHeader
    group by year(OrderDate), CustomerID) 

select t1.Year, sum(t1.ttl) [Total Sale],

STUFF((SELECT  ', '+RTRIM(CAST(CustomerID as char))  
       FROM temp 
       WHERE Year = t1.Year and TopCustomer <=3
       FOR XML PATH('')) , 1, 2, '') AS Top3Customers
from temp t1
where t1.topcustomer <= 3
group by t1.Year
order by year;


-- Part B-2 (2 points)

with temp as (
select h.SalesPersonID, h.SalesOrderID, sum(OrderQty) TotalQuantity,
       rank() over (order by sum(OrderQty) desc) Rank
from Sales.SalesOrderDetail d
join Sales.SalesOrderHeader h
on d.SalesOrderID = h.SalesOrderID
where SalesPersonID is not null
group by h.SalesOrderID, h.SalesPersonID
),

m as
(select SalesPersonID, min(TotalQuantity) LowestQuantity
 from temp
 group by SalesPersonID)

select c.SalesPersonID, count(distinct c.SalesOrderID) TotalOrderCount, 
LowestQuantity,
STUFF((SELECT  TOP 3 WITH TIES ', '+RTRIM(CAST(s.TotalDue as varchar))  
       FROM Sales.SalesOrderHeader s  
	   WHERE s.SalesPersonID = c.SalesPersonID
       ORDER BY TotalDue ASC
       FOR XML PATH('')) , 1, 2, '') AS Lowest3Values

from Sales.SalesOrderHeader c
join temp t
on c.SalesPersonID = t.SalesPersonID
join m
on c.SalesPersonID = m.SalesPersonID
where Rank <= 3 and t.SalesPersonID is not null
group by c.SalesPersonID, LowestQuantity
order by c.SalesPersonID;


-- Part C (2 points)

IF OBJECT_ID('tempdb..#TempTable') IS NOT NULL
DROP TABLE #TempTable;

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS
(
    -- Top-level compoments
	SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
        b.EndDate, 0 AS ComponentLevel
    FROM Production.BillOfMaterials AS b
    WHERE b.ProductAssemblyID = 992
          AND b.EndDate IS NULL

    UNION ALL

	-- All other sub-compoments
    SELECT bom.ProductAssemblyID, bom.ComponentID, bom.PerAssemblyQty,
        bom.EndDate, ComponentLevel + 1
    FROM Production.BillOfMaterials AS bom 
        INNER JOIN Parts AS p
        ON bom.ProductAssemblyID = p.ComponentID
        AND bom.EndDate IS NULL
)
SELECT AssemblyID, ComponentID, Name, ListPrice, PerAssemblyQty, 
       ListPrice * PerAssemblyQty SubTotal, ComponentLevel

into #TempTable

FROM Parts AS p
    INNER JOIN Production.Product AS pr
    ON p.ComponentID = pr.ProductID
ORDER BY ComponentLevel, AssemblyID, ComponentID;

select * from
(select ComponentLevel, ComponentID, Name, ListPrice,
        rank() over (partition by ComponentLevel order by ListPrice DESC) rank
from #TempTable) temp
where rank = 1 and ListPrice > 0
order by ComponentLevel;

