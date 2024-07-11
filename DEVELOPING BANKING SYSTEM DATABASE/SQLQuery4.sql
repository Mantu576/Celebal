--                                                    PROJECT ON
--                                           DEVELOPING BANKING SYSTEM DATABASE
--                                           SUBMITTED BY MANTU PAL


-- Table Definitions

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    DateOfBirth DATE,
    Address NVARCHAR(255),
    PhoneNumber NVARCHAR(15),
    Email NVARCHAR(50)
);

CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY IDENTITY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    AccountType NVARCHAR(20),
    Balance DECIMAL(18, 2),
    CreatedDate DATE
);

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY,
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID),
    TransactionType NVARCHAR(20),
    Amount DECIMAL(18, 2),
    TransactionDate DATE,
    Description NVARCHAR(255)
);

-- Stored Procedures
CREATE PROCEDURE CreateCustomer
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @DateOfBirth DATE,
    @Address NVARCHAR(255),
    @PhoneNumber NVARCHAR(15),
    @Email NVARCHAR(50)
AS
BEGIN
    INSERT INTO Customers (FirstName, LastName, DateOfBirth, Address, PhoneNumber, Email)
    VALUES (@FirstName, @LastName, @DateOfBirth, @Address, @PhoneNumber, @Email);
END;

--NEW ACCOUNT OPPENING
CREATE PROCEDURE OpenAccount
    @CustomerID INT,
    @AccountType NVARCHAR(20),
    @InitialDeposit DECIMAL(18, 2)
AS
BEGIN
    INSERT INTO Accounts (CustomerID, AccountType, Balance, CreatedDate)
    VALUES (@CustomerID, @AccountType, @InitialDeposit, GETDATE());
END;
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY,
    Username NVARCHAR(50) UNIQUE,
    PasswordHash NVARCHAR(255),
    Role NVARCHAR(20)
);

CREATE TABLE UserRoles (
    RoleID INT PRIMARY KEY IDENTITY,
    RoleName NVARCHAR(50)
);
CREATE PROCEDURE RegisterUser
    @Username NVARCHAR(50),
    @PasswordHash NVARCHAR(255),
    @Role NVARCHAR(20)
AS
BEGIN
    INSERT INTO Users (Username, PasswordHash, Role)
    VALUES (@Username, @PasswordHash, @Role);
END;

CREATE PROCEDURE AuthenticateUser
    @Username NVARCHAR(50),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SELECT UserID, Role FROM Users
    WHERE Username = @Username AND PasswordHash = @PasswordHash;
END;
CREATE TABLE OnlineBankingUsers (
    UserID INT PRIMARY KEY IDENTITY,
    CustomerID INT,
    Username NVARCHAR(50) UNIQUE,
    PasswordHash NVARCHAR(255),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
CREATE PROCEDURE RegisterOnlineUser
    @CustomerID INT,
    @Username NVARCHAR(50),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    INSERT INTO OnlineBankingUsers (CustomerID, Username, PasswordHash)
    VALUES (@CustomerID, @Username, @PasswordHash);
END;

CREATE PROCEDURE AuthenticateOnlineUser
    @Username NVARCHAR(50),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SELECT UserID FROM OnlineBankingUsers
    WHERE Username = @Username AND PasswordHash = @PasswordHash;
END;
CREATE TABLE ATMTransactions (
    ATMTransactionID INT PRIMARY KEY IDENTITY,
    AccountID INT,
    TransactionType NVARCHAR(50),
    Amount DECIMAL(18, 2),
    TransactionDate DATETIME,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);
--WITHDRAWING MONEY FROM ATM
CREATE PROCEDURE ATMWithdraw
    @AccountID INT,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Balance DECIMAL(18, 2);
    SELECT @Balance = Balance FROM Accounts WHERE AccountID = @AccountID;

    IF @Balance >= @Amount
    BEGIN
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @AccountID;

        INSERT INTO ATMTransactions (AccountID, TransactionType, Amount, TransactionDate)
        VALUES (@AccountID, 'Withdrawal', @Amount, GETDATE());
    END
    ELSE
    BEGIN
        RAISERROR('Insufficient funds', 16, 1);
    END
END;

--DEPOSITING MONEY AT ATM
CREATE PROCEDURE ATMDeposit
    @AccountID INT,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    UPDATE Accounts
    SET Balance = Balance + @Amount
    WHERE AccountID = @AccountID;

    INSERT INTO ATMTransactions (AccountID, TransactionType, Amount, TransactionDate)
    VALUES (@AccountID, 'Deposit', @Amount, GETDATE());
END;

--ATM BALANCE INQUIRY
CREATE PROCEDURE ATMBalanceInquiry
    @AccountID INT
AS
BEGIN
    SELECT Balance FROM Accounts
    WHERE AccountID = @AccountID;
END;

--ATM MINI STATEMENT
CREATE PROCEDURE ATMMiniStatement
    @AccountID INT
AS
BEGIN
    SELECT TOP 5 * FROM ATMTransactions
    WHERE AccountID = @AccountID
    ORDER BY TransactionDate DESC;
END;





CREATE PROCEDURE DepositMoney
    @AccountID INT,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    UPDATE Accounts
    SET Balance = Balance + @Amount
    WHERE AccountID = @AccountID;

    INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
    VALUES (@AccountID, 'Deposit', @Amount, GETDATE(), 'Deposit to account');
END;

CREATE PROCEDURE WithdrawMoney
    @AccountID INT,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    DECLARE @CurrentBalance DECIMAL(18, 2);
    SELECT @CurrentBalance = Balance FROM Accounts WHERE AccountID = @AccountID;

    IF @CurrentBalance >= @Amount
    BEGIN
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @AccountID;

        INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
        VALUES (@AccountID, 'Withdrawal', @Amount, GETDATE(), 'Withdrawal from account');
    END
    ELSE
    BEGIN
        RAISERROR('Insufficient funds', 16, 1);
    END
END;

--MONEY TRANSFER
CREATE PROCEDURE TransferMoney
    @FromAccountID INT,
    @ToAccountID INT,
    @Amount DECIMAL(18, 2)
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @CurrentBalance DECIMAL(18, 2);
    SELECT @CurrentBalance = Balance FROM Accounts WHERE AccountID = @FromAccountID;

    IF @CurrentBalance >= @Amount
    BEGIN
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccountID;

        UPDATE Accounts
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccountID;

        INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
        VALUES (@FromAccountID, 'Transfer Out', @Amount, GETDATE(), 'Transfer to account ' + CAST(@ToAccountID AS NVARCHAR(10)));

        INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
        VALUES (@ToAccountID, 'Transfer In', @Amount, GETDATE(), 'Transfer from account ' + CAST(@FromAccountID AS NVARCHAR(10)));
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Insufficient funds', 16, 1);
    END

    COMMIT TRANSACTION;
END;

--TRANSACTION HISTORY
CREATE PROCEDURE ViewTransactionHistory
    @AccountID INT
AS
BEGIN
    SELECT * FROM Transactions
    WHERE AccountID = @AccountID
    ORDER BY TransactionDate DESC;
END;
CREATE TABLE Loans (
    LoanID INT PRIMARY KEY IDENTITY,
    CustomerID INT,
    LoanAmount DECIMAL(18, 2),
    InterestRate DECIMAL(5, 2),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(20),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE LoanRepayments (
    RepaymentID INT PRIMARY KEY IDENTITY,
    LoanID INT,
    RepaymentAmount DECIMAL(18, 2),
    RepaymentDate DATE,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID)
);
CREATE PROCEDURE ApplyForLoan
    @CustomerID INT,
    @LoanAmount DECIMAL(18, 2),
    @InterestRate DECIMAL(5, 2),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, StartDate, EndDate, Status)
    VALUES (@CustomerID, @LoanAmount, @InterestRate, @StartDate, @EndDate, 'Pending');
END;

CREATE PROCEDURE ApproveLoan
    @LoanID INT
AS
BEGIN
    UPDATE Loans
    SET Status = 'Approved'
    WHERE LoanID = @LoanID;
END;

CREATE PROCEDURE RepayLoan
    @LoanID INT,
    @RepaymentAmount DECIMAL(18, 2)
AS
BEGIN
    INSERT INTO LoanRepayments (LoanID, RepaymentAmount, RepaymentDate)
    VALUES (@LoanID, @RepaymentAmount, GETDATE());

    DECLARE @TotalRepayment DECIMAL(18, 2);
    SELECT @TotalRepayment = SUM(RepaymentAmount) FROM LoanRepayments WHERE LoanID = @LoanID;

    DECLARE @LoanAmount DECIMAL(18, 2);
    SELECT @LoanAmount = LoanAmount FROM Loans WHERE LoanID = @LoanID;

    IF @TotalRepayment >= @LoanAmount
    BEGIN
        UPDATE Loans
        SET Status = 'Repaid'
        WHERE LoanID = @LoanID;
    END;
END;
--ACCOUNT STATEMENT
CREATE PROCEDURE GenerateAccountStatement
    @AccountID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT * FROM Transactions
    WHERE AccountID = @AccountID AND TransactionDate BETWEEN @StartDate AND @EndDate
    ORDER BY TransactionDate DESC;
END;

CREATE PROCEDURE GenerateSummaryReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT AccountID, COUNT(*) AS TransactionCount, SUM(Amount) AS TotalAmount
    FROM Transactions
    WHERE TransactionDate BETWEEN @StartDate AND @EndDate
    GROUP BY AccountID;
END;


CREATE TABLE SupportTickets (
    TicketID INT PRIMARY KEY IDENTITY,
    CustomerID INT,
    IssueDescription NVARCHAR(255),
    Status NVARCHAR(20),
    CreatedDate DATETIME,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
CREATE PROCEDURE CreateSupportTicket
    @CustomerID INT,
    @IssueDescription NVARCHAR(255)
AS
BEGIN
    INSERT INTO SupportTickets (CustomerID, IssueDescription, Status, CreatedDate)
    VALUES (@CustomerID, @IssueDescription, 'Open', GETDATE());
END;

CREATE PROCEDURE UpdateSupportTicketStatus
    @TicketID INT,
    @Status NVARCHAR(20)
AS
BEGIN
    UPDATE SupportTickets
    SET Status = @Status
    WHERE TicketID = @TicketID;
END;

CREATE PROCEDURE ViewSupportTickets
    @CustomerID INT
AS
BEGIN
    SELECT * FROM SupportTickets
    WHERE CustomerID = @CustomerID
    ORDER BY CreatedDate DESC;
END;

SELECT * FROM Accounts;
EXEC CreateCustomer 'John', 'Doe', '1980-01-01', '123 Main St', '555-1234', 'john.doe@example.com';
EXEC CreateCustomer 'Joy', 'Das', '1981-01-01', '122 Main St', '545-1234', 'joy.das@example.com';
EXEC CreateCustomer 'Mantu', 'Pal', '2000-07-02', '121 Main St', '555-1235', 'mantu.pal@example.com';
select * from Customers;

EXEC OpenAccount 1, 'Checking', 1000.00;
EXEC OpenAccount 2, 'Checking', 2000.00;
EXEC OpenAccount 3, 'Savings', 5000.00;

EXEC DepositMoney 1, 500.00;
EXEC DepositMoney 2, 1000.00;
EXEC DepositMoney 3, 500.00;
EXEC WithdrawMoney 1, 200.00;
EXEC WithdrawMoney 2, 200.00;
EXEC WithdrawMoney 3, 200.00;


EXEC TransferMoney 1, 2, 50.00;
EXEC TransferMoney 1, 3, 50.00;
EXEC TransferMoney 2, 1, 50.00;
EXEC ViewTransactionHistory 1;
EXEC ViewTransactionHistory 2;
EXEC ViewTransactionHistory 3;
EXEC RegisterUser 'Mantu@200','Mana#2580','Customer';
EXEC RegisterUser 'Manu@200','Manu#2580','Customer';
EXEC RegisterUser 'Raja@201','Raja#2580','Customer';
EXEC RegisterUser 'Ram@101','ram#2580','Customer';
EXEC AuthenticateUser 'Mantu@200','Mana#2580';
EXEC AuthenticateUser 'Manu@200','Manu#2580';
EXEC AuthenticateUser 'Raja@201','Raja#2580';
EXEC AuthenticateUser 'ram@101','ram#2580';
EXEC AuthenticateOnlineUser 'Mantu@200','Mana#2580';
EXEC AuthenticateOnlineUser 'Manu@200','Manu#2580';
EXEC AuthenticateOnlineUser 'Raja@200','Raja#2580';
EXEC ATMWithdraw 1,200;
EXEC ATMWithdraw 2,200;
EXEC ATMWithdraw 3,200;
EXEC ATMDeposit 1,500;
EXEC ATMDeposit 2,500;
EXEC ATMDeposit 3,500;
EXEC ATMBalanceInquiry 1;
EXEC ATMBalanceInquiry 2;
EXEC ATMBalanceInquiry 3;

EXEC ATMMiniStatement 1;
EXEC ATMMiniStatement 2;
EXEC ATMMiniStatement 3;
EXEC ApplyForLoan 1,10000,7,'2024-05-26','2025-05-26';
EXEC ApplyForLoan 2,10000,7,'2024-05-26','2025-05-26';
EXEC ApproveLoan 1;
EXEC ApproveLoan 2;
SELECT * from Loans;
EXEC GenerateAccountStatement 1,'2024-05-20','2024-05-26';
EXEC GenerateAccountStatement 2,'2024-05-20','2024-05-26';
EXEC GenerateAccountStatement 3,'2024-05-20','2024-05-26';
EXEC GenerateSummaryReport '2024-05-10','2024-05-26';