-- 0005_turn_timing.sql — sessions 增加 queued_at / started_at：区分「排队」与
-- 「执行」。queued_at 在入队时写入（Create 的首个回合，或 BeginTurn 的后续回合），
-- started_at 在 Worker 认领执行租约时写入（ClaimLease），BeginTurn 会清空它。
-- 两者之差就是用户在工作台状态徽章上看到的排队时长。
-- 幂等（IF NOT EXISTS），可重跑；两列皆可空，对存量会话无影响（历史回合没有时间
-- 数据，前端退化为只显示「构建中」）。

ALTER TABLE sessions
    ADD COLUMN IF NOT EXISTS queued_at  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
