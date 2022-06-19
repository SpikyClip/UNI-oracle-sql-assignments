-- CSE4DBF Assignment 2
-- Vikesh Ajith 20596064

-- 
-- Task 2
-- 

-- a. Write a stored procedure that accepts a particular year as input,
-- and as output displays the number of cars sold grouped by the 3
-- mileage groups (Low Mileage: <50000km, Medium Mileage: >=50000km &
-- <150000km, High Mileage:
-- >=150000km). Also display the total number of cars sold overall.

-- 
-- Create procedure
-- 

CREATE OR REPLACE PROCEDURE cars_sold_by_year (year IN NUMBER) AS

    total_sold NUMBER;

    -- Cursor that categorises cars by mileage
    CURSOR cars_sold_by_mileage IS
        SELECT
            mileage_group,
            count(*) AS cars_sold
        FROM (
            SELECT
                salestransaction.vin,
                EXTRACT(year FROM salestransaction.dateofsale) AS year_sold,
                CASE
                    WHEN car.currentmileage < 50000 THEN 'low'
                    WHEN car.currentmileage < 150000 THEN 'medium'
                    ELSE 'high'
                END AS mileage_group
            FROM salestransaction
            INNER JOIN car ON salestransaction.vin = car.vin
            WHERE EXTRACT(year FROM salestransaction.dateofsale) = year
        )
        GROUP BY mileage_group
        ORDER BY CASE
            WHEN mileage_group = 'low' THEN 1
            WHEN mileage_group = 'medium' THEN 2
            WHEN mileage_group = 'high' THEN 3
            END ASC;

BEGIN
    -- Count all sold that year
    SELECT COUNT(*)
    INTO total_sold
    FROM salestransaction
    WHERE EXTRACT(year FROM salestransaction.dateofsale) = year;

    -- If cars sold, loop through cursor and print count of mileage groups
    -- followed by total cars sold
    IF total_sold > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Cars sold in each mileage category in: '|| year || CHR(10));

        FOR mileage IN cars_sold_by_mileage LOOP
            DBMS_OUTPUT.PUT_LINE(
                mileage.mileage_group || ' mileage:' || mileage.cars_sold
                );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Total cars sold: '|| total_sold);

        -- Catch years with no cars sold
        ELSE
            DBMS_OUTPUT.PUT_LINE(total_sold || ' cars sold in ' || year);
    END IF;

END;
/

-- 
-- Test procedure
-- 

BEGIN
    cars_sold_by_year(2020);
    cars_sold_by_year(2019);
    cars_sold_by_year(2018);
END;

-- b. Write a stored function that uses a senior agent’s ID as input and
-- calculates the total commission owed to date for that agent. You also
-- need to show an SQL statement to display the total amount of
-- commission (i.e., the sum) owed to all senior agents in the
-- database.CSE2/4DBF-Assignment 2-Semester 2-2021 Page 4 of 4

-- - Note: the commission policy states that a senior agent receives an
--   additional 1% commission multiplier for each year since they became
--   a senior agent, rounding down to the nearest full year. This means
--   that a senior agent who was promoted 4.25 years before the date of
--   sale, would have their commission calculated as (agreedPrice –
--   askingPrice) × 4%. Also, a senior agent receives the commission
--   only when the agreedPrice is greater than the askingPrice stored in
--   the database. The asking price in the database is not visible to
--   customers.

-- 
-- Create function
-- 

CREATE OR REPLACE FUNCTION total_commission(snr_agent_id IN VARCHAR2)
    RETURN NUMBER
    IS commission NUMBER(11, 2);

BEGIN

    -- Calculates commission by taking difference in days, converting to
    -- years, rounding down, and multiplying by the sale profit. This is
    -- then summed.
    SELECT
        SUM(
            FLOOR((salestransaction.dateofsale - senioragent.yearpromoted) / 365)
                / 100
                * (salestransaction.agreedprice - car.askingprice)
        ) AS total_commission
    INTO commission
    FROM salestransaction

    -- Join to get car.askingprice and senioragent.yearpromoted data
    INNER JOIN car ON salestransaction.vin = car.vin
    INNER JOIN senioragent ON salestransaction.agentid = senioragent.agentid

    -- Restrict to snr_agent id, sales where the agreed price exceeded
    -- asking price, and where the sale happened after the agent was
    -- promoted.
    WHERE salestransaction.agentid = snr_agent_id
    AND salestransaction.agreedprice > car.askingprice
    AND senioragent.yearpromoted <= salestransaction.dateofsale;

    RETURN commission;

END;

-- 
-- Calculate commission owed to all agents
-- 

SELECT SUM(TOTAL_COMMISSION(agentid)) AS total_commission_owed
FROM senioragent;
