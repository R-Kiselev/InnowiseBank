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
('Sarah', 5),   
('Sophia', 5), 
('NoAccount', 5); 
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

SELECT SocialStatus.Name AS SocialStatus, COUNT(*) AS CardAmounts
FROM Card
	INNER JOIN Account ON Card.AccountId = Account.Id
	INNER JOIN Client ON Account.ClientId = Client.Id
	INNER JOIN SocialStatus ON Client.SocialStatusId = SocialStatus.Id
GROUP BY SocialStatus.Name
ORDER BY CardAmounts DESC
GO


SELECT SocialStatus.Name AS SocialStatus,
	(SELECT COUNT(*)
	 FROM Card
		INNER JOIN Account ON Card.AccountId = Account.Id
		INNER JOIN Client ON Account.ClientId = Client.Id
		WHERE Client.SocialStatusId = SocialStatus.Id
	) AS CardAmounts
FROM SocialStatus
ORDER BY CardAmounts DESC
GO

