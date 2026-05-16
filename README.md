# Google Analytics Ecommerce Analysis with BigQuery SQL

## 📌 Project Overview

This project analyzes ecommerce performance using the public **Google Analytics Sample Dataset** on **Google BigQuery**.

The project includes a set of SQL queries designed to answer common business questions related to website traffic, user behavior, revenue performance, conversion rate, product funnel, and cumulative revenue.

The SQL code was updated based on coach feedback to improve query structure, date formatting, join logic, and handling of nested fields using `UNNEST`.

Dataset used:

```sql
bigquery-public-data.google_analytics_sample.ga_sessions_*
```

References:
- Google Analytics BigQuery Export Schema: https://support.google.com/analytics/answer/3437719?hl=en
- BigQuery Format Elements: https://cloud.google.com/bigquery/docs/reference/standard-sql/format-elements

---

## 🛠️ Tools & Technologies

- Google BigQuery
- Standard SQL
- Google Analytics Sample Dataset
- Date Functions
- Aggregation Functions
- Window Functions
- Common Table Expressions
- UNNEST for nested and repeated fields

---

## 📂 Repository Structure

```text
.
├── README.md
└── ecommerce_bigquery.sql
```

---

## 🎯 Project Objectives

The main objectives of this project are to:

- Practice SQL querying on nested Google Analytics data.
- Analyze ecommerce website traffic and sales performance.
- Calculate business metrics such as bounce rate, conversion rate, revenue contribution, and cumulative revenue.
- Understand purchaser and non-purchaser behavior.
- Build product funnel analysis from product view to add to cart to purchase.
- Apply clean SQL structure using CTEs, joins, date functions, and window functions.

---

## 📊 Business Questions

### Query 01: Monthly Website Performance

Calculate total visits, pageviews, and transactions for **January, February, and March 2017**.

Output columns:

```text
month | visits | pageviews | transactions
```

Key update:
- Month is formatted as `YYYYMM` using `FORMAT_DATE()` to match the expected output format.

---

### Query 02: Bounce Rate by Traffic Source

Calculate bounce rate per traffic source in **July 2017**.

Formula:

```text
Bounce Rate = Total Bounces / Total Visits * 100
```

Output columns:

```text
source | total_visits | total_no_of_bounces | bounce_rate
```

Purpose:
- Identify which traffic sources have high bounce rates.
- Evaluate traffic quality by acquisition source.

---

### Query 03: Revenue by Traffic Source by Month and Week

Calculate revenue by traffic source in **June 2017**, grouped by both month and week.

Formula:

```text
Revenue = SUM(productRevenue) / 1,000,000
```

Output columns:

```text
time_type | time | source | revenue
```

Key updates:
- Monthly and weekly revenue are separated into two CTEs.
- `UNION ALL` is used to combine the results.
- Date is formatted correctly using `FORMAT_DATE()`.
- `ORDER BY` is placed after the final combined result.

---

### Query 04: Conversion Rate by Traffic Source

Calculate conversion rate by traffic source in **2017**.

Formula:

```text
Conversion Rate = Transactions / Visits * 100
```

Output columns:

```text
source | visits | transactions | conversion_rate
```

Business logic:
- Only traffic sources with at least **50 transactions** are included.
- This helps reduce noise from sources with very low transaction volume.

---

### Query 05: Average Pageviews by Purchaser Type

Compare average pageviews between purchasers and non-purchasers in **June and July 2017**.

Formula:

```text
Average Pageviews = Total Pageviews / Number of Unique Users
```

Output columns:

```text
month | avg_pageviews_purchase | avg_pageviews_non_purchase
```

Key updates:
- Purchasers and non-purchasers are separated into two CTEs.
- `FULL JOIN` is used to avoid losing data when one group is missing in a specific month.
- This makes the query easier to debug and reduces logic errors.

Purchaser condition:

```sql
totals.transactions >= 1
AND product.productRevenue IS NOT NULL
```

Non-purchaser condition:

```sql
totals.transactions IS NULL
AND product.productRevenue IS NULL
```

---

### Query 06: Average Transactions per Purchasing User

Calculate the average number of transactions per purchasing user in **July 2017**.

Formula:

```text
Average Transactions per Purchasing User = Total Transactions / Number of Unique Purchasing Users
```

Output columns:

```text
month | avg_total_transactions_per_user
```

Purpose:
- Understand how frequently purchasing users complete transactions.

---

### Query 07: Revenue Contribution by Device

Calculate revenue contribution by device category in **2017**.

Formula:

```text
Revenue Ratio = Revenue by Device / Total Revenue * 100
```

Output columns:

```text
device | revenue_by_device | total_revenue | ratio
```

Purpose:
- Identify which device category contributes the most revenue.
- Compare revenue performance across desktop, mobile, and tablet.

---

### Query 08: Other Products Purchased Together

Find other products purchased by customers who bought:

```text
YouTube Men's Vintage Henley
```

Time period:
- July 2017

Output columns:

```text
other_purchased_products | quantity
```

Key update:
- A CTE is used to identify customers who purchased the target product.
- `INNER JOIN` is used to find other products purchased by the same customers.
- The target product is excluded from the final result.

---

### Query 09: Product Funnel Analysis

Calculate the product funnel from product view to add to cart to purchase for **January, February, and March 2017**.

Funnel action types:

```text
2 = Product view
3 = Add to cart
6 = Purchase
```

Formulas:

```text
Add to Cart Rate = Number of Add to Cart Products / Number of Product Views * 100
Purchase Rate = Number of Purchased Products / Number of Product Views * 100
```

Output columns:

```text
month | num_product_view | num_addtocart | num_purchase | add_to_cart_rate | purchase_rate
```

Key updates:
- Product actions are counted using `product.productSKU`.
- The query is split into three CTEs:
  - `product_view`
  - `add_to_cart`
  - `purchase`
- `LEFT JOIN` is used with product view as the base table to avoid losing product view records when add-to-cart or purchase data is missing.
- Purchase records are filtered with `product.productRevenue IS NOT NULL`.

---

### Query 10: Weekly Revenue and Cumulative Revenue

Calculate weekly revenue and cumulative revenue from **May to July 2017**.

Formula:

```text
Cumulative Revenue = SUM(Weekly Revenue) OVER (ORDER BY Week)
```

Output columns:

```text
week | weekly_revenue | cumulative_revenue
```

Key update:
- Window function is used with an explicit window frame:

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Purpose:
- Track weekly revenue growth over time.
- Understand year-to-date style cumulative performance for the selected period.

---

## 🔍 Key SQL Concepts Applied

### 1. Date Parsing and Formatting

The dataset stores date as a string in `YYYYMMDD` format.  
The project uses `PARSE_DATE()` and `FORMAT_DATE()` to convert and format dates.

Example:

```sql
FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month
```

---

### 2. Filtering Tables with `_TABLE_SUFFIX`

The Google Analytics dataset is split into multiple daily tables.  
`_TABLE_SUFFIX` is used to filter specific date ranges.

Example:

```sql
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
```

For wildcard tables across years:

```sql
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
```

---

### 3. Working with Nested Data using `UNNEST`

Google Analytics data contains nested and repeated fields such as `hits` and `hits.product`.

To access product-level fields, the query must use `UNNEST`.

Example:

```sql
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
```

Product-level fields used in this project include:

```text
product.productRevenue
product.productQuantity
product.v2ProductName
product.productSKU
```

---

### 4. Common Table Expressions

CTEs are used to break complex queries into smaller and easier-to-control steps.

Example:

```sql
WITH purchaser_data AS (...),
non_purchaser_data AS (...)
SELECT ...
```

This improves readability and makes debugging easier.

---

### 5. Joins

The project applies different join types depending on the business logic:

- `FULL JOIN`: used when both groups should be preserved.
- `LEFT JOIN`: used when product view is the base of funnel analysis.
- `INNER JOIN`: used when finding products purchased by a specific customer group.

---

### 6. Safe Division

`SAFE_DIVIDE()` is used to avoid division errors when the denominator may be zero.

Example:

```sql
SAFE_DIVIDE(SUM(totals.bounces), SUM(totals.visits))
```

---

### 7. Window Functions

Window functions are used to calculate cumulative revenue.

Example:

```sql
SUM(weekly_revenue) OVER (
  ORDER BY week
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

---

## 📈 Project Outcomes

This project demonstrates the ability to:

- Query and analyze nested ecommerce data in BigQuery.
- Translate business questions into SQL queries.
- Calculate key ecommerce metrics such as visits, pageviews, bounce rate, conversion rate, revenue, and cumulative revenue.
- Build purchaser behavior analysis.
- Build product funnel analysis.
- Use CTEs and joins to improve SQL readability and logic control.
- Apply SQL best practices based on review feedback.

---

## 🚀 How to Run

1. Open Google BigQuery.
2. Make sure Standard SQL mode is enabled.
3. Open the SQL file:

```text
ecommerce_bigquery_queries_updated.sql
```

4. Run each query separately.
5. Review the output and compare it with the expected business requirement.

---

## 📌 Notes

Revenue fields in Google Analytics BigQuery export are stored in micro-units.  
Therefore, `product.productRevenue` is divided by `1,000,000`.

Example:

```sql
SUM(product.productRevenue) / 1000000 AS revenue
```

For purchase-related queries, this condition is used to ensure valid purchase records:

```sql
product.productRevenue IS NOT NULL
```

---

## 👤 Author

**Phan Minh Tan**  
Aspiring Data Analyst  

GitHub: [mnhtan](https://github.com/mnhtan)

---

## 📎 Repository Name Suggestion

Recommended repository name:

```text
google-analytics-ecommerce-sql-bigquery
```
