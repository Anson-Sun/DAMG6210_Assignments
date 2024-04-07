
-- Lab 5-1

Select Year,
       ISNULL([275 Michael Blythe],' ') '275 Michael Blythe',
	   ISNULL([276 Linda Mitchell],' ') '276 Linda Mitchell',
	   ISNULL([277 Jillian Carson],' ') '277 Jillian Carson',
	   ISNULL([278 Garrett Vargas],' ') '278 Garrett Vargas'
From(
select datepart(yy, OrderDate) Year,
       cast(SalesPersonID as varchar)+' '+FirstName+' '+LastName SalesPerson,
       cast(cast(sum(TotalDue) as int) as varchar) as TotalSales
from Sales.SalesOrderHeader sh
join Person.Person p
on sh.SalesPersonID = p.BusinessEntityID
where year(OrderDate) in (2006, 2007) and SalesPersonID between 275 and 278
group by cast(SalesPersonID as varchar)+' '+FirstName+' '+LastName,  datepart(yy, OrderDate)
having sum(TotalDue) > 1500000
)P
PIVOT  
(  
MAX(TotalSales)
FOR SalesPerson IN  
( [275 Michael Blythe] , [276 Linda Mitchell] , [277 Jillian Carson] ,
  [278 Garrett Vargas] )  
) AS pvt;


-- Lab 5-2

-- Create a table-valued function
create function uf_GetCustomerName
(@CustID int)
returns @tbl table  (name varchar(200))
  begin
     declare @fullname varchar(200) = '' ;

     select @fullname = p.FirstName + ' ' + p.LastName
     from AdventureWorks2008R2.Sales.Customer c
     join AdventureWorks2008R2.Person.Person p
     on c.PersonID = p.BusinessEntityID
     where c.CustomerID = @custID;

     insert into @tbl values (@fullname);

     return;
  end

-- Test run the function
select * from dbo.uf_GetCustomerName(11000)


-- Lab 5-3

create function ufLookUpFine (@StID int)
returns money
begin
   declare @amt money;
   select @amt = sum(Amount)
      from Fine
      where StudentID = @StID and PaidDate is null;
   return @amt;
end

alter table Enrollment add CONSTRAINT ckfine CHECK (dbo.ufLookUpFine (StudentID) = 0);


-- Lab 5-4

create trigger trShippingFee on Orderdetail
after insert, update, delete
as
begin
   declare @TotalQuantity int, @oid int, @fee money;

   set @oid = (select coalesce(i.OrderID, d.OrderID)
							   from inserted i
							   full join deleted d
							        on i.OrderID=d.OrderID);

   set @TotalQuantity = (select sum(Quantity) from OrderDetail 
                         where OrderID = @oid);
   
   if (select OrderValue from SalesOrder where OrderID = @oid) > 600
      set @fee = 2 * @TotalQuantity
      else set @fee = 4 * @TotalQuantity;

   update SalesOrder set ShippingFee = @fee
          where OrderID = @oid;
end

drop trigger trShippingFee



