-- @Description Tests the basic phantom read behavior of GPDB with serializable.
-- transactions. Actually, no UAO is involved here.
-- 
DROP TABLE IF EXISTS ao;
CREATE TABLE ao (a INT, b INT) WITH (appendonly=true);
INSERT INTO ao SELECT i as a, i as b FROM generate_series(1, 100) AS i;

1: BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
1: SELECT * FROM ao WHERE b BETWEEN 20 AND 30 ORDER BY a;
2: BEGIN;
2: INSERT INTO ao VALUES (101, 25);
2: COMMIT;
1: SELECT * FROM ao WHERE b BETWEEN 20 AND 30 ORDER BY a;
1: COMMIT;
