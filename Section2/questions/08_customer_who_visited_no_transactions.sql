-- ============================================================
-- Q8 · Customer Who Visited but Did Not Make Any Transactions  (LeetCode #1581, Easy)
-- Pattern : anti-join (rows in A with NO match in B)
-- Tables  : customers(id, name, country, referee_id), orders(id, customer_id, ...)
-- Task    : Return the name of every customer who has never placed an order.
-- Return  : name
-- ============================================================

-- My answer (correct, NULL-safe form):
-- SELECT name FROM customers c LEFT JOIN orders o ON c.id = o.customer_id WHERE o.id IS NULL;

-- Reference (senior default — NOT EXISTS):
SELECT c.name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- Equally valid (your form):
-- SELECT c.name FROM customers c LEFT JOIN orders o ON c.id=o.customer_id WHERE o.id IS NULL;

-- Senior-DE notes
--  * THREE forms: LEFT JOIN..IS NULL, NOT EXISTS, NOT IN.
--  * NOT IN + NULL LANDMINE: NOT IN(list) = id<>v1 AND id<>v2 ...; if ANY list value is NULL the whole
--    chain can never be TRUE -> returns ZERO rows for EVERYONE, silently, no error.
--    (Verified: one order with NULL customer_id made NOT IN return 0 instead of 50.)
--    -> Prefer NOT EXISTS / LEFT JOIN..IS NULL (NULL-safe). If forced to use NOT IN, guard it:
--       NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL)
--  * NOT EXISTS is the senior default: NULL-safe, reads like the task, plans as a Hash Anti Join that
--    short-circuits at the first match. LEFT JOIN..IS NULL often plans identically.
--  * Test the PK for NULL (o.id) — it's NULL ONLY when the join missed. Avoid testing nullable cols.
--  * Index orders(customer_id) to make the existence check fast at scale:
--      CREATE INDEX idx_orders_customer_id ON orders (customer_id);
