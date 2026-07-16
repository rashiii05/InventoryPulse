# 📦 InventoryPulse: Optimization & Waste Mitigation Framework

## Overview

InventoryPulse is an end-to-end Inventory Analytics project built using **PostgreSQL** and **Power BI**. The project transforms raw grocery inventory data into actionable business insights that help optimize inventory levels, reduce waste, improve warehouse efficiency, and support data-driven procurement decisions.

The project follows a complete analytics workflow:

- Raw Data → Staging Table
- Data Cleaning & Transformation
- Final Production Table
- SQL Analysis
- Interactive Power BI Dashboard

---

## Dataset

**Source:** https://www.kaggle.com/datasets/willianoliveiragibin/grocery-inventory/data

The dataset contains grocery inventory information including products, suppliers, stock levels, warehouse locations, sales, reorder information, and expiration dates.

---

# Dataset Features

| Feature | Description |
|----------|-------------|
| Product_ID | Unique identifier assigned to each product |
| Product_Name | Name of the grocery product |
| Category | Product category (Grains & Pulses, Dairy, etc.) |
| Supplier_ID | Unique supplier identifier |
| Supplier_Name | Supplier name |
| Stock_Quantity | Current inventory quantity |
| Reorder_Level | Minimum stock level before reorder |
| Reorder_Quantity | Suggested quantity to reorder |
| Unit_Price | Price per unit |
| Date_Received | Date inventory was received |
| Last_Order_Date | Most recent procurement date |
| Expiration_Date | Product expiry date |
| Warehouse_Location | Storage location |
| Sales_Volume | Total units sold |
| Inventory_Turnover_Rate | Inventory movement efficiency |
| Status | Active / Backordered / Discontinued |

---

# Tech Stack

- PostgreSQL
- Power BI
- SQL
- Data Cleaning
- Data Modeling
- Business Analytics

---

# Project Workflow

## Step 1 — Raw Data Loading

The original CSV is first imported into a **staging table** where every column is initially stored as **TEXT**.

This prevents data loading failures and allows complete inspection before transformation.

---

## Step 2 — Data Cleaning

The staging table is cleaned and converted into appropriate data types.

### Numeric Columns

- stock_quantity
- reorder_level
- reorder_quantity
- unit_price
- sales_volume
- inventory_turnover_rate
- percentage

### Date Columns

- date_received
- last_order_date
- expiration_date

### Text Columns

- product_id
- supplier_id
- category
- status
- warehouse_location
- product_name
- supplier_name

---

## Step 3 — Production Table

After cleaning, validated records are loaded into the final production table (`grocery_inventory`) used for all SQL analysis and Power BI reporting.

---

# Features

## 1. ABC Analysis

Uses the Pareto Principle to categorize inventory based on revenue contribution.

- **Class A:** Top 20% of products generating ~80% of revenue
- **Class B:** Next 30%
- **Class C:** Remaining 50%

This helps prioritize inventory management efforts.

---

## 2. Reorder Alerts

Automatically compares:

```
Stock Quantity
vs
Reorder Level
```

Products falling below the reorder threshold are flagged along with the recommended reorder quantity.

---

## 3. Efficiency Tracking

Uses the Inventory Turnover Rate to classify inventory into:

- Fast Movers
- Steady Movers
- Slow Movers

This identifies inventory tying up warehouse space and working capital.

---

## 4. Waste Prevention

Calculates remaining shelf life using Expiration Date and identifies products nearing expiry.

Allows early:

- Discounting
- Liquidation
- Clearance Sales

to reduce financial loss.

---

## 5. Warehouse Analysis

Aggregates:

- Sales Volume
- Stock Quantity

by Warehouse Location to identify:

- High-performing zones
- Overstocked zones
- Storage bottlenecks

---

## 6. Category-Specific Profit & Risk Trend

Analyzes each product category using:

- Sales Volume
- Expiration Risk

to determine:

- Revenue-driving categories
- Categories with highest waste risk

---

# SQL Analysis

---

## 1. ABC Analysis

### What We Did

Calculated total sales value for every product:

```
Sales Value = Sales Volume × Unit Price
```

Products were sorted from highest to lowest contribution and classified into A, B, and C categories.

### What We Found

- 472 Class A products generate **$274,850+** revenue.
- 230 Class C products contribute only **$18,144**.
- Revenue follows a clear Pareto distribution where a small portion of products drives the majority of sales.

### Business Recommendation

- Maintain high stock availability for Class A products.
- Reduce ordering frequency for Class C items.
- Allocate inventory planning resources primarily toward Class A inventory.

---

## 2. Reorder Alerts

### What We Did

Built an automated SQL view comparing:

```
Stock Quantity
vs
Reorder Level
```

The system also calculates:

```
Units To Order
```

for every low-stock item.

### What We Found

- 465 products require immediate restocking.
- Total reorder requirement: **13,946 units**.
- Products such as **Haddock** and **Egg (Turkey)** require urgent replenishment.

### Business Recommendation

- Prioritize procurement using the reorder view.
- Prevent stockouts without excessive overstocking.

---

## 3. Efficiency Tracking

### What We Did

Products were classified using Inventory Turnover Rate into:

- Fast Movers
- Steady Movers
- Slow Movers

### What We Found

Out of 990 products:

- 492 Fast Movers
- 412 Steady Movers
- 86 Slow Movers

Slow movers have turnover rates below 10 and represent tied-up inventory.

### Business Recommendation

- Keep Fast Movers easily accessible and sufficiently stocked.
- Investigate Slow Movers for promotions, discounts, or discontinuation.

---

## 4. Waste Prevention

### What We Did

Created a dynamic expiration monitoring system calculating:

```
Days Until Expiry
```

for every product.

### What We Found

Products such as:

- Pomegranate
- Evaporated Milk

are within 2–4 days of expiration and face immediate waste risk.

### Business Recommendation

- Launch flash sales and clearance campaigns.
- Prioritize selling near-expiry products before financial loss occurs.

---

## 5. Warehouse Analysis

### What We Did

Calculated the:

```
Stock-to-Sales Ratio
```

for every warehouse location.

### What We Found

**Most Productive Zone**

- 1 Jackson Pass (Ratio = 0.10)

**Most Overstocked Zone**

- 6 John Wall Plaza (Ratio = 5.00)

The latter stores five times more inventory than it sells.

### Business Recommendation

- Move Fast Movers closer to productive zones.
- Audit overcrowded locations and eliminate stagnant inventory.

---

## 6. Category-Specific Profit & Risk Trend

### What We Did

Compared:

- Sales Performance
- Products expiring within 60 days

across every category.

### What We Found

**Top Revenue Categories**

- Fruits & Vegetables
- Dairy

**Highest Expiration Risk**

- Grains & Pulses (19.14%)
- Dairy (18.89%)

### Business Recommendation

- Apply dynamic markdowns for high-risk inventory.
- Shorten procurement cycles for categories prone to expiration.

---

# Power BI Dashboard

The Power BI dashboard provides an interactive overview of inventory health through KPIs, charts, filters, and drill-down analysis.

## KPI Cards

### Total Revenue

---

### Total Products


---

### Total Sales Volume


---

# Dashboard Highlights

- Revenue Overview
- ABC Classification
- Reorder Alert Summary
- Warehouse Performance
- Inventory Turnover Analysis
- Waste Prevention Dashboard
- Category-wise Revenue & Risk Analysis
- Interactive Filters for Category, Warehouse, and Status

---

# Business Impact

InventoryPulse helps organizations:

- Reduce inventory holding costs
- Prevent stockouts
- Minimize product waste
- Improve warehouse utilization
- Optimize procurement planning
- Prioritize high-value inventory
- Improve cash flow through better inventory decisions

---

# Future Enhancements

- Demand Forecasting using Machine Learning
- Seasonal Inventory Prediction
- Supplier Performance Dashboard
- EOQ (Economic Order Quantity) Optimization
- Safety Stock Optimization
- Automatic Purchase Order Generation
- Inventory Cost Forecasting
- Power BI Incremental Refresh



# Author

**Rashi**

SQL • PostgreSQL • Power BI • Data Analytics
