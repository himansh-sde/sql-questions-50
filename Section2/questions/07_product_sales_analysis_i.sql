-- ============================================================
-- Q7 · Product Sales Analysis I   (LeetCode #1068, Easy)
-- Pattern : inner join + projecting a derived (year) column
-- Tables  : orders(id, customer_id, product_id, quantity, order_date)
--           products(id, name, category, price)
-- Task    : For every order return product name, the order's year, product price.
-- Return  : name, year, price
-- ============================================================

-- My answer (correct):
-- SELECT p.name, EXTRACT(year FROM o.order_date::TIMESTAMP) AS year, p.price
-- FROM orders o JOIN products p ON o.product_id = p.id;

-- Reference (no needless cast; year as int):
SELECT p.name,
       EXTRACT(YEAR FROM o.order_date)::int AS year,
       p.price
FROM orders o
JOIN products p ON o.product_id = p.id;

-- Senior-DE notes
--  * EXTRACT works directly on a DATE -> the ::TIMESTAMP cast is unnecessary (and casting a column
--    is the sargability smell from Q1/Q5: harmless in a projection, index-defeating in WHERE).
--  * "year" has three shapes -> pick what downstream needs:
--      EXTRACT(YEAR FROM d)   -> numeric  (cast ::int for an integer consumer)
--      to_char(d,'YYYY')      -> text     (label/display/group, not math/ranges)
--      date_trunc('year', d)  -> date     (group by year but keep a real date)
--  * INNER JOIN is correct because every order references a real product (mandatory FK).
--    If integrity were in doubt: LEFT JOIN + WHERE p.id IS NULL surfaces orphan orders.
--  * Join uses products.id (PK, indexed) from orders.product_id (FK, not auto-indexed);
--    with 60 products Postgres hashes the small table and seq-scans orders -> optimal.
