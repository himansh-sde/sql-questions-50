-- ============================================================
-- Q3 · Big Countries   (LeetCode #595, Easy)
-- Pattern : OR across two independent thresholds + boundary operators
-- Table   : employees(id, name, department_id, manager_id, salary, hire_date)
-- Task    : name, salary of employees earning at least 120000
--           OR hired before 2020-01-01.
-- Return  : name, salary
-- ============================================================

-- My answer (correct — both boundaries right):
-- SELECT name, salary FROM employees WHERE salary >= 120000 OR hire_date < '2020-01-01';

-- Reference:
SELECT name, salary
FROM employees
WHERE salary >= 120000
   OR hire_date < DATE '2020-01-01';

-- Senior-DE notes
--  * "at least"  -> inclusive -> >=    (">" would drop exactly 120000)
--  * "before X"  -> exclusive -> <     ("<=" would wrongly include Jan 1)
--  * Use ISO dates (YYYY-MM-DD); optionally explicit cast DATE '...'.
--  * Prefer HALF-OPEN ranges (>= start AND < end) for date/time — essential if the column is a
--    TIMESTAMP ("<= '2019-12-31'" would drop 2019-12-31 14:30).
--  * Indexing: OR across DIFFERENT columns can't use one composite index (that helps AND).
--    Postgres may BitmapOr two single-col indexes (salary, hire_date) only if each arm is selective.
--    This filter returns a large fraction -> Seq Scan is the correct plan.
