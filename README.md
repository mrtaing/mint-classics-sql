Mint Classics Company SQL Analysis
=============================================
2023-10-03

**Project Scenario**

Mint Classics Company, a retailer of classic model cars and other vehicles, is looking at closing one of their storage facilities. They are looking for suggestions and recommendations for reorganizing or reducing inventory, while still maintaining timely service to their customers. For example, they would like to be able to ship a product to a customer within 24 hours of the order being placed.

**Tools Used**

MySQL Workbench, MySQL

**Data Understanding**

This project used data imported from a relational database and has the ER diagram shown below. There are 4 warehouses that the company has (with codes a, b, c, and d).

![](data/MintClassicsDataModel.png)

**Solution**

The analysis showed that if we were to close a warehouse, it would be best to close warehouse d. Through looking at the top products by orders and profit, warehouses a, b, and c seem to bring in the most profit. For example, warehouse b's profit is shown to be $1,435,639.62, while warehouse d's profit is $653,305.13. Looking at the average percentage of products sold by warehouse, we can see that they're all in the 20-30% range (a: 25.84061600, b: 20.07158919, c: 22.93138750, d:	29.38191304); and the percent of products that have been sold by each warehouse shows that warehouse d's products have the highest percentage sold (a: 14.7375, b: 13.6230, c: 14.4042, d: 20.1368). Warehouse d makes the least profit and has the lowest amount of products in stock, so it can be easier to split up those products to store between the other warehouses. Warehouse d does have the highest percentage of its products being sold though, so we'd want to move the items to warehouses where it could still be efficiently shipped to customers. Warehouse d currently has 79,380 items, while the other warehouses have the following open spaces: a: 51,212, b: 107,955, c: 124,880. Based off this, warehouse d's items could be split between warehouses b and c since they have a lot of space left. It would be beneficial to further analyze which warehouses are closest to warehouse d or closest to the customers who make a lot of orders that come from warehouse d before deciding to close it. If it's necessary to decrease the stock of some items in order to close down a warehouse, then we could reduce the inventory of items that have the lowest percentage ordered out of the total stock.

**Approach**

Exploratory data analysis was performed on MySQL. I first determined what the problem we're trying to solve is, what objectives we're trying to meet, and which tables would be relevant and that I would be able to use to solve the problem. The tables used were warehouses, products, orderdetails, orders, and customers. I created some questions that I thought would be helpful to analyze such as what warehouse has the least/most sold products and which warehouse brings in the most profit? I then wrote several [SQL scripts](mintclassics_script.sql) to explore the data and come up with answers to the questions. Some assumptions were made and noted in the SQL script, such as looking at only shipped items for some queries and assuming some meanings of some ambiguous columns. One thing that would've been useful to have is information on how long it takes to ship items to a customer and from which warehouse, which would've helped in determining timely services to customers (the database only had shipped date, but not delivery date). 
