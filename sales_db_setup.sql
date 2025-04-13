/*
==============================================================================
📦 SALES DATABASE SETUP | PostgreSQL-Compatible
==============================================================================
Author   : Sudais Shah
Purpose  : Create a sample sales database to practice:
           - Time/Date Functions
           - Window Functions (used in a separate case study)

Tables   : 
  - sales: Order-level data (customers , orderdetails , orders , products)

Usage    : Run this before executing query files.
==============================================================================
*/

-- Create Customers Table
CREATE TABLE IF NOT EXISTS Customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(50),
    signup_date DATE
);

-- Insert 1000 sample customers without specifying customer_id
INSERT INTO Customers (customer_name, signup_date)
SELECT 
    'Customer_' || generate_series(1, 1000) AS customer_name,  -- Generate unique customer names
    CURRENT_DATE - (RANDOM() * 365)::INT * INTERVAL '1 day'  -- Random signup date within the last year
FROM generate_series(1, 1000);

-----------------------------

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50),
    price NUMERIC(10, 2)
);

-- Insert 500 sample products with corrected ROUND function
INSERT INTO Products (product_name, price)
SELECT 
    'Product_' || generate_series(1, 500) AS product_name,  -- Generate unique product names
    ROUND(10 + (RANDOM() * 990)::NUMERIC, 2)  -- Random price between $10 and $1000
FROM generate_series(1, 500);



------------------------------------

-- Create Orders Table
CREATE TABLE IF NOT EXISTS Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_time TIME,
    amount NUMERIC(10, 2),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Insert 50,000 sample orders with corrected ROUND function
INSERT INTO Orders (customer_id, order_date, order_time, amount)
SELECT 
    (RANDOM() * 1000)::INT + 1 AS customer_id,  -- Random customer_id between 1 and 10,000
    CURRENT_DATE - (RANDOM() * 365)::INT * INTERVAL '1 day' AS order_date,  -- Random order date within the last year
    (TIMESTAMP '2023-01-01 00:00:00' + RANDOM() * INTERVAL '1 day')::TIME AS order_time,  -- Random time
    ROUND((50 + (RANDOM() * 1000))::NUMERIC, 2) AS amount  -- Random amount between $50 and $1050
FROM generate_series(1, 50000);

------------------------------------

-- Create OrderDetails Table
CREATE TABLE IF NOT EXISTS OrderDetails (
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Insert 50,000 sample orders into the Orders table

INSERT INTO OrderDetails (order_id, product_id, quantity)
SELECT (RANDOM() * 50000)::INT + 1 AS order_id,  -- Random order_id between 1 and 50,000 (assuming 50,000 orders exist)
       (RANDOM() * 500)::INT + 1 AS product_id,  -- Random product_id between 1 and 500 (assuming you have 500 products)
      (RANDOM() * 5)::INT + 1 AS quantity  -- Random quantity between 1 and 5
FROM generate_series(1, 100000);
