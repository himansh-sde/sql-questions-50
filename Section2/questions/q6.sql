-- ============================================================
-- Q6 · Replace Employee ID With The Unique Identifier   (LeetCode #1378, Easy)
-- Pattern : LEFT JOIN to a mapping table, keep unmatched rows
-- Tables  : employees(id, name, department_id, manager_id, salary, hire_date)
--           employee_uuids(employee_id, uuid)   -- only ~90% of employees mapped
-- Task    : For EVERY employee return name + uuid; uuid is NULL when unmapped.
-- Return  : name, uuid
-- ============================================================

-- My answer (correct, optimal):
-- SELECT e.name, eu.uuid FROM employees e LEFT JOIN employee_uuids eu ON e.id = eu.employee_id;

-- Reference:
SELECT e.name, eu.uuid
FROM employees e
LEFT JOIN employee_uuids eu ON e.id = eu.employee_id;

-- Senior-DE notes
--  * "for EVERY employee" -> LEFT JOIN (INNER JOIN would silently drop the ~100 unmapped).
--    Verified: LEFT JOIN -> 1001 rows (100 NULL uuid); INNER JOIN -> only 901.
--  * The must-keep table goes on the LEFT. (employee_uuids LEFT JOIN employees = wrong anchor.)
--  * WHERE-vs-ON trap: a condition on the RIGHT (optional) table belongs in ON, not WHERE.
--      keep all, blank some : ... ON e.id=eu.employee_id AND eu.issued_at > DATE '2024-01-01'
--      accidental INNER join: ... ON e.id=eu.employee_id WHERE eu.issued_at > DATE '2024-01-01'
--    A WHERE on the right table rejects NULL-extended rows (NULL > x = NULL) and drops unmatched rows.
--  * Indexing: primary keys are auto-indexed; FOREIGN-KEY columns are NOT. Index the child join col:
--      CREATE INDEX idx_emp_uuids_emp_id ON employee_uuids (employee_id);
--    Enables efficient nested-loop / merge joins at scale; a classic missing-index cause of slow joins.
