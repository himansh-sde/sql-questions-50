# SQL 50 Mastery — Review Log (Q6–Q9: Basic Joins)

Database: Postgres (`sqllab`), built from `setup_lab.sql` (~93k rows).
Each entry: task -> my answer -> verdict -> senior-DE notes -> reference query -> plain-language.

---

## Q6 — LEFT JOIN to a mapping table (keep unmatched)
*Maps to LeetCode #1378, Replace Employee ID With The Unique Identifier (Easy)*

**Task:** For every employee return `name` and `uuid`; `uuid` is NULL for employees with no mapping.
**Return:** `name, uuid` · **Tables:** `employees(...)`, `employee_uuids(employee_id, uuid)`

**My answer**
```sql
SELECT e.name, eu.uuid FROM employees e LEFT JOIN employee_uuids eu ON e.id = eu.employee_id;
```

**Verdict:** Correct and optimal. All 1001 employees (100 with NULL uuid). INNER JOIN would return
only 901 — silently dropping the 100 unmapped.

### Senior notes
- "for EVERY employee" -> LEFT JOIN. The must-keep table goes on the LEFT.
- WHERE-vs-ON trap: a condition on the RIGHT (optional) table belongs in `ON`, not `WHERE`. In
  `WHERE` it rejects NULL-extended rows (`NULL > x` = NULL) -> LEFT JOIN silently collapses to INNER.
      keep all, blank some : ... ON e.id=eu.employee_id AND eu.issued_at > DATE '2024-01-01'
      accidental inner join: ... ON e.id=eu.employee_id WHERE eu.issued_at > DATE '2024-01-01'
- Indexing: PKs auto-indexed; FK columns are NOT. Index the child join column:
      CREATE INDEX idx_emp_uuids_emp_id ON employee_uuids (employee_id);

### Reference query
```sql
SELECT e.name, eu.uuid
FROM employees e
LEFT JOIN employee_uuids eu ON e.id = eu.employee_id;
```

### Plain-language
INNER JOIN = "keep only perfect matches" -> throws away the 100 badge-less people. LEFT JOIN =
"protect my main list, lose nobody" -> keeps all, writes blank where there's no badge. "Every"/"all"
is the signal for LEFT JOIN; the must-keep list goes on the LEFT. WHERE-vs-ON: staple badges (ON),
then throw away rows (WHERE); filtering the badge in WHERE drops the blank-badge people — secretly an
INNER JOIN. Indexing: auto on primary keys, NOT on the foreign-key link column (common slow-join cause).

---

## Q7 — Inner join + derived (year) column
*Maps to LeetCode #1068, Product Sales Analysis I (Easy)*

**Task:** For every order return product `name`, the order's `year`, product `price`.
**Return:** `name, year, price` · **Tables:** `orders(...)`, `products(...)`

**My answer**
```sql
SELECT p.name, EXTRACT(year FROM o.order_date::TIMESTAMP) AS year, p.price
FROM orders o JOIN products p ON o.product_id = p.id;
```

**Verdict:** Correct (all 50,060 rows). Two refinements, neither a bug.

### Senior notes
- `::TIMESTAMP` is unnecessary — EXTRACT works on a DATE. Casting a column is the sargability smell
  (harmless in a projection, index-defeating in WHERE).
- "year" shapes: EXTRACT -> numeric (cast ::int); to_char(d,'YYYY') -> text; date_trunc('year',d) -> date.
- INNER is correct because every order has a real product (mandatory FK). If integrity were in doubt,
  LEFT JOIN + WHERE p.id IS NULL surfaces orphans. (Differs from Q6, whose mapping was intentionally partial.)

### Reference query
```sql
SELECT p.name, EXTRACT(YEAR FROM o.order_date)::int AS year, p.price
FROM orders o JOIN products p ON o.product_id = p.id;
```

### Plain-language
Join is a straight staple here because every order points at a real product, so nothing is lost —
INNER is fine. Only use LEFT when some rows might not match AND you want to keep/inspect them.
"Year" can be a number (math/ranges), text (labels), or a real date (grouping but keep sortable) —
pick what the next step needs. Don't cast a column just in case; needless casts can switch off indexes.

---

## Q8 — Anti-join (rows in A with no match in B)
*Maps to LeetCode #1581, Customer Who Visited but Did Not Make Any Transactions (Easy)*

**Task:** Return the `name` of every customer who has never placed an order.
**Return:** `name` · **Tables:** `customers(...)`, `orders(...)`

**My answer**
```sql
SELECT name FROM customers c LEFT JOIN orders o ON c.id = o.customer_id WHERE o.id IS NULL;
```

**Verdict:** Correct; picked a NULL-safe form.

### The three forms
```sql
-- 1) LEFT JOIN ... IS NULL  (yours)
SELECT c.name FROM customers c LEFT JOIN orders o ON c.id=o.customer_id WHERE o.id IS NULL;
-- 2) NOT EXISTS  (senior default)
SELECT c.name FROM customers c WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id=c.id);
-- 3) NOT IN  (DANGEROUS)
SELECT c.name FROM customers c WHERE c.id NOT IN (SELECT customer_id FROM orders);
```

### Senior notes
- NOT IN + NULL LANDMINE: if the subquery returns ANY NULL, NOT IN yields ZERO rows for everyone,
  silently (verified: a NULL customer_id made it return 0 instead of 50). Prefer NOT EXISTS /
  LEFT JOIN..IS NULL; if forced to NOT IN, add `WHERE customer_id IS NOT NULL`.
- NOT EXISTS is the default: NULL-safe, reads like the task, plans as a Hash Anti Join (short-circuits).
- Test the PK for NULL (`o.id`) — NULL only when the join missed.
- Index `orders(customer_id)` for a fast existence check at scale.

### Reference query
```sql
SELECT c.name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

### Plain-language
"Who's in the guest list but never bought?" = anti-join. Safe ways: LEFT JOIN..IS NULL ("pair up,
keep the unpaired") and NOT EXISTS ("for each person, does even one order exist? if no, keep them" —
reads like the question, stops at the first match). Avoid NOT IN: a blank in its list means "unknown
person", and the DB can't rule out that the unknown is any given customer, so it answers "unknown"
for everyone -> ZERO rows, no error. Check `o.id IS NULL` because a primary key is blank ONLY when
no match was found.

---

## Q9 — Self-join (compare a row to the previous day)
*Maps to LeetCode #197, Rising Temperature (Easy)*

**Task:** From `daily_sales`, return the `day` of every date whose revenue beat the day before.
**Return:** `day` · **Table:** `daily_sales(day DATE, revenue INT)`

**My answer**
```sql
SELECT ds1.day FROM daily_sales ds1
JOIN daily_sales ds2 ON ds2.day = ds1.day - INTERVAL '1 DAY'
WHERE ds1.revenue > ds2.revenue;
```

**Verdict:** Correct, INCLUDING gap handling (a missing calendar day is correctly skipped; naive LAG
would wrongly include the day after the gap).

### Senior notes
- Join on `yesterday.day = today.day - 1` demands the previous CALENDAR day exists (previous DAY, not
  previous ROW) -> gaps handled for free.
- `today.day - INTERVAL '1 DAY'` yields a TIMESTAMP; prefer `today.day - 1` (date - int = date).
- LAG alternative is faster at scale (one sort, no join) BUT compares the previous ROW = previous DAY
  only with no gaps; guard it: `AND prev_day = day - 1`.
- Index: `CREATE INDEX idx_daily_sales_day ON daily_sales (day);`

### Reference queries
```sql
-- self-join (gap-safe, clean types):
SELECT today.day FROM daily_sales today
JOIN daily_sales yday ON yday.day = today.day - 1
WHERE today.revenue > yday.revenue;

-- window (faster at scale; needs the gap guard):
SELECT day FROM (
  SELECT day, revenue,
         LAG(revenue) OVER (ORDER BY day) AS prev_rev,
         LAG(day)     OVER (ORDER BY day) AS prev_day
  FROM daily_sales) t
WHERE revenue > prev_rev AND prev_day = day - 1;
```

### Plain-language
A table is an unordered bag of rows, so you must build "yesterday" yourself. Self-join = print the
table twice (TODAY / YESTERDAY), slide YESTERDAY down a day, keep rows where today beat yesterday;
a missing day simply has no partner and is skipped. LAG = sort by date and peek at the row above;
faster on big data, but it peeks at the previous ROW, which equals the previous DAY only when nothing
is missing — with a gap it compares across it and is wrong, so guard by checking the neighbour's date.
Takeaway: previous row != previous day whenever data can have gaps.

---

## Scoreboard (Q6–Q9)
| Q | Topic | Result |
|---|-------|--------|
| 6 | LEFT JOIN keep-unmatched | correct, optimal |
| 7 | Inner join + year extraction | correct |
| 8 | Anti-join + NOT IN/NULL landmine | correct |
| 9 | Self-join vs LAG + gap trap | correct (gap-safe) |
