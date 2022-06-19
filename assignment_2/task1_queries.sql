-- CSE4DBF Assignment 2
-- Vikesh Ajith 20596064

-- 
-- Task 1
-- 

-- a. Display the name of the customer who has purchased the most cars from
-- Archie’s Luxury Motors.

-- Join table with relevant info on purchase count
WITH purchase_details AS (
    SELECT
        salestransaction.custid,
        customer.name,
        COUNT(*) AS no_of_purchases
    FROM salestransaction
    INNER JOIN customer ON salestransaction.custid = customer.custid
    GROUP BY salestransaction.custid, customer.name
)
-- Filter to select customer with the most purchases
SELECT
    name,
    no_of_purchases
FROM purchase_details
WHERE no_of_purchases = (SELECT MAX(no_of_purchases) FROM purchase_details);

-- b. For each sales agent, display their ID and name, along with the
-- total number of sales they have made thus far. Order by number of
-- sales decreasing.

-- Group agentid by count
WITH total_sales AS (
    SELECT
        agentid,
        COUNT(*) AS no_of_sales
    FROM salestransaction
    GROUP BY agentid
)
-- Left outer join with total_sales to consider agents with null sales,
-- filling null with 0
SELECT
    salesagent.agentid,
    salesagent.name,
    NVL(total_sales.no_of_sales, 0) AS no_of_sales
FROM salesagent
LEFT OUTER JOIN total_sales ON salesagent.agentid = total_sales.AGENTID
ORDER BY no_of_sales DESC;

-- c. For each month in 2020, display the total profit (i.e., using the
-- attributes purchasedPrice and agreedPrice) generated from car sales
-- only. Do not consider any discounts.

-- Get month and profit of each car sale in 2020
WITH all_profits AS (
    SELECT
        EXTRACT(month FROM dateofsale) AS month,
        (agreedprice - purchasedprice) AS profit
    FROM salestransaction, car
    WHERE EXTRACT(year FROM dateofsale) = 2020
        AND car.vin = salestransaction.vin
)
-- Group profits by month
SELECT
    month,
    SUM(profit)
FROM all_profits
GROUP BY month
ORDER BY month;

-- d. Display the details (i.e., Manufacturer name, model name, type,
-- and the number of times it was sold) of the top selling European car
-- model. Hint: use the manufacturer region information.

-- Get count of euro model sales
WITH euro_model_sales AS (
    SELECT
        model.modelno,
        manufacturer.name AS manufacturer_name,
        model.name AS model_name,
        model.type,
        COUNT(*) AS sale_no
    FROM salestransaction
    INNER JOIN car ON salestransaction.vin = car.vin
    INNER JOIN model ON car.modelno = model.modelno
    INNER JOIN
        manufacturer ON model.manufacturerid = manufacturer.manufacturerid
    WHERE manufacturer.region = 'EUROPE'
    GROUP BY model.modelno, manufacturer.name, model.name, model.type
)
-- Get the highest selling euro model info
SELECT
    manufacturer_name,
    model_name,
    type,
    sale_no
FROM euro_model_sales
WHERE sale_no = (SELECT MAX(sale_no) FROM euro_model_sales);

-- e. Display the average number of sales transactions (i.e., car sales)
-- per month. Hint: count the number of sales for each month, then
-- divide the count by the number of years the dealership has been
-- making transactions for.


WITH
-- Get the no. of years between the first car sale and the most recent.
-- This is necessary to get an accurate average value
year_diff AS (
    SELECT ((MAX(dateofsale) - MIN(dateofsale)) / 365) AS diff
    FROM salestransaction
),
-- Group number of transactions by month, irrespective of year (since we
-- are looking at overall average per month)
monthly_sales AS (
    SELECT
        EXTRACT(month FROM dateofsale) AS month,
        COUNT(*) AS sales
    FROM salestransaction
    GROUP BY EXTRACT(month FROM dateofsale)
)
-- Get the average monthly sales
SELECT
    monthly_sales.month,
    ROUND(monthly_sales.sales / year_diff.diff, 2) AS avg_sales
FROM year_diff, monthly_sales
ORDER BY month;

-- f. Display the total profit to date for Archie’s Luxury Motors. Note
-- that you must take into consideration all car sales (ignoring unsold
-- cars as they may be sold later) and viewing party shows, and any VIP
-- discounts that may apply. Do not subtract any commission owed to the
-- senior sales agents.

-- - Note: A VIP customer gets a 5% discount for any car purchase
--   greater than or equal to $50,000 AUD. However, the agreed price
--   stored in the database is without the discount. For each car sold
--   to a VIP customer with an agreed price of $50,000 AUD or more, you
--   should subtract this 5% discount from the agreed price when
--   calculating the profit. Also note that the profit from each viewing
--   party show is equal to the amount paid for the show.

-- Calculate profits per car considering VIP discount
WITH car_profits AS (
    SELECT
        salestransaction.vin,
        CASE
            WHEN (customer.type = 'VIP' AND salestransaction.agreedprice >= 50000) THEN
                (salestransaction.agreedprice * 0.95) - car.purchasedprice
            ELSE salestransaction.agreedprice - car.purchasedprice
        END AS profit
    FROM salestransaction
    INNER JOIN car ON salestransaction.vin = car.vin
    INNER JOIN customer ON salestransaction.custid = customer.custid
)
-- Union car and viewing profits and sum
SELECT SUM(profit) FROM (
    SELECT SUM(car_profits.profit) as profit FROM car_profits
    UNION
    SELECT SUM(carsviewed.amountpaid) as profit FROM carsviewed
);

