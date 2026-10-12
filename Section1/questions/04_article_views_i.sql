-- ============================================================
-- Q4 · Article Views I   (LeetCode #1148, Easy)
-- Pattern : DISTINCT + ORDER BY
-- Table   : products(id, name, category, price)
-- Task    : The distinct product categories, sorted A->Z.
-- Return  : category
-- ============================================================

-- My answer (correct, optimal):
-- SELECT DISTINCT category FROM products ORDER BY category ASC;

-- Reference:
SELECT DISTINCT category
FROM products
ORDER BY category;

-- Senior-DE notes
--  * DISTINCT vs GROUP BY: for pure de-dup with NO aggregates they give the same result and usually
--    the same plan (HashAggregate). Choose by intent — DISTINCT = "just unique values" (this case);
--    GROUP BY = when you actually aggregate (COUNT/SUM/AVG per group).
--  * ORDER BY may only reference columns present in the SELECT DISTINCT output (dedup before sort).
--  * NULLs: DISTINCT keeps one NULL; ASC sorts NULLS LAST by default.
--      drop blanks:     WHERE category IS NOT NULL
--      blanks first:    ORDER BY category NULLS FIRST
--  * ASC is the default; writing it is a harmless clarity choice.
