CREATE DATABASE QLBida
GO

USE QLBida
GO

-- food, drinnk
-- table
-- foodcatagory, drinkcatagory
-- account
-- bill: bill chung
-- bill info: 1 bill nhieu mon an

CREATE TABLE TableFood
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên',
	status NVARCHAR(100) NOT NULL DEFAULT N'Trống',-- Trống || Có người
	timestart DATETIME NULL DEFAULT NULL
)
DBCC CHECKIDENT (TableFood, RESEED, 0); -- reset IDENTITY 
GO


CREATE TABLE Account 
(
	UserName NVARCHAR(100) PRIMARY KEY,
	DisplayName NVARCHAR(100) NOT NULL DEFAULT N'Dat',
	PassWord NVARCHAR(1000) NOT NULL DEFAULT 0,
	Type INT NOT NULL DEFAULT 0 -- 1: admin && 0: staff
)
GO

CREATE TABLE FoodCategory
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên'
)

DBCC CHECKIDENT (FoodCategory, RESEED, 1); -- reset IDENTITY cho id chạy bắt đầu từ 1
GO

CREATE TABLE Food
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên',
	idCategory INT NOT NULL,
	price FLOAT NOT NULL DEFAULT 0

	FOREIGN KEY (idCategory) REFERENCES dbo.FoodCategory(id)
)

DBCC CHECKIDENT (Food, RESEED, 0); -- reset IDENTITY cho id chạy bắt đầu từ 1
GO

CREATE TABLE Bill
(
	id INT IDENTITY PRIMARY KEY,
	DateCheckIn DATE NOT NULL DEFAULT GETDATE(),
	DateCheckOut DATE,
	idTable INT NOT NULL,
	status INT NOT NULL DEFAULT 0, -- 1: Đã thanh toàn && 0: Chưa thanh toán
	discount INT DEFAULT 0,
	totalPrice FLOAT DEFAULT 0
	FOREIGN KEY (idTable) REFERENCES dbo.TableFood(id)
)
DBCC CHECKIDENT (Bill, RESEED, 0); -- reset IDENTITY cho id chạy bắt đầu từ 1
GO

CREATE TABLE BillInfo
(
	id INT IDENTITY PRIMARY KEY,
	idBill INT NOT NULL,
	idFood INT NOT NULL,
	count INT NOT NULL DEFAULT 0

	FOREIGN KEY (idBill) REFERENCES dbo.Bill(id),
	FOREIGN KEY (idFood) REFERENCES dbo.Food(id)
)

DBCC CHECKIDENT (BillInfo, RESEED, 0); -- reset IDENTITY cho id chạy bắt đầu từ 1
GO

INSERT INTO dbo.Account
	   ( UserName, 
		 DisplayName,
		 PassWord,
		 Type
	   )
VALUES ( N'K9',
		 N'RongK9',
		 N'1',
		 1
	   )

INSERT INTO dbo.Account
	   ( UserName, 
		 DisplayName,
		 PassWord,
		 Type
	   )
VALUES ( N'staff',
		 N'staff',
		 N'1',
		 0
	   )
GO

-- Tim user bang ten dang nhap
CREATE PROC USP_GetAccountByUserName 
@userName nvarchar(100)
AS
BEGIN
	SELECT * FROM dbo.Account WHERE UserName = @userName
END
GO

--EXEC dbo.USP_GetAccountByUserName @userName = N'K9' -- nvarchar(50)

-- Login
CREATE PROC USP_Login
@userName nvarchar(100), @passWord nvarchar(100)
AS
BEGIN
	SELECT * FROM dbo.Account WHERE UserName = @userName AND PassWord = @passWord
END
GO

-- Thêm 10 bàn mẫu
DECLARE @i INT = 0

WHILE @i <= 10
BEGIN
	INSERT dbo.TableFood (name) VALUES (N'Bàn ' + CAST(@i AS nvarchar(100)))
	SET @i = @i + 1
END 
GO

-- Lay danh sach ban
CREATE PROC USP_GetTableList
AS SELECT * FROM dbo.TableFood
GO

-- Thêm category
INSERT dbo.FoodCategory
	(name)
VALUES (N'Đồ ăn vặt')
INSERT dbo.FoodCategory
	(name)
VALUES (N'Nước uống') 
INSERT dbo.FoodCategory
	(name)
VALUES (N'Cơm')
INSERT dbo.FoodCategory
	(name)
VALUES (N'Trái cây')

INSERT dbo.FoodCategory
	(name)
VALUES (N'Xúc xích')

GO
-- Thêm món ăn
INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Bánh tráng trộn', 1, 10000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Tóp mỡ', 1, 15000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Sting', 2, 10000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Coca', 2, 10000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Cơm gà', 3, 25000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Cơm trộn', 3, 30000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Trái cây dĩa', 4, 20000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Trái cây tô', 4, 20000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Xúc xích Pony', 5, 20000)

INSERT dbo.Food
	(name, idCategory, price)
VALUES (N'Xúc xích Đức', 5, 20000)

GO
-- Insert bill
CREATE PROC USP_InsertBill
@idTable INT
AS 
BEGIN
	INSERT INTO Bill(
		DateCheckIn,
		DateCheckOut,
		idTable,
		status,
		discount
	) 
	VALUES(
		GETDATE(),
		NULL,
		@idTable,
		0,
		0
	)
END
GO

-- InsertBillInfo
CREATE PROC USP_InsertBillInfo
@idBill INT, @idFood INT, @count INT 
AS
BEGIN

	DECLARE @isExistBillInfo INT
	DECLARE @foodCount INT = 1

	SELECT @isExistBillInfo = id, @foodCount = b.count 
	FROM dbo.BillInfo AS b 
	WHERE idBill = @idBill AND idFood = @idFood

	IF (@isExistBillInfo > 0)
	BEGIN
		DECLARE @newCount INT = @foodCount + @count
		IF (@newCount > 0)
			UPDATE dbo.BillInfo SET count = @foodCount + @count WHERE idFood = @idFood
		ELSE 
			DELETE dbo.BillInfo WHERE idBill = @idBill AND idFood = @idFood
	END
	ELSE 
	BEGIN
		INSERT dbo.BillInfo
				(idBill,
				idFood,
				count )
		VALUES (@idBill, 
				@idFood,
				@count
		)
	END
END
GO


-- Tao trigger khi BillInfo duoc update
CREATE TRIGGER UTG_UpdateBillInfo
ON dbo.BillInfo FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @idBill INT

	SELECT @idBill = idBill FROM Inserted
	
	DECLARE @idTable INT

	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill AND status = 0

	UPDATE dbo.TableFood SET status = N'Có người' WHERE id = @idTable

END
GO

-- Tao trigger khi Bill duoc update
CREATE TRIGGER UTG_UpdateBill
ON dbo.Bill FOR UPDATE
AS
BEGIN
	DECLARE @idBill INT

	SELECT @idBill = id FROM Inserted
	
	DECLARE @idTable INT

	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill

	DECLARE @count int = 0

	SELECT @count = COUNT(*) FROM dbo.Bill WHERE idTable = @idTable AND status = 0

	IF (@count = 0)
		UPDATE dbo.TableFood SET status = N'Trống' WHERE id = @idTable
END
GO

CREATE TRIGGER UTG_DeleteBillInfo
ON BillInfo FOR DELETE
AS 
BEGIN
	DECLARE @idBillInfo INT
	DECLARE @idBill INT
	SELECT @idBillInfo = id, @idBill = Deleted.idBill FROM Deleted

	DECLARE @idTable INT
	SELECT @idTable = idTable FROM Bill WHERE id = @idBill
	
	DECLARE @count INT = 0

	SELECT @count = COUNT(*) FROM BillInfo AS bi, Bill AS b WHERE b.id = bi.idBill AND b.id = @idBill AND b.status = 0

	IF (@count = 0)
		UPDATE TableFood SET status = N'Trống' WHERE id = @idTable

END
GO

-- Lay list bang ngay
CREATE PROC USP_GetListBillByDate
@checkIn DATE, @checkOut DATE
AS
BEGIN
	SELECT t.name, DateCheckIn, DateCheckOut, discount, totalPrice
	FROM Bill AS b, TableFood AS t
	WHERE DateCheckIn >= @checkIn AND DateCheckOut <= @checkOut AND b.status = 1
	AND t.id = b.idTable
END
GO


-- Update tai khoan
CREATE PROC USP_UpdateAccount
@userName NVARCHAR(100), @displayName NVARCHAR(100), @password NVARCHAR(100), @newPassWord NVARCHAR(100)
AS
BEGIN
	DECLARE @isRightPass INT = 0
	SELECT @isRightPass = COUNT(*) FROM Account WHERE UserName = @userName AND PassWord = @password

	IF (@isRightPass = 1)
	BEGIN
		IF (@newPassWord = NULL OR @newPassWord = '')
		BEGIN
			UPDATE Account SET DisplayName = @displayName WHERE UserName = @userName
		END
		ELSE
			UPDATE Account SET DisplayName = @displayName, PassWord = @newPassWord WHERE UserName = @userName
	END
END
GO