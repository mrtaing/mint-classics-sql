USE mintclassics;
############################################################################################################################
## 1. Looking at top popular (most ordered) products and where they're stored

### Top popular products (products that are in the most orders)
SELECT p.productCode, p.productName, w.warehouseCode, COUNT(o.orderNumber) AS orders
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode
JOIN orders AS o ON o.orderNumber = od.orderNumber
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE o.status LIKE '%Shipped%'
GROUP BY p.productCode
ORDER BY orders DESC;
-- A lot of top products are in warehouse a and b

### Verifying the query above is correct
-- SELECT count(*) FROM orders JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber
-- WHERE orderdetails.productCode = 'S18_4933'

### Products with the most quantity ordered
SELECT p.productCode, p.productName, w.warehouseCode, sum(od.quantityOrdered) AS quantityOrdered
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode
JOIN orders AS o ON o.orderNumber = od.orderNumber
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE o.status LIKE '%Shipped%'
GROUP BY p.productCode
ORDER BY quantityOrdered DESC;
-- There seems to be a good mix between warehouses for items that have the highest quanities ordered

### Products by profit
SELECT p.productCode, p.productName, w.warehouseCode, sum(od.quantityOrdered*(od.priceEach - p.buyPrice)) AS profit
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode
JOIN orders AS o ON o.orderNumber = od.orderNumber
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE o.status LIKE '%Shipped%'
GROUP BY p.productCode
ORDER BY profit DESC;
-- Warehouses a, b, c seem to have products that bring in the most profit

### Are there any products that don't sell?
SELECT p.productCode, p.productName, w.warehouseCode
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode
JOIN orders AS o ON o.orderNumber = od.orderNumber
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
GROUP BY p.productCode
HAVING COUNT(od.productCode) = 0;
-- There aren't any products that don't sell

############################################################################################################################
## 2. Sum of profit from orders that have been shipped by warehouse
SELECT w.warehouseCode, sum(od.quantityOrdered*(od.priceEach - p.buyPrice)) AS profit
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode
JOIN orders AS o ON o.orderNumber = od.orderNumber
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE o.status LIKE '%Shipped%'
GROUP BY w.warehouseCode
ORDER BY profit DESC;
-- warehouse b > a > c > d

############################################################################################################################
## 3. Checking inventory counts for products compared to how much are sold

### Percentage of product sold
SELECT p.productCode, w.warehouseCode, (sum(od.quantityOrdered)/(p.quantityInStock+sum(od.quantityOrdered)))*100 AS percent
FROM orderdetails AS od 
JOIN products AS p on od.productCode = p.productCode
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
GROUP BY p.productCode
ORDER BY percent DESC
-- I'm assuming that quantityInStock + sum(quantityOrdered) gives us the total stock for a product

### average percentage of the products sold for each warehouse
WITH perProductSold AS (
	SELECT p.productCode, w.warehouseCode, (sum(od.quantityOrdered)/(p.quantityInStock+sum(od.quantityOrdered)))*100 AS percent
	FROM orderdetails AS od 
	JOIN products AS p on od.productCode = p.productCode
    JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
	GROUP BY p.productCode
)
SELECT w.warehouseCode, avg(ps.percent)
FROM warehouses AS w
JOIN perProductSold AS ps ON w.warehouseCode = ps.warehouseCode
GROUP BY w.warehouseCode

### Percent of products that have been sold for each warehouse
WITH productSold AS (
	SELECT p.productCode, w.warehouseCode, sum(od.quantityOrdered) AS totalOrdered,  (p.quantityInStock + sum(od.quantityOrdered)) AS quantityInStock
	FROM orderdetails AS od 
	JOIN products AS p on od.productCode = p.productCode
    JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
    JOIN orders AS o ON o.orderNumber = od.orderNumber
	WHERE o.status LIKE '%Shipped%'
	GROUP BY p.productCode
)
SELECT w.warehouseCode, (sum(ps.totalOrdered)/sum(ps.quantityInStock))*100 AS percent
FROM warehouses AS w
JOIN productSold AS ps ON w.warehouseCode = ps.warehouseCode
GROUP BY w.warehouseCode
-- d: 22%, c: 16%, a: 16%, b: 14%


### Calculate the amount of items currently in each warehouse
SELECT w.warehouseCode, sum(p.quantityInStock) AS total
FROM warehouses AS w
JOIN products AS p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode

### Amount of items originally in each warehouse (including ones that have been sold); assuming that if an item is in an order that means it's been subtracted from quantityInStock
WITH productSold AS (
	SELECT p.productCode, w.warehouseCode, (p.quantityInStock + sum(od.quantityOrdered)) AS quantityInStock
	FROM orderdetails AS od 
	JOIN products AS p on od.productCode = p.productCode
    JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
	GROUP BY p.productCode
)
SELECT w.warehouseCode, (sum(ps.quantityInStock)) AS total
FROM warehouses AS w
JOIN productSold AS ps ON w.warehouseCode = ps.warehouseCode
GROUP BY w.warehouseCode

-- From the previous analysis, it looks like if we were to close a warehouse, warehouse d (South warehouse) would be the least
-- impactful on profit and sales to close. d makes the least profit and has the lowest amount of products in stock, so it can
-- be easier to split up those products to store between the other warehouses. d does have the highest percentage of its products
-- being sold though, so we'd want to move the items to warehouses where it could still be efficiently shipped to customers

############################################################################################################################
## 4. Look at splitting the products in warehouse d to the other warehouses

### Calculate the open space in warehouses a, b, c (depending on their warehousePctCap and how many items they currently have)
SELECT w.warehouseCode, FLOOR(((sum(p.quantityInStock)/CAST(w.warehousePctCap AS UNSIGNED))*100 - (sum(p.quantityInStock)))) AS remainingSpace
FROM warehouses AS w
JOIN products AS p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode
-- a: 51,212, b: 107,955, c: 124,880

### See if we need to reduce any inventory to fit items in warehouse d in the other warehouses
-- warehouse d currently has 79,380 items; both warehouse b and c have enough space for warehouse d's items
-- warehouse d's items could be split between warehouse b and c since those two have a lot of space left


### which items have the lowest percentage ordered out of total stock for each warehouse so we can reduce their inventory if needed
SELECT p.productCode, w.warehouseCode, (sum(od.quantityOrdered)/(p.quantityInStock+sum(od.quantityOrdered)))*100 AS percent
FROM orderdetails AS od 
JOIN products AS p on od.productCode = p.productCode
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE w.warehouseCode = 'a'
GROUP BY p.productCode
ORDER BY percent ASC
LIMIT 10

SELECT p.productCode, w.warehouseCode, (sum(od.quantityOrdered)/(p.quantityInStock+sum(od.quantityOrdered)))*100 AS percent
FROM orderdetails AS od 
JOIN products AS p on od.productCode = p.productCode
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE w.warehouseCode = 'b'
GROUP BY p.productCode
ORDER BY percent ASC
LIMIT 10

SELECT p.productCode, w.warehouseCode, (sum(od.quantityOrdered)/(p.quantityInStock+sum(od.quantityOrdered)))*100 AS percent
FROM orderdetails AS od 
JOIN products AS p on od.productCode = p.productCode
JOIN warehouses AS w ON w.warehouseCode = p.warehouseCode
WHERE w.warehouseCode = 'c'
GROUP BY p.productCode
ORDER BY percent ASC
LIMIT 10