-- Table Creation

-- a max length of 255 was used for all VARCHAR2 where there was not a natural
-- maximum, as it maximises the use on an 8bit integer.

CREATE TABLE MANUFACTURER (
    PRIMARY KEY (manufacturer_id),
    -- region and name are not null as all manufacturers have a region and name,
    -- there would be no situation where a manufacturer only has an ID
    manufacturer_id   NUMBER        NOT NULL,
    region            VARCHAR2(255) NOT NULL,
    manufacturer_name VARCHAR2(255) NOT NULL
);


CREATE TABLE MODEL (
    PRIMARY KEY (model_no),
    -- Model number is a string PK as it may contain other characters.
    -- Name and type are not null because all models must have a name and type,
    -- otherwise the information in this table is not particularly useful.
    -- Manufacturer ID is also not null as all cars must be produced by a
    -- manufacturer. prev_model_no can be null if the model is the first of its
    -- kind
    model_no        VARCHAR2(255) NOT NULL,
    model_name      VARCHAR2(255) NOT NULL,
    model_type      VARCHAR2(255) NOT NULL,
    prev_model_no   VARCHAR2(255),
    manufacturer_id NUMBER        NOT NULL,

    FOREIGN KEY (prev_model_no) 
        REFERENCES MODEL (model_no),
    FOREIGN KEY (manufacturer_id)
        REFERENCES MANUFACTURER (manufacturer_id)
);


CREATE TABLE CAR (
    PRIMARY KEY (vin),
    -- All cars have a build year, purchase price, acquisition date, colour,
    -- current_mileage and model number, hence it should be information that is
    -- included if a car is inserted. Asking price may not be pre-defined when
    -- the car is acquired.
    vin             NUMBER(17)    NOT NULL,
    year_built      NUMBER(4)     NOT NULL,
    asking_price    NUMBER(38, 2),
    purchased_price NUMBER(38, 2) NOT NULL,
    date_acquired   DATE          NOT NULL,
    colour          VARCHAR2(255) NOT NULL,
    current_mileage NUMBER(38)    NOT NULL,
    model_no        VARCHAR2(255) NOT NULL,

    -- All the attributes below should be positive.
    CHECK (vin             >= 0),
    CHECK (year_built      >= 0),
    CHECK (asking_price    >= 0),
    CHECK (purchased_price >= 0),
    CHECK (current_mileage >= 0),

    FOREIGN KEY (model_no)
        REFERENCES MODEL (model_no)
);


CREATE TABLE FEATURES (
    PRIMARY KEY (feature_id),
    -- Feature description must be not null, otherwise the feature_id points to
    -- no useful information. Category may be null for features that are hard
    -- to define.
    feature_id          NUMBER        NOT NULL,
    feature_description VARCHAR2(255) NOT NULL,
    category            VARCHAR2(255)
);


CREATE TABLE VIEWING_PARTY (
    PRIMARY KEY (viewing_party_id),
    -- Contact number and email are important pieces of information that should
    -- not be null.
    viewing_party_id NUMBER        NOT NULL,
    contact_no       VARCHAR2(31)  NOT NULL,
    email            VARCHAR2(255) NOT NULL,
    -- Basic email format sanity check
    CHECK (email LIKE '%_@__%.__%')
);


CREATE TABLE ORGANISATION (
    PRIMARY KEY (viewing_party_id),
    -- organisation name is not null otherwise an entry in this table is
    -- meaningless
    viewing_party_id  NUMBER        NOT NULL,
    organisation_name VARCHAR2(255) NOT NULL,

    FOREIGN KEY (viewing_party_id)
        REFERENCES VIEWING_PARTY (viewing_party_id)
);


CREATE TABLE INT_GUEST (
    PRIMARY KEY (viewing_party_id),
    -- country is not null otherwise an entry in this table is meaningless
    viewing_party_id NUMBER        NOT NULL,
    country          VARCHAR2(255) NOT NULL,

    FOREIGN KEY (viewing_party_id)
        REFERENCES VIEWING_PARTY (viewing_party_id)
);


CREATE TABLE CUSTOMER (
    PRIMARY KEY (customer_id),
    -- Customer name, contact information, and address are important
    -- information to collect, hence its not null status. Customer type is
    -- binary and exhaustive, so there is no reason for a null entry. dob and
    -- gender may not be disclosed by the customer, and is not particularly
    -- important to a sale.
    customer_id    NUMBER        NOT NULL,
    customer_name  VARCHAR2(255) NOT NULL,
    dob            DATE,
    gender         CHAR(1),
    phone          VARCHAR2(31)  NOT NULL,
    email          VARCHAR2(255) NOT NULL,
    street_address VARCHAR2(255) NOT NULL,
    postcode       NUMBER(4)     NOT NULL,
    suburb         VARCHAR2(255) NOT NULL,
    customer_type  VARCHAR2(7)   NOT NULL,

    CHECK (gender IN ('M', 'F')),
    -- Basic email format sanity check
    CHECK (email LIKE '%_@__%.__%'),
    CHECK (customer_type IN ('regular', 'vip'))
);


CREATE TABLE SALES_AGENT (
    PRIMARY KEY (agent_id),
    -- Name is not null otherwise the agent_id does not point to any useful
    -- information. dob is not necessary here for the business and may be
    -- private, so it can be null.
    agent_id    NUMBER        NOT NULL,
    agent_name  VARCHAR2(255) NOT NULL,
    dob         DATE
);


CREATE TABLE SENIOR_AGENT (
    PRIMARY KEY (agent_id),
    -- Senior agents must have a promotion date, so it cannot be null
    agent_id  NUMBER        NOT NULL,
    from_date DATE          NOT NULL,

    FOREIGN KEY (agent_id)
        REFERENCES SALES_AGENT (agent_id)
);


CREATE TABLE JUNIOR_AGENT (
    PRIMARY KEY (agent_id),
    -- Junior agents must have a senior agent mentor, so it cannot be null.
    agent_id        NUMBER NOT NULL,
    senior_agent_id NUMBER NOT NULL,

    FOREIGN KEY (agent_id)
        REFERENCES SALES_AGENT (agent_id),
    FOREIGN KEY (senior_agent_id)
        REFERENCES SENIOR_AGENT (agent_id)
);


CREATE TABLE CAR_FEATURES (
    PRIMARY KEY (vin, feature_id),

    vin        NUMBER(17) NOT NULL,
    feature_id NUMBER     NOT NULL,

    FOREIGN KEY (vin)
        REFERENCES CAR (vin)
);


CREATE TABLE ON_DISPLAY_FOR (
    PRIMARY KEY (date_viewed, vin, viewing_party_id),
    -- viewing parties must have a cost, even if it is zero, so it cannot be null
    date_viewed      DATE          NOT NULL,
    vin              NUMBER(17)    NOT NULL,
    viewing_party_id NUMBER        NOT NULL,
    amount_paid      NUMBER(38, 2) NOT NULL,

    CHECK (amount_paid >= 0),

    FOREIGN KEY (vin)
        REFERENCES CAR (vin),
    FOREIGN KEY (viewing_party_id)
        REFERENCES VIEWING_PARTY (viewing_party_id)
);


CREATE TABLE DESIRED_FEATURES (
    PRIMARY KEY (feature_id, customer_id),

    feature_id  NUMBER NOT NULL,
    customer_id NUMBER NOT NULL,

    FOREIGN KEY (feature_id)
        REFERENCES FEATURES (feature_id),
    FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
);


CREATE TABLE SALE (
    PRIMARY KEY (vin, customer_id, agent_id),

    vin          NUMBER(17)    NOT NULL,
    customer_id  NUMBER        NOT NULL,
    agent_id     NUMBER        NOT NULL,
    date_of_sale DATE          NOT NULL,
    agreed_price NUMBER(38, 2) NOT NULL,

    CHECK (agreed_price >= 0),

    FOREIGN KEY (vin)
        REFERENCES CAR (vin),
    FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id),
    FOREIGN KEY (agent_id)
        REFERENCES SALES_AGENT (agent_id)
);

-- Insert Statements

INSERT INTO MANUFACTURER
VALUES (1, 'Australia', 'Holden');

INSERT INTO MODEL (model_no, model_name, model_type, manufacturer_id)
VALUES ('VT-VZ-123', 'Commodore VT', 'sedan', 1);

INSERT INTO CAR
VALUES (25644247043033662, '1997', 10000.50, 6000, '01-JUN-2021', 'red', 5000,
        'VT-VZ-123');

INSERT INTO FEATURES
VALUES (1, 'manual transmission', 'transmission-type');

INSERT INTO VIEWING_PARTY
VALUES (1, '+61 4345 345 952', 'ilovecars@gmail.com');

INSERT INTO ORGANISATION
VALUES (1, 'American Car Enthusiasts');

INSERT INTO INT_GUEST
VALUES (1, 'America');

INSERT INTO CUSTOMER
VALUES (1, 'Vikesh Ajith', '16-NOV-1995', 'M', '+61 4345 345 952',
        'ilovecars@gmail.com', 'Random Lane', 3057, 'Brunswick East', 'vip');

INSERT INTO SALES_AGENT
VALUES (1, 'John Doe', '05-FEB-1991');

INSERT INTO SALES_AGENT
VALUES (2, 'Mary Jane', '02-MAR-1981');

INSERT INTO SENIOR_AGENT
VALUES (2, '01-JAN-2021');

INSERT INTO JUNIOR_AGENT
VALUES (1, 2);

INSERT INTO CAR_FEATURES
VALUES (25644247043033662, 1);

INSERT INTO ON_DISPLAY_FOR
VALUES ('01-JUL-2021', 25644247043033662, 1, 100.50);

INSERT INTO DESIRED_FEATURES
VALUES (1, 1);

INSERT INTO SALE
VALUES (25644247043033662, 1, 1, '08-SEP-2021', 15000.75);