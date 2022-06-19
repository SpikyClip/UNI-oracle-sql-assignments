-- CSE4DBF Assignment 2
-- Vikesh Ajith 20596064

--
-- Task 3
--
-- For submission, please include both the PL/SQL code and an insert
-- statement to demonstrate the trigger functionality. 

-- A Trigger which automatically stores in a separate table called
-- ‘ExcellentSale’ the Sales Agent name, car model and manufacturer
-- name, each time the agreed price of a SalesTransaction is more than
-- 20% above the car’s asking price. (Note: You need to create the
-- ‘ExcellentSale’ table before implementing this trigger. To create the
-- primary key, use a sequence that starts at 1 and increments by 1).

-- 
-- Set-up
-- 

-- Create table to hold excellent sales

CREATE TABLE excellentsale (
    es_id             NUMBER NOT NULL,
    agent_name        VARCHAR2(50),
    model_name        VARCHAR2(20),
    manufacturer_name VARCHAR2(20),
    CONSTRAINT es_pk  PRIMARY KEY (es_id)
);

-- Create sequence for excellentsale pk
CREATE SEQUENCE es_seq;

-- 
-- Create trigger
-- 

CREATE OR REPLACE TRIGGER trg_excellentsale
    AFTER INSERT ON salestransaction
    FOR EACH ROW

DECLARE

    model_no          model.modelno%TYPE;
    ask_price         car.askingprice%TYPE;
    agent_name        salesagent.name%TYPE;
    model_name        model.name%TYPE;
    manufacturer_id   manufacturer.manufacturerid%TYPE;
    manufacturer_name manufacturer.name%TYPE;

BEGIN
    -- Store variables model_no and ask_price
    SELECT modelno
    INTO model_no
    FROM car
    WHERE :NEW.vin = car.vin;

    SELECT askingprice
    INTO ask_price
    FROM car
    WHERE :NEW.vin = car.vin;

    -- Check if agreed price is 20% over the asking price
    IF :NEW.agreedprice > (ask_price * 1.2) THEN

        DBMS_OUTPUT.PUT_LINE('Excellent sale.');
        -- Store output variables
        SELECT name
        INTO agent_name
        FROM salesagent
        WHERE salesagent.agentid = :NEW.agentid;

        SELECT name
        INTO model_name
        FROM model
        WHERE model.modelno = model_no;

        SELECT manufacturerid
        INTO manufacturer_id
        FROM model
        WHERE model.modelno = model_no;

        SELECT name 
        INTO manufacturer_name
        FROM manufacturer
        WHERE manufacturer.manufacturerid = manufacturer_id;

        -- Create entry in excellentsale
        INSERT INTO excellentsale
        VALUES (es_seq.nextval, agent_name, model_name, manufacturer_name);

    ELSE DBMS_OUTPUT.PUT_LINE('Below excellent sale.');
    END IF;
END trg_excellentsale;
/

-- 
-- Test trigger
-- 

BEGIN
    -- Equal to 1.2 * askingprice, expected 'Below excellent sale.'
    INSERT INTO salestransaction
    VALUES ('1GTHC29D56E184231', 1, 1, '30-Jan-2019', 358800);
    -- $1 above 1.2 * askingprice, expected 'Excellent sale.'
    INSERT INTO salestransaction
    VALUES ('1GTHC29D56E184231', 2, 1, '30-Jan-2019', 358801);

    -- $41200  above 1.2 * askingprice, expected 'Excellent sale.'
    INSERT INTO salestransaction
    VALUES ('1GTHC29D56E184231', 3, 1, '30-Jan-2019', 400000);
END;