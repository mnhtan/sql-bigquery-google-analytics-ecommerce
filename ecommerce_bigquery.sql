-- Google Analytics Ecommerce Analysis with BigQuery SQL
-- Dataset: bigquery-public-data.google_analytics_sample.ga_sessions_*
-- Author: Phan Minh Tan

-- =========================================================
-- Query 01
-- Calculate total visits, pageviews, and transactions
-- for Jan, Feb, and Mar 2017.
-- =========================================================

SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;


-- =========================================================
-- Query 02
-- Calculate bounce rate per traffic source in July 2017.
-- Bounce rate = total bounces / total visits * 100
-- =========================================================

SELECT
  trafficSource.source AS source,
  SUM(totals.visits) AS total_visits,
  SUM(totals.bounces) AS total_no_of_bounces,
  ROUND(SAFE_DIVIDE(SUM(totals.bounces), SUM(totals.visits)) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY 1
ORDER BY total_visits DESC;


-- =========================================================
-- Query 03
-- Calculate revenue by traffic source by month and by week
-- in June 2017.
-- Revenue = productRevenue / 1,000,000
-- =========================================================

WITH month_data AS (
  SELECT
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(product.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE product.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
),

week_data AS (
  SELECT
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(product.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE product.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
)

SELECT
  time_type,
  time,
  source,
  revenue
FROM month_data

UNION ALL

SELECT
  time_type,
  time,
  source,
  revenue
FROM week_data

ORDER BY time_type, revenue DESC;


-- =========================================================
-- Query 04
-- Calculate conversion rate by traffic source in 2017.
-- Conversion rate = transactions / visits * 100
-- Only include traffic sources with transactions >= 50.
-- =========================================================

SELECT
  trafficSource.source AS source,
  SUM(totals.visits) AS visits,
  SUM(totals.transactions) AS transactions,
  ROUND(SAFE_DIVIDE(SUM(totals.transactions), SUM(totals.visits)) * 100, 2) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '1231'
GROUP BY 1
HAVING transactions >= 50
ORDER BY conversion_rate DESC;


-- =========================================================
-- Query 05
-- Calculate average number of pageviews by purchaser type
-- in June and July 2017.
-- Purchaser: totals.transactions >= 1 and productRevenue is not null
-- Non-purchaser: totals.transactions is null and productRevenue is null
-- =========================================================

WITH purchaser_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY 1
),

non_purchaser_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY 1
)

SELECT
  COALESCE(p.month, np.month) AS month,
  p.avg_pageviews_purchase,
  np.avg_pageviews_non_purchase
FROM purchaser_data AS p
FULL JOIN non_purchaser_data AS np
  USING (month)
ORDER BY month;


-- =========================================================
-- Query 06
-- Calculate average number of transactions per purchasing user
-- in July 2017.
-- Average transactions per user = total transactions / unique purchasing users
-- =========================================================

SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
GROUP BY 1;


-- =========================================================
-- Query 07
-- Calculate revenue contribution by device in 2017.
-- Ratio = revenue by device / total revenue * 100
-- =========================================================

WITH device_revenue AS (
  SELECT
    device.deviceCategory AS device,
    SUM(product.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY 1
)

SELECT
  device,
  revenue_by_device,
  SUM(revenue_by_device) OVER () AS total_revenue,
  ROUND(SAFE_DIVIDE(revenue_by_device, SUM(revenue_by_device) OVER ()) * 100, 2) AS ratio
FROM device_revenue
ORDER BY ratio DESC;


-- =========================================================
-- Query 08
-- Find other products purchased by customers who purchased
-- "YouTube Men's Vintage Henley" in July 2017.
-- =========================================================

WITH buyers_list AS (
  SELECT DISTINCT
    fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND product.productRevenue IS NOT NULL
    AND totals.transactions >= 1
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
INNER JOIN buyers_list AS buyers
  USING (fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
  AND product.productRevenue IS NOT NULL
  AND totals.transactions >= 1
GROUP BY 1
ORDER BY quantity DESC;


-- =========================================================
-- Query 09
-- Calculate product funnel from product view to add to cart
-- to purchase in Jan, Feb, and Mar 2017.
-- Product view: action_type = '2'
-- Add to cart: action_type = '3'
-- Purchase: action_type = '6'
-- =========================================================

WITH product_view AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.productSKU) AS num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.productSKU) AS num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.productSKU) AS num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.eCommerceAction.action_type = '6'
    AND product.productRevenue IS NOT NULL
  GROUP BY 1
)

SELECT
  pv.month,
  pv.num_product_view,
  COALESCE(a.num_addtocart, 0) AS num_addtocart,
  COALESCE(p.num_purchase, 0) AS num_purchase,
  ROUND(SAFE_DIVIDE(COALESCE(a.num_addtocart, 0), pv.num_product_view) * 100, 2) AS add_to_cart_rate,
  ROUND(SAFE_DIVIDE(COALESCE(p.num_purchase, 0), pv.num_product_view) * 100, 2) AS purchase_rate
FROM product_view AS pv
LEFT JOIN add_to_cart AS a
  USING (month)
LEFT JOIN purchase AS p
  USING (month)
ORDER BY pv.month;


-- =========================================================
-- Query 10
-- Calculate weekly revenue from May to July 2017
-- and cumulative revenue.
-- =========================================================

WITH raw_data AS (
  SELECT
    FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
    SUM(product.productRevenue) / 1000000 AS weekly_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0501' AND '0731'
    AND product.productRevenue IS NOT NULL
  GROUP BY 1
)

SELECT
  week,
  ROUND(weekly_revenue, 2) AS weekly_revenue,
  ROUND(
    SUM(weekly_revenue) OVER (
      ORDER BY week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),
    2
  ) AS cumulative_revenue
FROM raw_data
ORDER BY week;
