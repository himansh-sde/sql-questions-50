-- ============================================================
-- Q2 · Find Customer Referee   (LeetCode #584, Easy)
-- Pattern : NULL-safe filtering (the classic <> NULL trap)
-- Table   : customers(id, name, country, referee_id)
-- Task    : Names of customers NOT referred by customer 1,
--           INCLUDING customers with no referrer (referee_id IS NULL).
-- Return  : name
-- ============================================================

-- My answer (correct — avoided the NULL trap):
-- SELECT name FROM customers WHERE referee_id != 1 OR referee_id IS NULL;

-- Reference (clearest, null-safe):
SELECT name
FROM customers
WHERE referee_id IS DISTINCT FROM 1;

-- Equivalent, index-friendly + cross-engine portable:
-- SELECT name FROM customers WHERE referee_id <> 1 OR referee_id IS NULL;

-- Senior-DE notes
--  * THE TRAP: NULL means "unknown". Any comparison with NULL yields NULL (not TRUE/FALSE),
--    and WHERE keeps only TRUE rows -> a bare `referee_id <> 1` SILENTLY drops all NULL referees.
--    `OR referee_id IS NULL` (or IS DISTINCT FROM) rescues them.
--  * Prefer standard `<>` to non-standard `!=` (both work in Postgres).
--  * IS DISTINCT FROM is the one-breath null-safe form, BUT it is not sargable (no plain B-tree
--    index). The `<> 1 OR IS NULL` form can use an index. Irrelevant when the filter returns most rows.
--  * Portability: `OR IS NULL` works everywhere. IS DISTINCT FROM is standard SQL + Postgres;
--    MySQL lacks it (use: NOT (referee_id <=> 1)).
