SELECT COUNT(*) FROM UserBehavior_train;

SELECT * FROM UserBehavior_train;

SELECT UserID, ProductID, Timestamps
FROM UserBehavior_train
GROUP BY UserID, ProductID, Timestamps
HAVING COUNT(1) > 1;

SELECT COUNT(UserID), COUNT(ProductID), COUNT(CategoryID), 
COUNT(BehaviorType), COUNT(Timestamps)
FROM UserBehavior_train;

ALTER TABLE UserBehavior_train
ADD Datee date, 
ADD Timee varchar(10);

UPDATE UserBehavior_train
SET Datee = FROM_UNIXTIME(Timestamps, '%Y-%m-%d'), Timee = FROM_UNIXTIME(Timestamps,'%k');

ALTER TABLE UserBehavior_train
ADD Hourr varchar(10);

UPDATE UserBehavior_train
SET Hourr = FROM_UNIXTIME(Timestamps,'%H');

SELECT MAX(Datee), MIN(Datee)
FROM UserBehavior_train;

SELECT COUNT(1) 
FROM UserBehavior_train
WHERE Datee < '2017-11-25';

DELETE FROM UserBehavior_train
WHERE Datee < '2017-11-25'

SELECT COUNT(1) 
FROM UserBehavior_train;

SELECT BehaviorType, COUNT(1) AS 'Amount' 
FROM UserBehavior_train
GROUP BY BehaviorType;

CREATE TABLE BehaviorPath
AS
SELECT UserID, ProductID,
SUM(CASE WHEN BehaviorType = 'pv' THEN 1 ELSE 0 END) as 'Click',
SUM(CASE WHEN BehaviorType = 'cart' THEN 1 ELSE 0 END) as 'Add_to_cart',
SUM(CASE WHEN BehaviorType = 'fav' THEN 1 ELSE 0 END) as 'Add_to_favorite',
SUM(CASE WHEN BehaviorType = 'buy' THEN 1 ELSE 0 END) as 'Buy'
FROM UserBehavior_train
GROUP BY UserID, ProductID;

-- Amount of clicks: 887166
SELECT SUM(Click) FROM BehaviorPath;

-- Amount of click-buy: 9759
SELECT SUM(Buy) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart = 0 AND Add_to_favorite = 0 AND Buy > 0;

-- Amount of click-Add_to_cart: 26639
SELECT SUM(Add_to_cart) FROM BehaviorPath
WHERE Click > 0 AND Add_to_favorite = 0 AND Add_to_cart > 0;

-- Amount of click-Add_to_cart-buy: 2863
SELECT SUM(Buy) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart > 0 AND Add_to_favorite = 0 AND Buy > 0;


-- Amount of click-Add_to_favorite: 10752
SELECT SUM(Add_to_favorite) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart = 0 AND Add_to_favorite > 0;

-- Amount of click-Add_to_favorite-buy: 936
SELECT SUM(Buy) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart = 0 AND Add_to_favorite > 0 AND Buy > 0;


-- Amount of click-Add_to_favorite-Add_to_cart: 1631
SELECT SUM(Add_to_favorite) + SUM(Add_to_cart) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart > 0 AND Add_to_favorite > 0;

-- Amount of click-Add_to_favorite-Add_to_cart-buy: 143
SELECT SUM(Buy) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart > 0 AND Add_to_favorite > 0 AND Buy > 0;

-- Amount of click-lose_customer: 781384
SELECT SUM(Click) FROM BehaviorPath
WHERE Click > 0 AND Add_to_cart = 0 AND Add_to_favorite = 0 AND Buy = 0;

CREATE TABLE Clicks
AS
SELECT CategoryID, COUNT(CategoryID) AS 'Amount_of_Clicks'
FROM UserBehavior_train
WHERE BehaviorType = 'pv'
GROUP BY CategoryID
ORDER BY Amount_of_Clicks DESC LIMIT 10;

CREATE TABLE Sales
AS
SELECT CategoryID, COUNT(CategoryID) AS 'Amount_of_Sales'
FROM UserBehavior_train
WHERE BehaviorType = 'buy'
GROUP BY CategoryID
ORDER BY Amount_of_Sales DESC LIMIT 10;

SELECT *
FROM Clicks
left JOIN Sales
ON Clicks.CategoryID = Sales.CategoryID
ORDER BY Amount_of_Clicks DESC;

-- The top 10 products with the most clicks
CREATE TABLE ProductsClicks
AS
SELECT ProductID, COUNT(ProductID) AS 'Amount_of_Clicks'
FROM UserBehavior_train
WHERE BehaviorType = 'pv'
GROUP BY ProductID
ORDER BY Amount_of_Clicks DESC LIMIT 10;

-- The top 10 products with the most sales
CREATE TABLE ProductsSales
AS
SELECT ProductID, COUNT(ProductID) AS 'Amount_of_Sales'
FROM UserBehavior_train
WHERE BehaviorType = 'buy'
GROUP BY ProductID
ORDER BY Amount_of_Sales DESC LIMIT 10;

-- Calculate the amount of sales with the top 10 products, which have the most clicks
CREATE TABLE SalesofMostClicks
AS
SELECT * FROM
(SELECT ProductID, 
COUNT(BehaviorType) AS 'Amount_of_Sales'
FROM UserBehavior_train
WHERE BehaviorType = 'buy'
GROUP BY ProductID) AS A
WHERE ProductID IN('812879', '138964', '3845720', '3708121', '2032668', '2331370', 
'2338453', '1535294', '4211339', '3371523');

INSERT INTO SalesofMostClicks (ProductID, Amount_of_Sales)
VALUES('3845720', '0'), ('2331370', '0'), ('4211339', '0'), ('3371523', '0');

-- Calculate the amount of clicks with the top 10 products, which have the most sales
CREATE TABLE ClicksofMostSales
AS
SELECT * FROM
(SELECT ProductID, 
COUNT(BehaviorType) AS 'Amount_of_Clicks'
FROM UserBehavior_train
WHERE BehaviorType = 'pv'
GROUP BY ProductID) AS A
WHERE ProductID IN('3122135', '3237415', '2124040', '2964774', '4401268', '1004046', 
'1910706', '3991727', '3147410', '1595279')


SELECT * 
FROM ProductsClicks AS P
LEFT JOIN SalesofMostClicks AS S ON P.ProductID = S.ProductID;

SELECT * 
FROM ProductsSales AS P
LEFT JOIN ClicksofMostSales AS S ON P.ProductID = S.ProductID;

SELECT Datee,COUNT(BehaviorType) as 'Total',
SUM(CASE WHEN BehaviorType = 'pv' THEN 1 ELSE 0 END) AS 'Clicks',
SUM(CASE WHEN BehaviorType = 'cart' THEN 1 ELSE 0 END) AS 'Add_to_Cart',
SUM(CASE WHEN BehaviorType = 'fav' THEN 1 ELSE 0 END) AS 'Add_to_Favorite',
SUM(CASE WHEN BehaviorType = 'buy' THEN 1 ELSE 0 END) AS 'Buy'
FROM UserBehavior_train 
GROUP BY Datee;

SELECT UserID, DATEDIFF('2017-12-3',max(Datee))+1 AS R,
COUNT(BehaviorType) AS F 
FROM UserBehavior_train
WHERE BehaviorType = 'buy'
GROUP BY UserID;

CREATE TABLE Score
AS
SELECT *, 
(CASE WHEN R <= 2 THEN 4
WHEN R BETWEEN 3 AND 4 THEN 3
WHEN R BETWEEN 5 AND 7 THEN 2
WHEN R BETWEEN 8 AND 9 THEN 1 END) AS Rscore,
(CASE WHEN F BETWEEN 1 AND 6 THEN 1 
WHEN F BETWEEN 7 AND 12 THEN 2
WHEN F BETWEEN 13 AND 18 THEN 3
WHEN F >= 19 THEN 4 END) AS Fscore
FROM 
(SELECT UserID, DATEDIFF('2017-12-3',max(Datee))+1 AS R,
COUNT(BehaviorType) AS F 
FROM UserBehavior_train
WHERE BehaviorType = 'buy'
GROUP BY UserID) AS M;

SELECT AVG(Rscore), AVG(Fscore)
FROM Score;

SELECT CustomerSegmentation, COUNT(UserID) AS Amount_of_People
FROM
(SELECT UserID,
(CASE WHEN Rscore > '3.0366' AND Fscore > '1.1028' THEN 'Important value customers'
WHEN Rscore > '3.0366' AND Fscore < '1.1028' THEN 'Important development customers'
WHEN Rscore < '3.0366' AND Fscore > '1.1028' THEN 'Important keep customers'
WHEN Rscore < '3.0366' AND Fscore < '1.1028' THEN 'Important save customers'
ELSE 0 END) AS 'CustomerSegmentation'
FROM Score) AS N
GROUP BY CustomerSegmentation
ORDER BY Amount_of_People DESC;

SELECT Hourr, COUNT(BehaviorType) AS Amount,
SUM(CASE WHEN BehaviorType = 'pv' THEN 1 ELSE 0 END) AS Clicks,
SUM(CASE WHEN BehaviorType = 'buy' THEN 1 ELSE 0 END) AS Buy,
SUM(CASE WHEN BehaviorType = 'cart' THEN 1 ELSE 0 END) AS Add_to_Cart,
SUM(CASE WHEN BehaviorType = 'fav' THEN 1 ELSE 0 END) AS Add_to_Favorite
FROM UserBehavior_train 
GROUP BY Hourr;

