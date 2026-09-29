-- ============================================================
-- Walmart Store Sales Analysis — Business Questions
-- Dataset: Walmart Recruiting - Store Sales Forecasting (Kaggle)
-- Real weekly sales data, 45 stores, 2010-2012
-- ============================================================

-- Q1: Which store types (A/B/C) generate the most total sales,
-- and does store size correlate with performance?
SELECT
  st.type,
  COUNT(DISTINCT st.store) AS num_stores,
  ROUND(SUM(s.weekly_sales), 2) AS total_sales,
  ROUND(AVG(st.size), 0) AS avg_store_size,
  ROUND(SUM(s.weekly_sales) / COUNT(DISTINCT st.store), 2) AS avg_sales_per_store
FROM sales s
JOIN stores st ON s.store = st.store
GROUP BY st.type
ORDER BY total_sales DESC;


-- Q2: Do sales spike during holiday weeks vs non-holiday weeks?
SELECT
  IsHoliday,
  COUNT(*) AS num_records,
  ROUND(AVG(Weekly_Sales), 2) AS avg_weekly_sales
FROM sales
GROUP BY IsHoliday;


-- Q3: Top 10 highest-revenue store/department combinations
SELECT
  store,
  dept,
  ROUND(SUM(weekly_sales), 2) AS total_sales
FROM sales
GROUP BY store, dept
ORDER BY total_sales DESC
LIMIT 10;


-- Q4: Month-over-month sales trend across the full dataset,
-- using LAG() to compare each month to the previous one
WITH monthly AS (
  SELECT
    strftime('%Y-%m', date) AS month,
    SUM(weekly_sales) AS total_sales
  FROM sales
  GROUP BY 1
)
SELECT
  month,
  ROUND(total_sales, 2) AS total_sales,
  ROUND(total_sales - LAG(total_sales) OVER (ORDER BY month), 2) AS change_vs_prev_month
FROM monthly
ORDER BY month;


-- Q5: Rank the top 3 departments by total sales within each store type
WITH dept_sales AS (
  SELECT
    st.type,
    s.dept,
    SUM(s.weekly_sales) AS total_sales
  FROM sales s
  JOIN stores st ON s.store = st.store
  GROUP BY st.type, s.dept
),
ranked AS (
  SELECT
    type,
    dept,
    ROUND(total_sales, 2) AS total_sales,
    RANK() OVER (PARTITION BY type ORDER BY total_sales DESC) AS rank_in_type
  FROM dept_sales
)
SELECT * FROM ranked
WHERE rank_in_type <= 3
ORDER BY type, rank_in_type;


-- Q6: Does the presence of markdown promotions correlate with
-- higher average sales for that store/week? (using the features table)
SELECT
  CASE WHEN f.markdown1 IS NOT NULL THEN 'Had Markdown1 promo' ELSE 'No Markdown1 promo' END AS promo_status,
  COUNT(*) AS num_weeks,
  ROUND(AVG(s.weekly_sales), 2) AS avg_weekly_sales
FROM sales s
JOIN features f ON s.store = f.store AND s.date = f.date
GROUP BY promo_status;
