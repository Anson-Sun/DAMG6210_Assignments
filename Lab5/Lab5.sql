USE "AdventureWorks2008R2";

-- 5.1

SELECT SalesPersonID, 
       FirstName, 
       LastName, 
       [2006] AS Sales_2006, 
       [2007] AS Sales_2007
FROM
(
    SELECT datepart(yy, OrderDate) AS Year,
           sh.SalesPersonID,
           p.FirstName,
           p.LastName,
           cast(sum(TotalDue) as int) as TotalSales
    FROM Sales.SalesOrderHeader sh
    JOIN Person.Person p ON sh.SalesPersonID = p.BusinessEntityID
    WHERE year(OrderDate) IN (2006, 2007)
      AND SalesPersonID BETWEEN 275 AND 278
    GROUP BY sh.SalesPersonID, datepart(yy, OrderDate), p.FirstName, p.LastName
    HAVING SUM(TotalDue) > 1500000
) AS SourceTable
PIVOT
(
    SUM(TotalSales)
    FOR Year IN ([2006], [2007])
) AS PivotTable;

-- 5.2

CREATE FUNCTION GetCustomerFullName(@CustomerID INT)
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @FullName NVARCHAR(255);
    
    SELECT @FullName = p.LastName + ' ' + p.FirstName
    FROM Person.Person p
    INNER JOIN Sales.Customer c ON p.BusinessEntityID = c.PersonID
    WHERE c.CustomerID = @CustomerID;
    
    RETURN @FullName;
END;
GO

USE "AdventureWorks2008R2";

-- 5.3

CREATE TRIGGER CheckUnpaidFinesBeforeEnrollment
BEFORE INSERT ON Enrollment
FOR EACH ROW
BEGIN
    DECLARE unpaidFines INT;
    SELECT COUNT(*) INTO unpaidFines
    FROM Fine
    WHERE StudentID = NEW.StudentID AND PaidDate IS NULL;
    
    IF unpaidFines > 0 THEN
        RAISE EXCEPTION 'Cannot enroll due to unpaid fines.';
    END IF;
END;

--5.4

CREATE TRIGGER CalculateShippingFee
AFTER INSERT, UPDATE
ON OrderDetail
FOR EACH ROW
BEGIN
    -- Temporary variables to hold calculations
    DECLARE totalQuantity INT;
    DECLARE orderValue MONEY;
    DECLARE shippingFeePerProduct MONEY;
    DECLARE totalShippingFee MONEY;

    -- Calculate total quantity of products for the order
    SELECT SUM(Quantity) INTO totalQuantity
    FROM OrderDetail
    WHERE OrderID = NEW.OrderID;

    -- Get the order value to determine shipping fee per product
    SELECT OrderValue INTO orderValue
    FROM SalesOrder
    WHERE OrderID = NEW.OrderID;

    -- Determine shipping fee per product based on order value
    IF orderValue > 600 THEN
        SET shippingFeePerProduct = 2;
    ELSE
        SET shippingFeePerProduct = 4;
    END IF;

    -- Calculate total shipping fee
    SET totalShippingFee = totalQuantity * shippingFeePerProduct;

    -- Update the ShippingFee in the SalesOrder table
    UPDATE SalesOrder
    SET ShippingFee = totalShippingFee
    WHERE OrderID = NEW.OrderID;
END;