-- DROPPING TABLES
print('Dropping tables...')
DROP TABLE Card
GO
DROP TABLE Account
GO
DROP TABLE Client
GO
DROP TABLE SocialStatus
GO
DROP TABLE Branch
GO
DROP TABLE City
GO
DROP TABLE Bank
GO
USE master
GO
ALTER DATABASE Banks
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE Banks
GO

-- CREATING TABLES
print('Creating tables...')
CREATE DATABASE Banks
GO

USE Banks
GO

CREATE TABLE Bank (
  Id INT IDENTITY PRIMARY KEY,
  Name VARCHAR(20)
);
GO

CREATE TABLE City (
  Id INT IDENTITY PRIMARY KEY,
  Name VARCHAR(20)
);
GO

CREATE TABLE Branch (
  BankId INT REFERENCES Bank(Id),
  CityId INT REFERENCES City(Id)
);
GO

CREATE TABLE SocialStatus (
  Id INT IDENTITY PRIMARY KEY,
  Name VARCHAR(20)
);
GO

CREATE TABLE Client (
  Id INT IDENTITY PRIMARY KEY,
  Name VARCHAR(20),
  SocialStatusId INT REFERENCES SocialStatus(Id)
);
GO

CREATE TABLE Account (
  Id INT IDENTITY PRIMARY KEY,
  Balance INT,
  ClientId INT REFERENCES Client(Id),
  BankId INT REFERENCES Bank(Id)
);
GO

CREATE TABLE Card (
  Id INT IDENTITY PRIMARY KEY,
  Balance INT,
  AccountId INT REFERENCES Account(Id)
);
GO

--INSERTING VALUES
print('Inserting values...')

INSERT INTO Bank(Name)
VALUES
('Priorbank'),
('Alfabank'),
('Sberbank'),
('Belarusbank'),
('Belinvestbank')
GO
--SELECT Name FROM Bank
--GO

INSERT INTO City(Name)
VALUES
('Minsk'),
('Gomel'),
('Moscow'),
('Warsaw'),
('Riga')
GO
--SELECT Name FROM City
--GO

INSERT INTO Branch(BankId, CityId) VALUES
(4,1),
(1,2),
(4,2),
(3,2),
(2,3),
(5,3),
(3,3),
(1,4),
(2,4),
(5,4),
(2,5);
GO
--SELECT * FROM Branch
--GO

INSERT INTO SocialStatus(Name) VALUES
('Student'),
('Worker'),
('Unemployed'),
('Retiree'),
('Disabled')
GO
--SELECT Name FROM SocialStatus
--GO

INSERT INTO Client (Name, SocialStatusId) VALUES
('John', 1),    
('James', 1),  
('Michael', 2), 
('Linda', 2),  
('Anna', 3),    
('Emily', 3),   
('Robert', 4),    
('David', 4),
('Sarah', 1),   
('Sophia', 2), 
('NoCard', 3); 
GO
--SELECT * FROM Client
--GO

INSERT INTO Account (Balance, ClientId, BankId) VALUES
(500, 1, 1),
(300, 1, 2),
(0, 2, 2),
(700, 2, 3),
(700, 3, 3),
(400, 3, 4),
(1000, 4, 4),
(600, 4, 5),
(500, 5, 1),
(200, 5, 5),
(600, 6, 1),
(0, 7, 2),
(800, 8, 3),
(900, 9, 4),
(200, 10, 5),
(200, 11, 5);
GO
--SELECT * FROM Account
--GO

INSERT INTO Card (Balance, AccountId) VALUES
(500, 1),
(300, 2),
(0, 2),
(300, 3),
(200, 3),
(700, 4),
(400, 5),
(500, 5),
(100, 6),
(300, 6),
(500, 7),
(400, 7),
(600, 8),
(200, 9),
(400, 10),
(100, 10),
(100, 11),
(500, 12),
(300, 13),
(400, 14),
(500, 14),
(200, 15);
GO
--SELECT * FROM Card
--GO

-- TASK 1
-- 1.Покажи мне список банков у которых есть филиалы в городе X (выбери один из городов)
print('Task 1')

SELECT Bank.Name
FROM Bank
	INNER JOIN Branch ON Branch.BankId = Bank.Id
	INNER JOIN City ON City.Id = Branch.CityId
WHERE City.Name = 'Gomel'

-- TASK 2
-- 2. Получить список карточек с указанием имени владельца, баланса и названия банка
print('Task 2')

SELECT c.Id, c.Balance, cl.Name, b.Name
FROM Card c
	INNER JOIN Account a ON a.Id = c.AccountId 
	INNER JOIN Client cl ON cl.Id = a.ClientId
	INNER JOIN Bank b ON b.Id = a.BankId


-- TASK 3
-- 3. Показать список банковских аккаунтов у которых баланс не совпадает с суммой баланса по карточкам.
-- В отдельной колонке вывести разницу
print('Task 3')

SELECT Account.Id AS AccountId, Account.Balance AS AccountBalance, 
	(SELECT SUM(Card.Balance)
	 FROM Card
	 WHERE Card.AccountId = Account.Id
	) AS CardsBalance
FROM Account
GO

--SELECT Account.Id AS AccountId, ABS(Account.Balance -
--	(SELECT SUM(Card.Balance)
--	 FROM Card
--	 WHERE Card.AccountId = Account.Id
--	)) AS BalanceDifference
--FROM Account
--WHERE Account.Balance -
--	(SELECT SUM(Card.Balance)
--	 FROM Card
--	 WHERE Card.AccountId = Account.Id
--	) != 0
--GO


SELECT Account.Id, Account.Balance AS AccountBalance, ABS(Account.Balance - ISNULL(SUM(Card.Balance), 0)) AS BalanceDifference
FROM Account
	 LEFT JOIN Card ON Card.AccountId = Account.Id
GROUP BY Account.Id, Account.Balance
HAVING Account.Balance - ISNULL(SUM(Card.Balance), 0) != 0


-- TASK 4
-- 4. Вывести кол-во банковских карточек для каждого соц статуса
-- (2 реализации, GROUP BY и подзапросом)
print('Task 4')
--SELECT SocialStatus.Name AS SocialStatus, COUNT(*) AS CardAmounts
--FROM Card
--	INNER JOIN Account ON Card.AccountId = Account.Id
--	INNER JOIN Client ON Account.ClientId = Client.Id
--	INNER JOIN SocialStatus ON Client.SocialStatusId = SocialStatus.Id
--GROUP BY SocialStatus.Name
--ORDER BY CardAmounts DESC
--GO


SELECT SocialStatus.Name AS SocialStatus,
	(SELECT COUNT(*)
	 FROM Card
		INNER JOIN Account ON Card.AccountId = Account.Id
		INNER JOIN Client ON Account.ClientId = Client.Id
		WHERE Client.SocialStatusId = SocialStatus.Id
	) AS CardAmounts
FROM SocialStatus
GO

-- TASK 5
-- 5. Написать stored procedure которая будет добавлять по 10$ на каждый банковский аккаунт для определенного соц статуса
--(У каждого клиента бывают разные соц. статусы. Например, пенсионер, инвалид и прочее). 
-- Входной параметр процедуры - Id социального статуса. Обработать исключительные ситуации 
-- (например, был введен неверные номер соц. статуса. Либо когда у этого статуса нет привязанных аккаунтов).
print('Task 5')
GO

CREATE PROCEDURE AddMoneyForSocialStatus 
	@SocialStatusId INT
AS
BEGIN
	IF @SocialStatusId NOT IN (SELECT SocialStatus.Id FROM SocialStatus)
		THROW 50001, 'Invalid social status', 1;

	UPDATE Account
	SET Account.Balance = Account.Balance + 10
	WHERE Account.Id IN
		(
		SELECT Account.Id
		FROM Account
			INNER JOIN Client ON Account.ClientId = Client.Id
		WHERE Client.SocialStatusId = @SocialStatusId 
		)
	
	IF @@ROWCOUNT = 0
		THROW 50002, 'There are no accounts with such social status', 1;
END
GO

SELECT Account.Balance
FROM Account

DECLARE @SocialStatusId INT
SET @SocialStatusId = 5

BEGIN TRY
	EXEC AddMoneyForSocialStatus @SocialStatusId
	
	SELECT Account.Balance
	FROM Account
END TRY
BEGIN CATCH
	PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER()) + ':' + ERROR_MESSAGE()
END CATCH
GO


DROP PROCEDURE AddMoneyForSocialStatus
GO

-- TASK 6
-- 6. Получить список доступных средств для каждого клиента. То есть если у клиента на банковском аккаунте 60 рублей,
-- и у него 2 карточки по 15 рублей на каждой, то у него доступно 30 рублей для перевода на любую из карт
print('Task 6')

SELECT Account.Balance AS AccountBalance, 
	(SELECT SUM(Card.Balance)
	 FROM Card
	 WHERE Card.AccountId = Account.Id
	) AS CardsBalance
FROM Account
GO

SELECT Account.Id AS AccountId,
	Client.Name, 
	Account.Balance - (SELECT ISNULL(SUM(Card.Balance), 0)
					   FROM Card 
					   WHERE Card.AccountId = Account.Id) AS BalanceAvailable
FROM Client
	LEFT JOIN Account ON Account.ClientId = Client.Id
	LEFT JOIN Card ON Card.AccountId = Account.Id
GROUP BY Client.Name, Account.Id, Account.Balance
HAVING Account.Balance - (SELECT ISNULL(SUM(Card.Balance), 0)
					   FROM Card 
					   WHERE Card.AccountId = Account.Id) > 0

-- TASK 7
-- 7. Написать процедуру которая будет переводить определённую сумму со счёта на карту этого аккаунта. 
-- При этом будем считать что деньги на счёту все равно останутся, просто сумма средств на карте увеличится.

-- Например, у меня есть аккаунт на котором 1000 рублей и две карты по 300 рублей на каждой.
-- Я могу перевести 200 рублей на одну из карт, при этом баланс аккаунта останется 1000 рублей,
-- а на картах будут суммы 300 и 500 рублей соответственно. После этого я уже не смогу перевести 400 рублей
-- с аккаунта ни на одну из карт, так как останется всего 200 свободных рублей (1000-300-500). 
-- Переводить БЕЗОПАСНО. То есть использовать транзакцию
print('Task 7')
GO

CREATE PROCEDURE TransferMoney
	@AccountId INT,
	@CardId INT,
	@AmountOfMoney INT
AS
BEGIN
	DECLARE @AccountCardsBalance INT, @BalanceAvailable INT
	IF NOT EXISTS(SELECT * 
				  FROM Account
					INNER JOIN Card ON Card.AccountId = Account.Id
				  WHERE Account.Id = @AccountId AND Card.Id = @CardId)
		THROW 50003, 'There is no cards with such account id', 1;

	SET @AccountCardsBalance = (SELECT SUM(Card.Balance)
								FROM Card 
								WHERE Card.AccountId = @AccountId)

	SET @BalanceAvailable = (SELECT Account.Balance - @AccountCardsBalance
							 FROM Account
							 WHERE Account.Id = @AccountId)

	IF @BalanceAvailable <= 0
		THROW 50004, 'There is no money available', 1;
	IF @BalanceAvailable - @AmountOfMoney < 0
		THROW 50005, 'There is not enough money for transaction', 1;

	BEGIN TRANSACTION 
		BEGIN TRY
			UPDATE Card
			SET Card.Balance = Card.Balance + @AmountOfMoney
			WHERE Card.Id = @CardId
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
			THROW;
		END CATCH
END
GO

DECLARE @AccountId INT;
SET @AccountId = 13

SELECT Account.Balance
FROM Account
WHERE Account.Id = @AccountId

-- show available cards and their balance for particular account
SELECT Card.Id AS CardsAvailableId, Card.Balance 
FROM Account
	INNER JOIN Card ON Card.AccountId = Account.Id
	WHERE Account.Id = @AccountId

EXEC TransferMoney @AccountId, 19, 300

-- show accounts available balance after procedure
SELECT Account.Id AS AccountId,
	Client.Name, 
	Account.Balance - (SELECT ISNULL(SUM(Card.Balance), 0)
					   FROM Card 
					   WHERE Card.AccountId = Account.Id) AS BalanceAvailable
FROM Client
	LEFT JOIN Account ON Account.ClientId = Client.Id
	LEFT JOIN Card ON Card.AccountId = Account.Id
GROUP BY Client.Name, Account.Id, Account.Balance
HAVING Account.Balance - (SELECT ISNULL(SUM(Card.Balance), 0)
					   FROM Card 
					   WHERE Card.AccountId = Account.Id) > 0

DROP PROCEDURE TransferMoney
GO

