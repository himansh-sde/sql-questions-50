-- ============================================================
-- Q5 · Invalid Tweets   (LeetCode #1683, Easy)
-- Pattern : filtering by string length
-- Table   : products(id, name, category, price)
-- Task    : id, name of products whose name is longer than 5 characters.
-- Return  : id, name
-- ============================================================

-- My answer (correct — "> 5" excludes exactly-5):
-- SELECT id, name FROM products WHERE LENGTH(name) > 5;

-- Reference (portable + explicit about characters):
SELECT id, name
FROM products
WHERE CHAR_LENGTH(name) > 5;

-- Senior-DE notes
--  * Characters vs bytes: Postgres LENGTH = characters (OK). OCTET_LENGTH = bytes.
--    MySQL LENGTH = BYTES, CHAR_LENGTH = characters -> same query can differ across engines.
--    For "length of text" prefer the explicit, portable CHAR_LENGTH.
--  * Sargability: a function on the column (LENGTH(name)) defeats a plain B-tree index -> Seq Scan.
--    At scale use an EXPRESSION index:
--      CREATE INDEX idx_products_name_len ON products (CHAR_LENGTH(name));
--    or a PARTIAL index:
--      CREATE INDEX idx_products_longname ON products (id) WHERE CHAR_LENGTH(name) > 5;
--  * NULL: LENGTH(NULL) -> NULL -> NULL > 5 -> NULL -> row dropped (desired).
