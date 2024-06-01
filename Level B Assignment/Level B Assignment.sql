
                                                                     --Level B Assignment
																	 --Done By Mantu Pal
-- procedures
-----------------------
--Question No 1
-- Create a procedure InsertOrderDetails that takes OrderID, ProductID, UnitPrice, Quantiy, Discount as input parameters and inserts that order information in the Order Details table. 
-- After each order inserted, check the @@rowcount value to make sure that order was inserted properly. If for any reason the order was not inserted, print the messages Failed to place the
-- order. Please try again. Also your procedure should have these functionalities

-- Make the UnitPrice and Discount parameters optional

-- If no UnitPrice is given, then use the UnitPrice value from the product table.

-- If no Discount is given, then use a discount of 0.

-- Adjust the quantity in stock (UnitsInStock) for the product by subtracting the quantity sold from inventory.

-- However, if there is not enough of a product in stock, then abort the stored procedure without making any changes to the database.

-- Print a message if the quantity in stock of a product drops below its Reorder Level as a result of the update.



CREATE PROCEDURE InsertorderDetailses
    @OrderID INT,
	@salesOrderDetailID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(10, 2) ,
    @Quantity INT,
    @Discount DECIMAL(4, 2), 
	@spoferID INT
AS
BEGIN
    DECLARE @ProductStock INT;

    -- Get current stock
    SELECT @ProductStock = p.Quantity
    FROM Production.ProductInventory p
    WHERE p.ProductID = @ProductID;

    IF @UnitPrice IS NULL
    BEGIN
        SELECT @UnitPrice = StandardCost
        FROM Production.Product
        WHERE ProductID = @ProductID;
    END

    IF @Discount IS NULL
    BEGIN
        SET @Discount = 0;
    END

    -- Check stock
    IF @ProductStock < @Quantity
    BEGIN
        PRINT 'Failed to place the order. Insufficient stock.';
        RETURN;
    END

    BEGIN TRANSACTION;

    -- Insert order detail
    INSERT INTO Sales.SalesOrderDetail (SalesOrderID,SalesOrderDetailID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount,SpecialOfferID)
    VALUES (@OrderID,@salesOrderDetailID, @ProductID, @UnitPrice, @Quantity, @Discount,@spoferID);

    -- Update stock
    UPDATE Production.ProductInventory
    SET Quantity =Quantity  - @Quantity
    WHERE ProductID = @ProductID;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    COMMIT TRANSACTION;
END;

-- sample data for testing
-- Insert a new order detail with sufficient stock
EXEC InsertOrderDetailses @OrderID = 2,@salesOrderDetailID=1, @ProductID = 1, @UnitPrice = NULL, @Quantity = 5, @Discount = NULL,@spoferID=1;
-- Expected: Successfully inserts the order detail and updates the stock.

-- Insert a new order detail with insufficient stock
EXEC InsertOrderDetailses @OrderID = 2,@salesOrderDetailID=2, @ProductID = 3, @UnitPrice = NULL, @Quantity = 100, @Discount = NULL,@spoferID=2;
-- Expected: Fails to place the order and prints a message about insufficient stock.


--Question No 2
-- Create a procedure UpdateOrderDetails that takes OrderID, ProductID, Unit Price, Quantity, and discount, and updates these values for that ProductID in that Order. All the parameters
-- except the OrderID and ProductID should be optional so that if the user wants to only update Quantity s/he should be able to do so without providing the rest of the values. You need 
-- also make sure that if any of the values are being passed in as NULL, then you want to retain the original value instead of overwriting it with NULL. To accomplish this, look for the
-- ISNULL() function in google or sql server books online. Adjust the UnitsInStock value in products table accordingly.


CREATE PROCEDURE UpdateOrderDetail
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(10, 2) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(4, 2) = NULL
AS
BEGIN
    DECLARE @OriginalUnitPrice DECIMAL(10, 2);
    DECLARE @OriginalQuantity INT;
    DECLARE @OriginalDiscount DECIMAL(4, 2);

    SELECT @OriginalUnitPrice = UnitPrice, @OriginalQuantity = OrderQty, @OriginalDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    IF @UnitPrice IS NULL
    BEGIN
        SET @UnitPrice = @OriginalUnitPrice;
    END

    IF @Quantity IS NULL
    BEGIN
        SET @Quantity = @OriginalQuantity;
    END

    IF @Discount IS NULL
    BEGIN
        SET @Discount = @OriginalDiscount;
    END

    -- Update order detail
    UPDATE Sales.SalesOrderDetail
    SET UnitPrice = @UnitPrice, OrderQty = @Quantity, UnitPriceDiscount = @Discount
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to update the order details. Please try again.';
    END
END;



--Sample data for testing
-- Update an order detail to change the unit price and discount

EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1, @UnitPrice = 20.00, @Quantity = NULL, @Discount = 0.05;
-- Expected: Updates the UnitPrice to 20.00 and Discount to 0.05 for the specified order detail.

-- Update an order detail with no changes
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 2, @UnitPrice = NULL, @Quantity = NULL, @Discount = NULL;
-- Expected: No changes made to the order detail.


--Question No 3
-- Create a procedure GetOrderDetails that takes OrderID as input parameter and returns all the records for that OrderID. If no records are found in Order Details table, then it should
-- print the line: "The OrderID XXXX does not exits", where XXX should be the OrderlD entered by user and the procedure should RETURN the value 1.



CREATE PROCEDURE GetOrderDetail
    @OrderID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID;
END;


--Sample data for Testing Procedure GetOrderDetails
-- Get details of an existing order
EXEC GetOrderDetails @OrderID = 1;
-- Expected: Returns the details for OrderID 1.

-- Get details of a non-existing order
EXEC GetOrderDetails @OrderID = 999;
-- Expected: Prints a message that the OrderID does not exist and returns 1.


--Question No 4
-- Create a procedure DeleteOrderDetails that takes OrderID and ProductID and deletes that from Order Details table. Your procedure should validate parameters. It should retum an error
-- code (-1) and print a message if the parameters are invalid. Parameters are valid if the given order ID appears in the table and if the given product ID appears in that order.


CREATE PROCEDURE DeleteOrderDetail
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Invalid OrderID or ProductID';
        RETURN -1;
    END

    DELETE FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to delete the order details. Please try again.';
    END
END;

--Sample data for Testing Procedure DeleteOrderDetails
-- Delete an existing order detail
EXEC DeleteOrderDetails @OrderID = 1, @ProductID = 2;
-- Expected: Deletes the order detail with OrderID 1 and ProductID 2.

-- Delete a non-existing order detail
EXEC DeleteOrderDetails @OrderID = 1, @ProductID = 999;
-- Expected: Prints an error message about invalid OrderID or ProductID and returns -1.



-- Functions
-----------------


-- Create a function that takes an input parameter type datetime and returns the date in the format MM/DD/YYYY. For example if I pass in 2006-11-21 23:34:05.920', the output of the
--  functions should be 11/21/2006


CREATE FUNCTION FormatDate_MMDDYYYY (@datetime datetime)
RETURNS varchar(10)
AS
BEGIN
    RETURN CONVERT(varchar(10), CONVERT(date, @datetime), 101)
END


-- Format date to MM/DD/YYYY
SELECT FormatDate_MMDDYYYY('2023-05-27 14:45:00') AS FormattedDate;
-- Expected: Returns '05/27/2023'



-- Create a function that takes an input parameter type datetime and returns the date in the fonnat YYYYMMDD



CREATE FUNCTION FormatDate_YYYYMMDD (@datetime datetime)
RETURNS varchar(10)
AS
BEGIN
    RETURN CONVERT(varchar(10), CONVERT(date, @datetime), 112)
END

-- Format date to YYYYMMDD
SELECT FormatDate_YYYYMMDD('2023-05-27 14:45:00') AS FormattedDate;
-- Expected: Returns '20230527'


-- Views
------------------

-- Create a view vwCustomerOrders which returns CompanyName OrderID.OrderDate, ProductID ProductName Quantity UnitPrice.Quantity od. UnitPrice

CREATE VIEW vwCustomerOrders AS
SELECT 
    c.CompanyName,
    o.SalesOrderID AS OrderID,
    o.OrderDate,
    od.ProductID,
    od.UnitPrice,
    od.OrderQty,
    od.UnitPrice * od.OrderQty AS TotalPrice
FROM 
    Sales.SalesOrderHeader o
JOIN 
    Sales.SalesOrderDetail od ON o.SalesOrderID = od.SalesOrderID
JOIN 
    Sales.Customer c ON o.CustomerID = c.CustomerID;




-- Create a copy of the above view and modify it so that it only returns the above information for orders that were placed yesterday


CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT c.CompanyName, od.OrderID, od.OrderDate, p.ProductName, od.Quantity, od.UnitPrice
FROM Sales.OrderDetails od INNER JOIN Products p ON od.ProductID = p.ProductID INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE CAST(od.OrderDate AS date) = CAST(GETDATE() - 1 AS date)


-- Use a CREATE VIEW statement to create a view called MyProducts. Your view should contain the ProductID, ProductName, QuantityPerUnit and Unit Price columns from the Products table. It
-- should also contain the CompanyName column from the Suppliers table and the CategoryName column from the Categories table. Your view should only contain products that are 
-- not discontinued. 


-- Create view MyProducts
CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName,
    c.CategoryName
FROM 
    Products p
INNER JOIN 
    Suppliers s ON p.SupplierID = s.SupplierID
INNER JOIN 
    Categories c ON p.CategoryID = c.CategoryID
WHERE 
    p.Discontinued IS NULL;




	-- View customer orders
SELECT * FROM vwCustomerOrders;
-- Expected: Returns customer orders with calculated TotalPrice.
-- View product details
SELECT * FROM MyProducts;
-- Expected: Returns product details including supplier and category names, and excludes discontinued products.



-- Triggers
-------------------

-- If someone cancels an order in northwind database, then you want to delete that order from the Orders table. But you will not be able to delete that Order before deleting the records 
-- from Order Details table for that particular order due to referential integrity constraints. Create an Instead of Delete trigger on Orders table so that if some one tries to delete an
-- Order that trigger gets fired and that trigger should first delete everything in order details table and then delete that order from the Orders table


-- Create INSTEAD OF DELETE trigger on Orders table
CREATE TRIGGER trg_InsteadOfDeleteOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Declare a variable to hold the OrderID
    DECLARE @OrderID INT;

    -- Use a cursor to handle multiple rows
    DECLARE cur CURSOR FOR
    SELECT OrderID
    FROM DELETED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @OrderID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Delete from Order Details table where OrderID matches
        DELETE FROM [Order Details]
        WHERE OrderID = @OrderID;

        -- Delete from Orders table where OrderID matches
        DELETE FROM Orders
        WHERE OrderID = @OrderID;

        -- Fetch the next row
        FETCH NEXT FROM cur INTO @OrderID;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;



-- When an order is placed for X units of product Y, we must first check the Products table to ensure that there is sufficient stock to fill the order. This trigger will operate on the
-- Order Details table. If sufficient stock exists, then fill the order and decrement X units from the UnitsInStock column in Products. If insufficient stock exists, then refuse the order
-- (le. do not insert it) and notify the user that the order could not be filled because of insufficient stock.
 


-- Create INSTEAD OF INSERT trigger on Order Details table
CREATE TRIGGER trg_CheckStockBeforeInsert
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @OrderID INT, @ProductID INT, @Quantity INT, @UnitsInStock INT;

    -- Cursor to handle multiple rows
    DECLARE cur CURSOR FOR
    SELECT OrderID, ProductID, Quantity
    FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @OrderID, @ProductID, @Quantity;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check the UnitsInStock for the product
        SELECT @UnitsInStock = UnitsInStock
        FROM Products
        WHERE ProductID = @ProductID;

        -- If there is sufficient stock, proceed with the insert and update stock
        IF @UnitsInStock >= @Quantity
        BEGIN
            -- Insert the row into Order Details
            INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
            SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
            FROM INSERTED
            WHERE ProductID = @ProductID AND OrderID = @OrderID;

            -- Update the UnitsInStock in Products
            UPDATE Products
            SET UnitsInStock = UnitsInStock - @Quantity
            WHERE ProductID = @ProductID;
        END
        ELSE
        BEGIN
            -- Raise an error for insufficient stock
            RAISERROR ('Insufficient stock for ProductID %d. Order cannot be placed.', 16, 1, @ProductID);
        END

        -- Fetch the next row
        FETCH NEXT FROM cur INTO @OrderID, @ProductID, @Quantity;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;


-- Attempt to insert an order detail with sufficient stock
INSERT INTO Sales.SalesOrderDetail (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES (2, 1, 18.00, 10, 0);
-- Expected: Successfully inserts the order detail and updates the stock.

-- Attempt to insert an order detail with insufficient stock
INSERT INTO Sales.SalesOrderDetails(OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES (2, 3, 10.00, 100, 0);
-- Expected: Fails due to insufficient stock, and prints an error message.
