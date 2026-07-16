DROP TABLE IF EXISTS staging_grocery_inventory;
-- first we create staging table and keep columns order as in original csv
CREATE TABLE staging_grocery_inventory (
    product_name TEXT,
    category TEXT,
    supplier_name TEXT,
    warehouse_location TEXT,
	status TEXT,
	product_id TEXT,
	supplier_id TEXT,
	date_received TEXT,
    last_order_date TEXT,
    expiration_date TEXT,
    stock_quantity TEXT,
    reorder_level TEXT,
    reorder_quantity TEXT,
    unit_price TEXT,
    sales_volume TEXT,
    inventory_turnover_rate TEXT,
    percentage TEXT
);    
-- now we use import option to load csv into table
-- lets verify
SELECT * FROM staging_grocery_inventory LIMIT 6;
-- now we will inspect columns
-- start with numeric columns inspection
SELECT 
    'stock_quantity' AS column_name, 
    COUNT(*) AS total_rows, 
    SUM(CASE WHEN stock_quantity !~ '^[0-9]+(\.[0-9]+)?$' AND stock_quantity <> '' THEN 1 ELSE 0 END) AS dirty_rows
FROM staging_grocery_inventory
UNION ALL
SELECT 'reorder_level', COUNT(*), SUM(CASE WHEN reorder_level !~ '^[0-9]+$' AND reorder_level <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'reorder_quantity', COUNT(*), SUM(CASE WHEN reorder_quantity !~ '^[0-9]+$' AND reorder_quantity <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'unit_price', COUNT(*), SUM(CASE WHEN unit_price !~ '^[\$]?[0-9]+(\.[0-9]+)?$' AND unit_price <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'sales_volume', COUNT(*), SUM(CASE WHEN sales_volume !~ '^[0-9]+$' AND sales_volume <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'inventory_turnover_rate', COUNT(*), SUM(CASE WHEN inventory_turnover_rate !~ '^[0-9]+(\.[0-9]+)?$' AND inventory_turnover_rate <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'percentage', COUNT(*), SUM(CASE WHEN percentage !~ '^[0-9]+(\.[0-9]+)?[\%]?$' AND percentage <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory;
-- percentage column showed 390 dirty rows, so we check what the reason could be
SELECT DISTINCT percentage 
FROM staging_grocery_inventory 
WHERE percentage !~ '^[0-9]+(\.[0-9]+)?[\%]?$' 
  AND percentage <> '';
-- we will drop percentage column as we are unaware of its context
-- now we inspect date columns
SELECT 
    'date_received' AS col, 
    COUNT(*) AS total_rows,
    -- Regex allows 1 or 2 digits for month/day
    SUM(CASE WHEN date_received !~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}$' AND date_received <> '' THEN 1 ELSE 0 END) AS dirty_rows
FROM staging_grocery_inventory
UNION ALL
SELECT 'last_order_date', COUNT(*), 
       SUM(CASE WHEN last_order_date !~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}$' AND last_order_date <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory
UNION ALL
SELECT 'expiration_date', COUNT(*), 
       SUM(CASE WHEN expiration_date !~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}$' AND expiration_date <> '' THEN 1 ELSE 0 END)
FROM staging_grocery_inventory;
-- now we create final table
CREATE TABLE grocery_inventory (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    supplier_id VARCHAR(50),
    supplier_name VARCHAR(255),
    stock_quantity INT,
    reorder_level INT,
    reorder_quantity INT,
    unit_price NUMERIC(10, 2),
    date_received DATE,
    last_order_date DATE,
    expiration_date DATE,
    warehouse_location VARCHAR(100),
    sales_volume INT,
    inventory_turnover_rate NUMERIC(5, 2),
    status VARCHAR(50)
);
-- now we load data into final table
INSERT INTO grocery_inventory (
    product_id, product_name, category, supplier_id, supplier_name,
    stock_quantity, reorder_level, reorder_quantity, unit_price,
    date_received, last_order_date, expiration_date, warehouse_location,
    sales_volume, inventory_turnover_rate, status
)
SELECT 
    product_id,
    product_name,
    category,
    supplier_id,
    supplier_name,
    NULLIF(stock_quantity, '')::INT,
    NULLIF(reorder_level, '')::INT,
    NULLIF(reorder_quantity, '')::INT,
    CAST(REPLACE(REPLACE(unit_price, '$', ''), ',', '') AS NUMERIC),
    TO_DATE(NULLIF(date_received, ''), 'MM/DD/YYYY'),
    TO_DATE(NULLIF(last_order_date, ''), 'MM/DD/YYYY'),
    TO_DATE(NULLIF(expiration_date, ''), 'MM/DD/YYYY'),
    warehouse_location,
    NULLIF(sales_volume, '')::INT,
    NULLIF(inventory_turnover_rate, '')::NUMERIC,
    status
FROM staging_grocery_inventory;
-- verify
SELECT COUNT(*) FROM grocery_inventory;
-- check nulls
SELECT 
    'product_id' AS column_name, COUNT(*) - COUNT(product_id) AS null_count FROM grocery_inventory
UNION ALL
SELECT 'unit_price', COUNT(*) - COUNT(unit_price) FROM grocery_inventory
UNION ALL
SELECT 'date_received', COUNT(*) - COUNT(date_received) FROM grocery_inventory;
-- verify range of numeric columns
SELECT 
    'stock_quantity' AS col, MIN(stock_quantity::INT) AS min_val, MAX(stock_quantity::INT) AS max_val FROM grocery_inventory
UNION ALL
SELECT 'reorder_level', MIN(reorder_level::INT), MAX(reorder_level::INT) FROM grocery_inventory
UNION ALL
SELECT 'reorder_quantity', MIN(reorder_quantity::INT), MAX(reorder_quantity::INT) FROM grocery_inventory
UNION ALL
SELECT 'unit_price', MIN(unit_price), MAX(unit_price) FROM grocery_inventory
UNION ALL
SELECT 'sales_volume', MIN(sales_volume::INT), MAX(sales_volume::INT) FROM grocery_inventory
UNION ALL
SELECT 'inventory_turnover_rate', MIN(inventory_turnover_rate), MAX(inventory_turnover_rate) FROM grocery_inventory;
-- checking for duplicate rows
SELECT product_id, COUNT(*) 
FROM grocery_inventory 
GROUP BY product_id 
HAVING COUNT(*) > 1;
-- now we begin with analysis
-- 1. ABC Analysis
CREATE OR REPLACE VIEW view_abc_analysis AS
WITH ProductSales AS (
    SELECT product_id, product_name, (unit_price * sales_volume) AS total_sales_value
    FROM grocery_inventory
),
RankedSales AS (
    SELECT 
        product_id, 
        product_name, 
        total_sales_value,
        SUM(total_sales_value) OVER (ORDER BY total_sales_value DESC) AS cumulative_sales,
        SUM(total_sales_value) OVER () AS grand_total
    FROM ProductSales
)
SELECT 
    product_id, 
    product_name, 
    total_sales_value,
    CASE 
        WHEN (cumulative_sales / grand_total) <= 0.80 THEN 'A'
        WHEN (cumulative_sales / grand_total) <= 0.95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM RankedSales;

SELECT 
    abc_class, 
    COUNT(product_id) AS total_items, 
    ROUND(SUM(total_sales_value), 2) AS total_revenue
FROM view_abc_analysis
GROUP BY abc_class
ORDER BY abc_class ASC;
-- 2. Reorder Alerts
CREATE OR REPLACE VIEW view_reorder_alerts AS
SELECT 
    product_id, 
    product_name, 
    supplier_name,
    stock_quantity, 
    reorder_level,
    (reorder_level - stock_quantity) AS units_to_order
FROM grocery_inventory
WHERE stock_quantity <= reorder_level;

SELECT * FROM view_reorder_alerts 
ORDER BY units_to_order DESC
LIMIT 5;

SELECT 
    COUNT(product_id) AS items_needing_restock,
    SUM(units_to_order) AS total_units_to_order
FROM view_reorder_alerts;
-- 3. Efficiency Tracking
CREATE OR REPLACE VIEW view_inventory_efficiency AS
SELECT 
    product_id, 
    product_name, 
    stock_quantity, 
    sales_volume,
    inventory_turnover_rate,
    CASE 
        WHEN inventory_turnover_rate < 10 THEN 'Slow Mover'
        WHEN inventory_turnover_rate BETWEEN 10 AND 50 THEN 'Steady'
        ELSE 'Fast Mover'
    END AS movement_category
FROM grocery_inventory;

SELECT 
    movement_category, 
    COUNT(product_id) AS item_count
FROM view_inventory_efficiency
GROUP BY movement_category
ORDER BY item_count DESC;
-- 4. Waste Prevention
CREATE OR REPLACE VIEW view_waste_prevention AS
WITH ReferenceDate AS (
    SELECT MAX(expiration_date) AS max_expiry 
    FROM grocery_inventory
)
SELECT 
    product_id, 
    product_name, 
    expiration_date,
    (expiration_date::DATE - (SELECT (max_expiry - INTERVAL '365 days')::DATE FROM ReferenceDate)) AS days_until_expiry
FROM grocery_inventory
WHERE expiration_date IS NOT NULL;

SELECT 
    product_id, 
    product_name, 
    expiration_date, 
    days_until_expiry
FROM view_waste_prevention
WHERE days_until_expiry BETWEEN 1 AND 10
ORDER BY days_until_expiry ASC;
-- 5. Warehouse Analysis
CREATE OR REPLACE VIEW view_warehouse_analysis AS
SELECT 
    warehouse_location,
    SUM(sales_volume) AS total_sales,
    SUM(stock_quantity) AS total_inventory,
    -- Ratio tells us how many units we hold to generate 1 unit of sales
    ROUND(SUM(stock_quantity)::NUMERIC / NULLIF(SUM(sales_volume), 0), 2) AS stock_to_sales_ratio
FROM grocery_inventory
GROUP BY warehouse_location;

SELECT warehouse_location, stock_to_sales_ratio
FROM view_warehouse_analysis
ORDER BY stock_to_sales_ratio ASC
LIMIT 5;

SELECT warehouse_location, stock_to_sales_ratio
FROM view_warehouse_analysis
ORDER BY stock_to_sales_ratio DESC
LIMIT 5;
-- 6. Category Specific Profit and Risk Trend
CREATE OR REPLACE VIEW view_category_risk_profit AS
WITH ReferenceDate AS (
    SELECT MAX(expiration_date) AS max_expiry FROM grocery_inventory
)
SELECT 
    category,
    SUM(sales_volume) AS total_sales_volume,
    COUNT(CASE WHEN expiration_date >= (SELECT max_expiry - INTERVAL '60 days' FROM ReferenceDate) 
               AND expiration_date <= (SELECT max_expiry FROM ReferenceDate) THEN 1 END) AS high_risk_items,
    COUNT(product_id) AS total_items,
    ROUND(100.0 * COUNT(CASE WHEN expiration_date >= (SELECT max_expiry - INTERVAL '60 days' FROM ReferenceDate) 
                             AND expiration_date <= (SELECT max_expiry FROM ReferenceDate) THEN 1 END) 
          / NULLIF(COUNT(product_id), 0), 2) AS risk_percentage
FROM grocery_inventory
WHERE category IS NOT NULL 
GROUP BY category
ORDER BY total_sales_volume DESC;

SELECT * FROM view_category_risk_profit;


