-- ============================================================================
-- File:        11_employee_bonus.sql
-- LeetCode:    #577 (Employee Bonus)
-- Pattern:     LEFT JOIN + NULL-inclusive filter & Safe Deduplication
-- Dialect:     PostgreSQL
-- ============================================================================

/*
TASK:
Report the name and bonus amount of each employee with a bonus strictly less 
than 1000, including employees who received no bonus at all (amount is NULL).

TABLES:
- employees (id, name, department_id, manager_id, salary, hire_date)
- bonuses   (employee_id, amount)
*/

-- SENIOR DE NOTES ON SUBMISSION:
-- 1. [CRITICAL BUG] ON vs WHERE Placement:
--    - In a LEFT JOIN, right-table filters inside ON determine *which rows match*.
--    - An employee with a bonus >= 1000 fails `b.amount < 1000`, so the join 
--      misses, but the LEFT JOIN still preserves the employee row with NULLs!
--    - Result: High-bonus employees are falsely reported as having no bonus.
--    - Rule: Outer join filtering on the right table MUST go in WHERE to drop rows.
--
-- 2. DISTINCT Syntax & Misconception:
--    - DISTINCT is a row-level query modifier, not a function:
--      `DISTINCT(e.name), b.amount` is evaluated as `DISTINCT e.name, b.amount`.
--    - Putting DISTINCT on display names (`e.name`) causes silent data loss:
--      distinct human beings who share the same name are merged into one.
--    - It masks upstream 1:N fan-out and forces unnecessary sort/hash overhead.


-- ----------------------------------------------------------------------------
-- 2. CANONICAL REFERENCE QUERY (Assuming 1:0..1 Relationship):
-- ----------------------------------------------------------------------------
SELECT 
    e.name,
    b.amount
FROM employees e
LEFT JOIN bonuses b 
    ON e.id = b.employee_id
WHERE b.amount < 1000 
   OR b.amount IS NULL;


-- ----------------------------------------------------------------------------
-- 3. DEDUPLICATION STRATEGIES (Handling 1:N / Dirty Upstream Data):
-- ----------------------------------------------------------------------------
-- Golden Rule: Deduplicate source tables BEFORE joining, never on the final projection.

-- Option A: Exact-Row Deduplication via CTE (Standard DE Pipeline Pattern)
-- Use when pipeline retries caused identical duplicate rows in bonuses.
WITH deduped_bonuses AS (
    SELECT 
        employee_id, 
        amount
    FROM bonuses
    GROUP BY employee_id, amount
)
SELECT 
    e.name,
    b.amount
FROM employees e
LEFT JOIN deduped_bonuses b 
    ON e.id = b.employee_id
WHERE b.amount < 1000 
   OR b.amount IS NULL;


-- Option B: Window Function Deduplication (Business Logic / Conflict Resolution)
-- Use when an employee has multiple different bonuses and you must pick a winner
-- (e.g., pick the highest bonus).
WITH ranked_bonuses AS (
    SELECT 
        employee_id,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id 
            ORDER BY amount DESC
        ) AS rn
    FROM bonuses
)
SELECT 
    e.name,
    b.amount
FROM employees e
LEFT JOIN ranked_bonuses b 
    ON e.id = b.employee_id 
   AND b.rn = 1
WHERE b.amount < 1000 
   OR b.amount IS NULL;


-- Option C: PostgreSQL Idiom (`DISTINCT ON`)
-- Fastest single-pass dedup in Postgres by entity PK (prevents name-merging).
SELECT DISTINCT ON (e.id)
    e.name,
    b.amount
FROM employees e
LEFT JOIN bonuses b 
    ON e.id = b.employee_id
WHERE b.amount < 1000 
   OR b.amount IS NULL
ORDER BY e.id, b.amount DESC NULLS LAST;


-- ----------------------------------------------------------------------------
-- 4. PERFORMANCE & PRODUCTION ARCHITECTURE:
-- ----------------------------------------------------------------------------
-- Postgres Indexing:
--   CREATE INDEX idx_bonuses_emp_amt ON bonuses (employee_id, amount);
--   Allows Index-Only Scans / fast Hash Join build side without heap fetches.
--
-- Distributed / Scale Notes (Spark / Snowflake):
--   - If `bonuses` is small, engines perform a Broadcast Hash Join (no shuffle).
--   - Outer joins that produce excessive NULL join keys can cause severe data skew 
--     if downstream operations repartition on that nullable column.
-- ============================================================================
