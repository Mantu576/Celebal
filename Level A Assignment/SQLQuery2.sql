--1.List of ALL Customers
select * from Sales.Customer;

--2. list of all customers where company name neling in N
SELECT * FROM HumanResources.Department WHERE Name LIKE '%N';

--3.List of all customers who live in Berlin or London
SELECT * FROM Person.Address WHERE City IN ('Berlin', 'London');

--4.List of all customers who live in UK or USA
SELECT * FROM Sales.CountryRegionCurrency WHERE CountryRegionCode IN ('UK', 'USA');

--5.LIst of all products sorted by procuct name
SELECT * FROM Production.Product ORDER BY Name;

--6.LIst of all products where product same starts with an A
SELECT * FROM Production.Product WHERE Name LIKE 'A%';

--7.List of customers who ever placed an order
SELECT DISTINCT c.* 
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID;

--8.lst of Castore's who live in London and have brought chai
SELECT DISTINCT c.* 
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader ca ON c.CustomerID = ca.CustomerID
JOIN Person.Address a ON ca.CustomerID = a.AddressID
WHERE a.City = 'London' AND p.Name = 'Chai';

--9.List of customers never place an order
SELECT * FROM Sales.Customer
WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Sales.SalesOrderHeader);

--10.Details of first orer of the system
SELECT TOP 1 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate;

--11.List of customers who orderd Tofu
SELECT DISTINCT c.*
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Name = 'Tofu';

--12. Find the details of most expensive order date
SELECT TOP 1 OrderDate , SUM(SubTotal) AS TotalAmount
FROM Sales.SalesOrderHeader
GROUP BY OrderDate
ORDER BY TotalAmount DESC;

--13. For each order get the OrderId and Average quantity of items in that order
SELECT SalesOrderID, AVG(OrderQty) AS AvgQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--14 For order get the order), minimum quantity and male quantity for that order
SELECT SalesOrderID, MIN(OrderQty) AS MinQuantity, MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--15. Get all of all managers and total number of employees who report to them.
SELECT e.BusinessEntityID, COUNT(e.BusinessEntityID) AS TotalEmployees
FROM HumanResources.Employee e
WHERE e.BusinessEntityID IS NOT NULL
GROUP BY e.BusinessEntityID;

--16.Get the orderId and total quantity for each order that has a total quantity of greater than 300
SELECT SalesOrderID, SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

--17. Ist of all orders placed on or after 1996/12/31
SELECT * FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

--18. Ist of all orders shipped to Canada
SELECT * FROM Sales.CountryRegionCurrency
WHERE CountryRegionCode = 'CA';

--19. LIst of all orders with onder total> 200
SELECT soh.*
FROM Sales.SalesOrderHeader soh
JOIN (
    SELECT SalesOrderID, SUM(LineTotal) AS TotalAmount
    FROM Sales.SalesOrderDetail
    GROUP BY SalesOrderID
    HAVING SUM(LineTotal) > 200
) t ON soh.SalesOrderID = t.SalesOrderID;

--20 List of countries and sales maade in each country
SELECT CountryRegionCode, COUNT(*) AS SalesCount
FROM Sales.CountryRegionCurrency
GROUP BY CountryRegionCode;

--21. List of customer Contact Name and number of ordors they placed
SELECT c.CustomerID,  COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID;

--22. Use of customer contactNamen who have placed more than 3 orders
SELECT c.CustomerID,  COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID
HAVING COUNT(soh.SalesOrderID) > 3;

--23. Ust of discontinued products which were ordered between 1/1/1997 and 1/1/1996
SELECT DISTINCT p.*
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate BETWEEN '1997-01-01' AND '1998-01-01'
  AND p.DiscontinuedDate IS NOT NULL;

  --24. List of employee firstname, lastnane, superviser FirstNamne, LastName
  SELECT e.FirstName, e.LastName, m.FirstName AS SupervisorFirstName, m.LastName AS SupervisorLastName
FROM HumanResources.vEmployee e
LEFT JOIN HumanResources.vEmployee m ON e.BusinessEntityID = m.BusinessEntityID;

--25. List of Employees id and total sale conducted by employee
SELECT e.BusinessEntityID, SUM(sod.LineTotal) AS TotalSales
FROM HumanResources.Employee e
JOIN Sales.SalesOrderHeader soh ON e.BusinessEntityID = soh.SalesPersonID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY e.BusinessEntityID;

--26. Ist of employees whose FirstName contains character a
SELECT * 
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
WHERE p.FirstName LIKE '%a%';

--27. List of managers who have more than four people reporting to them

SELECT m.BusinessEntityID AS ManagerID, p.FirstName, p.LastName, COUNT(e.BusinessEntityID) AS NumberOfReports
FROM HumanResources.Employee AS e
JOIN HumanResources.Employee AS m ON e.BusinessEntityID = m.BusinessEntityID
JOIN Person.Person AS p ON m.BusinessEntityID = p.BusinessEntityID
GROUP BY m.BusinessEntityID, p.FirstName, p.LastName
HAVING COUNT(e.BusinessEntityID) > 4;

--28. List of Orders and ProductNames
SELECT soh.SalesOrderID, p.Name AS ProductName
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID;

--29. List of orders place by The best customer
SELECT soh.*
FROM Sales.SalesOrderHeader AS soh
WHERE soh.CustomerID = (
    SELECT TOP 1 soh.CustomerID
    FROM Sales.SalesOrderHeader AS soh
    GROUP BY soh.CustomerID
    ORDER BY SUM(soh.TotalDue) DESC
);

--30.List of orders placed by customer who do not have a Fax number

SELECT soh.*
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID
WHERE pp.PhoneNumber IS NULL;

--31. list of Postal codes where the Product Tofu was shipped
SELECT DISTINCT a.PostalCode
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu';

--32.l1st of product Names that shipped to France
SELECT DISTINCT p.Name
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'France';

--33. List of ProductNames and Categories for the supplier 'Specialty Biscuits, Ltd'
SELECT p.Name AS ProductName, pc.Name AS CategoryName
FROM Production.Product AS p
JOIN Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID
JOIN Purchasing.ProductVendor AS pv ON p.ProductID = pv.ProductID
JOIN Purchasing.Vendor AS v ON pv.BusinessEntityID = v.BusinessEntityID
WHERE v.Name = 'Speciality Biscuits, Ltd.';

--34. List of products that were never ordered
SELECT * 
FROM Production.Product 
WHERE ProductID NOT IN (SELECT ProductID FROM Sales.SalesOrderDetail);

 --35.List of products where units in  stock is less than 10 and units on order are 0.
SELECT p.ProductID, p.Name
FROM Production.Product AS p
LEFT JOIN (
    SELECT ProductID, SUM(Quantity) AS UnitsInStock
    FROM Production.ProductInventory
    GROUP BY ProductID
) AS pi ON p.ProductID = pi.ProductID
LEFT JOIN (
    SELECT ProductID, SUM(OrderQty) AS UnitsOnOrder
    FROM Purchasing.PurchaseOrderDetail
    GROUP BY ProductID
) AS po ON p.ProductID = po.ProductID
WHERE (pi.UnitsInStock IS NULL OR pi.UnitsInStock < 10)
  AND (po.UnitsOnOrder IS NULL OR po.UnitsOnOrder = 0);

 
 --36. List of top 10 countries by sales
SELECT TOP 10 cr.CountryRegionCode, SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.CountryRegionCode
ORDER BY TotalSales DESC;

--37. Number of onder each  employee has taken for customers with CustomerId between A and AO
SELECT soh.SalesPersonID, COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
WHERE LEFT(c.AccountNumber, 1) BETWEEN 'A' AND 'AO'
GROUP BY soh.SalesPersonID;

--38.Orderdate of most expensive order
SELECT TOP 1 OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;

--39. Product name and total revenue form that prodact
SELECT p.Name AS ProductName, SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
GROUP BY p.Name;

--40.Suppiler  and number of products offered
SELECT pv.BusinessEntityID AS SupplierID, COUNT(pv.ProductID) AS NumberOfProducts
FROM Purchasing.ProductVendor AS pv
GROUP BY pv.BusinessEntityID;

--41.Top 10 customers based on their busness 
SELECT TOP 10 c.CustomerID, SUM(soh.TotalDue) AS TotalBusiness
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalBusiness DESC;

--42.what is the total enue of the company.
SELECT SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;


























