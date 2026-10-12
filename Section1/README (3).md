# SQL 50 Mastery — Practice Log & Review

A running record of each question, my answer, the senior-DE review, and the optimized query.
Database: Postgres (`sqllab`), built from `setup_lab.sql` (~93k rows, industry-scale).

## Scoreboard
| Q | Topic | Result |
|---|-------|--------|
| 1 | Filtering + sargability | correct, optimal |

---

## Q1 — Filtering on multiple conditions
*Maps to LeetCode #1, Recyclable and Low Fat Products (Easy)*

**Task:** From `products`, return the `id` of every product in the `Electronics` category priced under `1000`.
**Return:** `id` · **Table:** `products(id, name, category, price)`

**My answer**
```sql
SELECT id FROM products WHERE category='Electronics' AND price < 1000;
```

**Verdict:** Correct and already optimal — nothing to change.

### Why it's good
- Projects only `id` (no `SELECT *`) -> minimal I/O.
- Predicates are **sargable** (search-argument-able): each compares a column directly to a
  constant with no function wrapping the column, so an index could be used if one existed.

### Optimized / reference query (same as mine)
```sql
SELECT id
FROM products
WHERE category = 'Electronics'
  AND price < 1000;
```

### Indexing (only matters at scale)
On this 60-row table Postgres correctly does a sequential scan. If `products` were millions of
rows and this filter were hot:
```sql
-- equality column FIRST, range column SECOND
CREATE INDEX idx_products_cat_price ON products (category, price);
```
Column order matters: Postgres seeks to `category='Electronics'`, then range-scans `price < 1000`
within it. A partial index (`... WHERE category='Electronics'`) is even tighter if that category
dominates queries.

### The sargability trap (remember this)
- GOOD: `WHERE category = 'Electronics'` -> index usable.
- BAD:  `WHERE LOWER(category) = 'electronics'` -> wrapping the column in a function defeats a plain
  index (would need an expression index instead).

---

## Understanding EXPLAIN ANALYZE

### The query plan seen for Q1
```
Seq Scan on products  (cost=0.00..1.90 rows=6 width=4) (actual time=0.018..0.022 rows=6 loops=1)
  Filter: ((price < 1000) AND (category = 'Electronics'::text))
  Rows Removed by Filter: 54
Planning Time: 0.099 ms
Execution Time: 0.041 ms
```

### Technical reading
- **Seq Scan** - read the whole table. Correct for a tiny table; an index adds indirection that
  only pays off when it lets you skip most of the table.
- **cost=0.00..1.90** - planner's estimate (startup..total) in arbitrary units, used to compare plans.
- **rows=6 (estimate) vs actual rows=6** - the key habit: compare estimate to actual. Close match =
  healthy table statistics = you can trust the planner. Wild divergence = stale stats (run `ANALYZE`)
  or data skew, and usually the root cause of a bad plan on big queries.
- **Rows Removed by Filter: 54** - scanned 60, kept 6. A high removed-ratio on a large table is the
  hint that an index could skip that wasted work.
- **Planning vs Execution Time** - planning can exceed execution on trivial queries; only worth
  caring about for hot, repeated queries.
- Tip: `EXPLAIN (ANALYZE, BUFFERS) ...` also shows cache hits vs disk reads.

### Plain-language version
Think of the table as a **book** and the query as "find every Electronics product under $1000."
Postgres first makes a **plan** for the fastest way to find it, then (with ANALYZE) actually does it
and reports back.

Two ways to find something:
1. **Read every page** = Seq Scan. Simple, and genuinely fastest when the book is short.
2. **Use the index at the back** = Index Scan. A huge win only when the book is enormous
   (finding one topic in a 10,000-page encyclopedia - you'd never read it all).

Postgres picks between them automatically based on table size and how much it needs.

What the Q1 plan said, in plain terms:
- "I read the whole table" (Seq Scan) - the right call, because it's only 60 rows. Using an index
  to find 6 of 60 rows is like using an encyclopedia's index to search a one-page pamphlet.
- "I guessed 6 would match, and 6 actually did" - Postgres understands the data well.
- "I looked at 60, threw away 54, kept 6."
- "Finished in 0.041 ms" - essentially instant.

Optimization in two rules:
1. Small table -> don't worry. Reading everything is fine. Q1 is already optimal.
2. Huge table -> help it jump to the answer with an index instead of reading everything.

The one trap: for the index shortcut to work, compare the column as-is. A phone book is sorted
by last name so you can flip straight to "Smith" - but ask for "everyone whose ALL-CAPS name is
SMITH" and the sorting no longer helps; you'd check every entry. `WHERE category='Electronics'` keeps
the shortcut; `WHERE LOWER(category)='electronics'` throws it away.

One sentence: EXPLAIN ANALYZE shows Postgres's plan and how long it took; optimization is mostly
making sure that on big tables it can jump to the answer via an index rather than read the whole
table - and Q1 was already perfect because the table is tiny.

---

## Q2 — NULL-safe filtering
*Maps to LeetCode #584, Find Customer Referee (Easy)*

**Task:** From `customers`, return the `name` of every customer NOT referred by customer 1, INCLUDING customers with no referrer (`referee_id IS NULL`).
**Return:** `name` · **Table:** `customers(id, name, country, referee_id)`

**My answer**
```sql
SELECT name FROM customers WHERE referee_id != 1 OR referee_id IS NULL;
```

**Verdict:** Correct — did not fall into the NULL trap.

### The trap (the whole point of this question)
NULL means "unknown". ANY comparison with NULL returns NULL (not TRUE/FALSE). `WHERE` keeps only
TRUE rows, so it drops both FALSE and NULL. Therefore a bare `WHERE referee_id != 1` SILENTLY drops
every customer whose referee is NULL. The explicit `OR referee_id IS NULL` rescues them.

### Senior polish
- Prefer standard `<>` over non-standard `!=` (both work in Postgres).
- Cleanest idiom: `WHERE referee_id IS DISTINCT FROM 1` — null-safe, treats NULL as a comparable
  value (`NULL IS DISTINCT FROM 1` = TRUE), so NULLs are kept with no second condition.
  Trade-off: `IS DISTINCT FROM` is NOT sargable (can't use a plain B-tree index); the
  `<> 1 OR IS NULL` form can. Doesn't matter on a filter that returns most of the table.

### Reference query
```sql
SELECT name FROM customers WHERE referee_id IS DISTINCT FROM 1;          -- clearest
SELECT name FROM customers WHERE referee_id <> 1 OR referee_id IS NULL;  -- index-friendly, portable
```

### Portability
`OR ... IS NULL` works everywhere. `IS DISTINCT FROM` is standard SQL + Postgres, but MySQL lacks it
(there: `NOT (referee_id <=> 1)`).

### Plain-language version
A blank (NULL) means "unknown", and the database refuses to guess. Ask "is the referee different
from 1?" for a blank and it shrugs: "unknown" — not yes, not no. The `WHERE` clause is a strict
bouncer that only admits a definite YES, so "unknown" rows get turned away and silently vanish.
Writing `OR referee_id IS NULL` adds a second door specifically for the blanks. `IS DISTINCT FROM 1`
is the one-breath version that treats blank as just another value different from 1.
Takeaway: when filtering with `!=`/`<>`, always also include the blanks, or NULLs disappear.

---

## Q3 — OR across two thresholds
*Maps to LeetCode #595, Big Countries (Easy)*

**Task:** From `employees`, return `name`, `salary` of employees earning at least 120000 OR hired before 2020-01-01.
**Return:** `name, salary` · **Table:** `employees(id, name, department_id, manager_id, salary, hire_date)`

**My answer**
```sql
SELECT name, salary FROM employees WHERE salary >= 120000 OR hire_date < '2020-01-01';
```

**Verdict:** Correct — both boundaries right.

### Boundary mapping (what this tests)
- "at least" -> inclusive -> `>=` (not `>`). "more than/under/before" -> exclusive -> `>`/`<`.
- "before 2020-01-01" -> `< '2020-01-01'` (Jan 1 excluded). Classic bug is `<=`.

### Senior notes
- Use ISO date format `YYYY-MM-DD` (unambiguous). Optionally make the cast explicit: `DATE '2020-01-01'`.
- Half-open ranges for date/time: prefer `>= start AND < end`. Essential when the column is a
  TIMESTAMP (`<= '2019-12-31'` would drop `2019-12-31 14:30`).
- Indexing: `OR` across DIFFERENT columns can't use one composite index (composite helps AND). Postgres
  may BitmapOr two single-column indexes (`salary`, `hire_date`) — only if each arm is selective.
  This filter returns a large fraction, so a Seq Scan is correctly chosen.

### Reference query
```sql
SELECT name, salary FROM employees
WHERE salary >= 120000 OR hire_date < DATE '2020-01-01';
```

---

## Q4 — DISTINCT + ORDER BY
*Maps to LeetCode #1148, Article Views I (Easy)*

**Task:** From `products`, return the distinct product categories, sorted A->Z.
**Return:** `category` · **Table:** `products(id, name, category, price)`

**My answer**
```sql
SELECT DISTINCT category FROM products ORDER BY category ASC;
```

**Verdict:** Correct and optimal.

### DISTINCT vs GROUP BY
For pure de-duplication with NO aggregates, both give the same result and usually the same plan
(HashAggregate). Choose by intent: DISTINCT = "just unique values" (this case); GROUP BY = when you
actually aggregate (COUNT/SUM/AVG per group).

### Senior notes
- `ORDER BY` can only use columns present in the `SELECT DISTINCT` output (dedup happens before sort).
- NULLs: DISTINCT keeps one NULL; ASC sorts NULLS LAST by default. Use `WHERE category IS NOT NULL`
  to drop, or `ORDER BY category NULLS FIRST` to reposition.
- `ASC` is the default; writing it is a harmless clarity choice.

### Reference query
```sql
SELECT DISTINCT category FROM products ORDER BY category;
```

---

## Q5 — Filtering by string length
*Maps to LeetCode #1683, Invalid Tweets (Easy)*

**Task:** From `products`, return `id`, `name` of products whose name is longer than 5 characters.
**Return:** `id, name` · **Table:** `products(id, name, category, price)`

**My answer**
```sql
SELECT id, name FROM products WHERE LENGTH(name) > 5;
```

**Verdict:** Correct (`> 5` excludes exactly-5, as required).

### Senior notes
- Characters vs bytes: Postgres `LENGTH` = characters (fine). `OCTET_LENGTH` = bytes. In MySQL,
  `LENGTH` = BYTES and `CHAR_LENGTH` = characters -> same query can differ across engines. For
  "length of text" prefer the explicit, portable `CHAR_LENGTH(name)`.
- Sargability: `LENGTH(name)` wraps the column in a function -> defeats a plain B-tree index -> Seq
  Scan. At scale use an EXPRESSION index: `CREATE INDEX ... ON products (LENGTH(name));`
  or a partial index `... ON products (id) WHERE LENGTH(name) > 5;`.
- NULL: `LENGTH(NULL)` -> NULL -> `NULL > 5` -> NULL -> row dropped (desired).

### Reference query
```sql
SELECT id, name FROM products WHERE CHAR_LENGTH(name) > 5;
```

---

## Scoreboard (updated)
| Q | Topic | Result |
|---|-------|--------|
| 1 | Filtering + sargability | correct, optimal |
| 2 | NULL-safe filtering | correct (avoided NULL trap) |
| 3 | OR across thresholds + boundaries | correct |
| 4 | DISTINCT + ORDER BY | correct, optimal |
| 5 | String length + sargability | correct |

**Section 1 (Select) complete — 5/5.**
