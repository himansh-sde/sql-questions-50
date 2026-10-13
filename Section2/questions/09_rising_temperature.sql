-- ============================================================
-- Q9 · Rising Temperature   (LeetCode #197, Easy)
-- Pattern : self-join — compare a row to the previous CALENDAR day
-- Table   : daily_sales(day DATE, revenue INT)
-- Task    : Return the day of every date whose revenue beat the day before.
-- Return  : day
-- ============================================================

-- My answer (correct, gap-safe):
-- SELECT ds1.day FROM daily_sales ds1
-- JOIN daily_sales ds2 ON ds2.day = ds1.day - INTERVAL '1 DAY'
-- WHERE ds1.revenue > ds2.revenue;

-- Reference (self-join, clean integer date math + readable aliases):
SELECT today.day
FROM daily_sales today
JOIN daily_sales yday ON yday.day = today.day - 1
WHERE today.revenue > yday.revenue;

-- Window-function alternative (faster at scale; REQUIRES the gap guard):
-- SELECT day FROM (
--   SELECT day, revenue,
--          LAG(revenue) OVER (ORDER BY day) AS prev_rev,
--          LAG(day)     OVER (ORDER BY day) AS prev_day
--   FROM daily_sales) t
-- WHERE revenue > prev_rev AND prev_day = day - 1;

-- Senior-DE notes
--  * Join on `yday.day = today.day - 1` demands the immediately preceding CALENDAR day exists, so a
--    missing day has no partner and is correctly skipped (previous DAY, not previous ROW).
--  * `today.day - INTERVAL '1 DAY'` yields a TIMESTAMP; prefer `today.day - 1` (date - int = date).
--  * LAG compares the previous ROW = previous DAY only with NO gaps. Verified: naive LAG wrongly
--    added the day after a gap; the self-join did not. Guard LAG with `prev_day = day - 1`.
--  * LAG is usually faster on large time series (one sort, no join).
--  * Index: CREATE INDEX idx_daily_sales_day ON daily_sales (day);
