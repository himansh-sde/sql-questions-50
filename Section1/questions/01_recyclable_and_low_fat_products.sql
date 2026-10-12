-- ============================================================
-- Q1 · Recyclable and Low Fat Products   (LeetCode #1, Easy)
-- Pattern : filtering on multiple conditions
-- Table   : products(id, name, category, price)
-- Task    : Return the id of every Electronics product priced under 1000.
-- Return  : id
-- ============================================================

-- My answer (correct, optimal):
-- SELECT id FROM products WHERE category='Electronics' AND price < 1000;

-- Reference:
SELECT id
FROM products
WHERE category = 'Electronics'
  AND price < 1000;

-- Senior-DE notes
--  * Projects only `id` (no SELECT *) -> minimal I/O.
--  * Sargable: no function wraps a column, so a B-tree index is usable if present.
--  * At scale (millions of rows), equality col FIRST then range col:
--      CREATE INDEX idx_products_cat_price ON products (category, price);
--    Partial index is tighter if one category dominates:
--      CREATE INDEX idx_products_elec ON products (price) WHERE category='Electronics';
--  * Trap: WHERE LOWER(category)='electronics' would DEFEAT a plain index (needs expression index).
--  * On this 60-row table a Seq Scan is correctly chosen; an index would be slower.
