
--- SQL project Data Cleaning, normalization & exploring
---https://www.kaggle.com/datasets/abdulmalik1518/mobiles-dataset-2025



--- The first thing we want to do is create a database named [Mobiles Dataset (2025)] and import the .CSV file

---Let's explore our new dataset

SELECT *
FROM [Mobiles Dataset (2025)];



---Let's begin by getting rid of duplicate rows using CTE and window functions.

WITH Duplicates AS (
SELECT *, 
ROW_NUMBER () OVER( PARTITION BY [CompanyName]
      ,[ModelName]
      ,[MobileWeight]
      ,[RAM]
      ,[FrontCamera]
      ,[BackCamera]
      ,[Processor]
      ,[BatteryCapacity]
      ,[ScreenSize]
      ,[LaunchedPricePakistan]
      ,[LaunchedPriceIndia]
      ,[LaunchedPriceChina]
      ,[LaunchedPriceUSA]
      ,[LaunchedPriceDubai]
      ,[LaunchedYear]
	  ORDER BY [CompanyName] ) as row_num
FROM [Mobiles Dataset (2025)]
	)

	DELETE FROM  Duplicates
	WHERE  row_num > 1
	

---It's time to start a  table Normalization process
/* We'll create 4(four) tables: 1️ Companies (stores unique company names)
                                 2️ Models (stores model-specific details)
                                  3️ Specifications (stores technical details)
                                   4️ Prices (stores launch prices for different regions) */

--- 1️.Companies

--DROP TABLE Companies
CREATE TABLE Companies (
CompanyId INT PRIMARY KEY IDENTITY(1,1),
CompanyName Nvarchar(50));

INSERT INTO Companies
SELECT DISTINCT(CompanyName)
From [Mobiles Dataset (2025)]

SELECT *
FROM Companies
ORDER BY CompanyId

--- 2. Models

--DROP TABLE Models
CREATE TABLE Models(
ModelID INT PRIMARY KEY IDENTITY(1,1),
CompanyID INT,
ModelName VARCHAR(100),
LaunchedYear INT,
FOREIGN KEY (CompanyID) REFERENCES Companies(CompanyID)
);

INSERT INTO Models(CompanyID, ModelName,  LaunchedYear)
SELECT    c.CompanyID, M.ModelName,  M.LaunchedYear
FROM [Mobiles Dataset (2025)] AS M
JOIN Companies as c ON M.CompanyName = c.CompanyName;

SELECT *
FROM Models


--- 3. Specifications

--DROP TABLE Specifications
CREATE TABLE Specifications (
    SpecID INT PRIMARY KEY IDENTITY(1,1),
    ModelID INT,
    MobileWeight VARCHAR(50),
    RAM VARCHAR(50),
    FrontCamera VARCHAR(50),
    BackCamera VARCHAR(100),
    Processor VARCHAR(50),
    BatteryCapacity VARCHAR(50),
    ScreenSize VARCHAR(50),
    FOREIGN KEY (ModelID) REFERENCES Models(ModelID)
);

INSERT INTO Specifications(ModelID,MobileWeight,RAM,FrontCamera,BackCamera,Processor,BatteryCapacity,ScreenSize)
SELECT m.ModelID, mb.MobileWeight, mb.RAM, mb.FrontCamera, mb.BackCamera, mb.Processor, mb.BatteryCapacity, mb.ScreenSize
FROM [Mobiles Dataset (2025)] as mb 
JOIN Models AS m ON mb.ModelName = m.ModelName;


SELECT *
FROM Specifications


--- 4. Prices

--DROP TABLE Prices
CREATE TABLE Prices (
    PriceID INT PRIMARY KEY IDENTITY(1,1),
    ModelID INT,
    Country VARCHAR(50),
    LaunchedPrice VARCHAR(20),
    FOREIGN KEY (ModelID) REFERENCES Models(ModelID)
);

SELECT *
FROM Prices;
DELETE FROM Prices


INSERT INTO Prices (ModelID, Country, LaunchedPrice)
SELECT 
    m.ModelID, 
    Country,
    Price
FROM 
    [Mobiles Dataset (2025)] d
JOIN 
    Models m ON d.ModelName = m.ModelName
CROSS APPLY (VALUES
    ('Pakistan', d.LaunchedPricePakistan),
    ('India', d.LaunchedPriceIndia),
    ('China', d.LaunchedPriceChina),
    ('USA', d.LaunchedPriceUSA),
    ('Dubai', d.LaunchedPriceDubai)
) AS CountryPrices(Country, Price);



---We have in our Price table column 'LaunchedPrice' that contain values like this 'AED 28,888 ', so we need to split this column into 2, for that we are ALTERing our
---PRICE table by creating two new columns Price and Currency

ALTER TABLE Prices
ADD Price Decimal(10,2),
	Currency Varchar(10);

--- Here we are removing all characters like (,;.) by nested Replace() clause. UPDATE() is saving this query result in 'LaunchedPrice' table(by updating it)

UPDATE [dbo].[Prices]
SET LaunchedPrice = REPLACE((REPLACE(launchedPrice,',','')),'.','')
WHERE LaunchedPrice IS NOT null

UPDATE [dbo].[Prices]
SET LaunchedPrice =  REPLACE(LaunchedPrice, '¥13999', 'CNY 13999')
WHERE LaunchedPrice IS NOT null

---Slpitting  ‘LaunchedPrice’ column like 'AED 28,888' --> ‘AED’ AND ‘28888’, by UPDATING newly created columns Price and Currency. 
---CAST is not working here, so  TRY_CAST tries to convert the extracted number to DECIMAL(10,2). If conversion fails (e.g., invalid numeric value), it returns NULL instead of throwing an error.

UPDATE [dbo].[Prices]
SET  Currency =  LEFT(LaunchedPrice, CHARINDEX(' ', LaunchedPrice)) ,

	 Price =	CASE 
					WHEN launchedPrice LIKE '%Not available%' THEN null
					ELSE  TRY_CAST( (SUBSTRING(launchedPrice, PATINDEX('%[0-9]%', launchedPrice), LEN(launchedPrice))) AS Decimal(10,2))
					END
FROM [dbo].[Prices];

--- finishing touches deleting already splitted 'LaunchedPrices' column 

ALTER TABLE [dbo].[Prices]
DROP COLUMN LaunchedPrice;

---Dubai is not a country so we need to replace it with UAE
UPDATE [dbo].[Prices]
SET Country = 'UAE'
WHERE Country = 'Dubai';

--- Down below we need to divide some values in  'PRICE' column by 100 in order to correct the data formatting, 
---likely because the prices were stored in cents or had extra decimal places.

UPDATE Prices
SET Price =   Price / 100
	Where Price > 10000 AND Currency = 'USD'

ALTER TABLE PRICES
ADD In_USD DECIMAL(10,2);


---In our 'PRICES' table, the prices are associated with different currencies. 
---To standardize these currencies, we'd need to convert them to a common currency(USD).

UPDATE PRICES
SET In_USD  =   CASE 
					WHEN currency = 'INR' THEN price * 0.011 
					WHEN currency = 'PKR' THEN price * 0.0036
					WHEN currency = 'CNY' THEN price * 0.14
					WHEN currency = 'AED' THEN price * 0.27
					ELSE price
					END



SELECT *
FROM PRICES as p
JOIN Models as m ON p.modelId = m.modelId
WHERE  m.ModelName  LIKE '% Z Fold%'


UPDATE Prices
SET Currency = 'PKR' Where Currency ='Not'

UPDATE Prices
SET Price = 519999 
WHERE Price IS null and Country = 'Pakistan';

UPDATE Prices
SET Price = 14088
WHERE Price IS null and Country = 'China';




EXEC sp_help 'Prices'


---It's time for data exploration and basic analysis


---1 Write a query to get the total number of mobile phones (models) in each company.

SELECT C.CompanyName, COUNT((M.ModelID)) as model_count
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
GROUP BY   C.CompanyName
ORDER BY model_count DESC

---2 Find out how many models each company has launched in total and group them by the launch year.

SELECT C.CompanyName, M.LaunchedYear,COUNT((M.ModelID)) as model_count
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
GROUP BY   M.LaunchedYear,C.CompanyName
ORDER BY LaunchedYear DESC


---3 Find most expensive and cheap  brands

SELECT C.CompanyName, m.ModelName, p.Price, p.Currency
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
JOIN Prices as p ON m.ModelID = p.ModelID
WHERE Currency = 'USD'
ORDER BY Price DESC


---We need some  Price Analysis

---1. Find the average price of mobile phones across different countries.


SELECT p.Country, CEILING(AVG(in_USD))   AS AVG_price_USD
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
JOIN Prices as p ON m.ModelID = p.ModelID
GROUP BY p.Country,  p.Currency
ORDER BY AVG_price_USD DESC

---2. Determine the most expensive and least expensive mobile phone model for each country.

WITH Ranking AS (
SELECT  p.Country, c.CompanyName, m.ModelName, p.In_USD,
Dense_RANK() OVER(Partition BY COUNTRY ORDER BY in_USD DESC) as max_rank,
Dense_RANK() OVER(Partition BY COUNTRY ORDER BY in_USD ) as min_rank
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
JOIN Prices as p ON m.ModelID = p.ModelID
					)


SELECT Country, CompanyName, ModelName, In_USD
FROM Ranking
Where max_rank = 1  OR  min_rank=1

---3. Find the highest and lowest-priced mobile phones in a particular year.

WITH Ranking AS (
SELECT  p.Country, c.CompanyName, m.ModelName, p.In_USD, LaunchedYear,
Dense_RANK() OVER(Partition BY LaunchedYear ORDER BY in_USD DESC) as max_rank,
Dense_RANK() OVER(Partition BY LaunchedYear ORDER BY in_USD ) as min_rank
FROM [dbo].[Companies] as C
JOIN Models as M ON c.CompanyId = m.CompanyID
JOIN Prices as p ON m.ModelID = p.ModelID
					)


SELECT  Launchedyear, Country, CompanyName, ModelName, In_USD
FROM Ranking
Where max_rank = 1  OR  min_rank=1
