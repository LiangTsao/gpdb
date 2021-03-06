-- @Description Tests that a update operation in progress will block all other updates
-- until the transaction is committed.
-- 
DROP TABLE IF EXISTS ao;
CREATE TABLE ao (a INT, b INT) WITH (appendonly=true);
INSERT INTO ao SELECT i as a, i as b FROM generate_series(1,10) AS i;

DROP VIEW IF EXISTS locktest;
create view locktest as select coalesce(
	case when relname like 'pg_toast%index' then 'toast index'
	when relname like 'pg_toast%' then 'toast table'
	else relname end, 'dropped table'),
	mode,
	locktype from
	pg_locks l left outer join pg_class c on (l.relation = c.oid),
	pg_database d where relation is not null and l.database = d.oid and
	l.gp_segment_id = -1 and
	relname != 'gp_fault_strategy' and
	d.datname = current_database() order by 1, 3, 2;

-- The actual test begins
1: BEGIN;
2: BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
1: UPDATE ao SET b = 42 WHERE b = 1;
2&: UPDATE ao SET b = -1 WHERE b = 1;
1: COMMIT;
2<:
2: COMMIT;
SELECT * FROM ao WHERE b < 2;
