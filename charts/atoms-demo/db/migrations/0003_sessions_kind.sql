-- 0003_sessions_kind.sql — sessions 增加 kind 列：记录 building 期间在跑的 任务
-- (Job) 类型（turn | contest | publish），供崩溃恢复 sweeper 扫描时重新入队。
-- 幂等（IF NOT EXISTS），可重跑。lease_owner/lease_until 列已在 0001 建好，
-- 这里只补一个 building 部分索引，让 sweeper 的「无有效租约」扫描走索引。

ALTER TABLE sessions
    ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS sessions_building_lease_idx
    ON sessions (lease_until) WHERE status = 'building';
