# SQL 50 Mastery

A hands-on project to master the **LeetCode SQL 50** patterns at a **senior Data Engineer** level —
on a real, industry-scale **PostgreSQL** database running locally.

Each question is practised interactively: solve it, get a senior-level review (correctness,
readability, performance, indexing, edge cases), and keep the optimized query for future reference.

---

## Setup (WSL + Postgres)

```bash
# 1. install + start Postgres (once)
sudo apt update && sudo apt install -y postgresql
sudo service postgresql start

# 2. (if 'peer'/password issues) allow local login, then set a password — see logs if needed

# 3. build the database
sudo -u postgres createdb sqllab
cp setup_lab.sql /tmp/ && chmod 644 /tmp/setup_lab.sql
sudo -u postgres psql -d sqllab -f /tmp/setup_lab.sql

# 4. verify
sudo -u postgres psql -d sqllab -c "\dt"                       # 18 tables
sudo -u postgres psql -d sqllab -c "SELECT count(*) FROM orders;"  # 50060
```

Practice interactively:
```bash
sudo -u postgres psql -d sqllab      # type queries ending in ';', \q to quit
```
Or use the VS Code **SQLTools** + **SQLTools PostgreSQL** extensions (host `localhost`, db `sqllab`).

---

## The database (industry-scale, deterministic)

Built procedurally with `generate_series` + `setseed(0.42)` — small file, big data, same every time:

| Area | Volume |
|------|--------|
| employees | ~1,000 (+ 1 orphan) |
| customers | 5,000 |
| products | 60 |
| orders | 50,060 |
| daily_sales | 731 days |
| logins | ~30,200 |
| + 12 scenario tables | machine_log, price_changes, seats, investments, patients, contacts, ... |

**Intentional quirks** (so each pattern has a real answer): Legal & Facilities have no employees;
customers 4901–5000 never order; "Orphan Ophelia" reports to a missing manager; revenue is 9999 on
2024-06-10/11/12 (consecutive); customer 1 bought all 60 products; `contacts` has duplicate, invalid,
and mixed-case data. Big enough that **indexes and query plans matter** — which is the point.

---

## How each practice session works

1. I present a question (mapped to its real LeetCode number + the pattern it drills).
2. You write your query against `sqllab`.
3. I verify it on the real data and review it at **senior-DE level**:
   correctness · readability · performance & `EXPLAIN ANALYZE` · indexing · edge cases · portability.
4. I give the **optimized / reference query** and log it to `questions/NN_*.sql` and the review log.
5. On request, a **plain-language** explanation of the senior concepts.

---

## The 50-question roadmap

| Section | Questions | Focus |
|---------|-----------|-------|
| 1 · Select | 1–5 | filtering, NULL-safety, DISTINCT, string length |
| 2 · Basic Joins | 6–14 | inner/outer/anti/self joins, pairing rows |
| 3 · Basic Aggregates | 15–22 | COUNT/SUM/AVG, conditional aggregation |
| 4 · Sorting & Grouping | 23–29 | GROUP BY / HAVING, relational division |
| 5 · Advanced Select & Joins | 30–36 | window ranking, running totals, CASE |
| 6 · Subqueries | 37–43 | correlated subqueries, UNION, top-N per group |
| 7 · String / Regex | 44–50 | string/date/pattern functions, dedup |
| Bonus | B1–B8 | gaps & islands, pivots, more reps |

---

## Progress

**Completed: Q1–Q9** (Section 1 done; Section 2 in progress)

| Q | Topic | Result |
|---|-------|--------|
| 1 | Filtering + sargability | correct, optimal |
| 2 | NULL-safe filtering (`IS DISTINCT FROM`) | correct |
| 3 | OR across thresholds + boundary operators | correct |
| 4 | DISTINCT + ORDER BY | correct, optimal |
| 5 | String length + sargability | correct |
| 6 | LEFT JOIN keep-unmatched | correct, optimal |
| 7 | Inner join + year extraction | correct |
| 8 | Anti-join + NOT IN/NULL landmine | correct |
| 9 | Self-join vs LAG + gap trap | correct (gap-safe) |

**Recurring senior themes so far:** sargability (don't wrap columns in functions),
NULL semantics (`IS DISTINCT FROM`, the `NOT IN` landmine), half-open date ranges,
`LEFT JOIN` + WHERE-vs-ON, `NOT EXISTS` over `NOT IN`, and "previous row ≠ previous day with gaps".

---

## Credits / notes

Practice problems here are **original**, written to mirror each LeetCode SQL 50 skill (not copies of
LeetCode's problem statements). Each `questions/` file links the real problem to solve on their judge.
Dialect: PostgreSQL (the `sql50_mastery.sql` bundle is SQLite; notes flag where dialects differ).
