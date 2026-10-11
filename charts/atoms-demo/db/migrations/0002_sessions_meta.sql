-- 0002_sessions_meta.sql — sessions 聚合根的 JSONB 子结构：发布记录与竞赛状态。
-- 发布版本数组与竞赛状态机读写频繁且形态演进快，用 JSONB 整存整取，
-- 语义与磁盘版 session.json 中的字段一一对应；结构化查询需求出现时再做拆分迁移。

ALTER TABLE sessions
    ADD COLUMN IF NOT EXISTS publishes JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS contest  JSONB;
