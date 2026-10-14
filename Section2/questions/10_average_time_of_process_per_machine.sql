-- ============================================================
-- Q10 · Average Time of Process per Machine   (LeetCode #1661, Easy)
-- Pattern : self-join to pair start/end rows, then aggregate the difference
--           (or: conditional aggregation to avoid the self-join)
-- Table   : machine_log(machine_id, process_id, activity, ts NUMERIC)
-- Task    : per machine, average processing time = AVG(end.ts - start.ts)
-- Return  : machine_id, avg_time (round 3)
-- ============================================================

-- Approach 1 — self-join (robust to incomplete start/end pairs):
SELECT s.machine_id,
       ROUND(AVG(e.ts - s.ts), 3) AS avg_time
FROM machine_log s
JOIN machine_log e
  ON s.machine_id = e.machine_id
 AND s.process_id = e.process_id
 AND s.activity = 'start'
 AND e.activity = 'end'
GROUP BY s.machine_id;

-- Approach 2 — conditional aggregation (faster; assumes clean/complete pairs):
-- SELECT machine_id,
--        ROUND(SUM(CASE WHEN activity='end' THEN ts ELSE -ts END)
--              / COUNT(DISTINCT process_id), 3) AS avg_time
-- FROM machine_log
-- GROUP BY machine_id;

-- Senior-DE notes
--  * PAIR ON THE FULL KEY: joining on machine_id alone -> 4x4 cartesian explosion per machine.
--    Must equate machine_id AND process_id.
--  * ON vs WHERE for activity: identical for INNER join; ON reads as "how rows pair".
--  * ROUND type: ts NUMERIC -> AVG numeric -> ROUND(numeric,3) no cast. double would need ::numeric.
--  * Conditional-agg: +ts for 'end', -ts for 'start' = total duration; / count(processes) = avg.
--  * TRADE-OFF: self-join excludes incomplete pairs (fails safe); conditional-agg corrupts them.
--  * Index: CREATE INDEX idx_machine_log_proc ON machine_log (machine_id, process_id, activity);
