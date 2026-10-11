-- 0001_stage1_init.sql — Stage 1+2 首批表结构（sessions / events / messages / jobs）
-- 由 migrate Job 按序应用，schema_migrations 记账；全部幂等（IF NOT EXISTS），可重跑。

CREATE TABLE IF NOT EXISTS sessions (
    id          TEXT PRIMARY KEY,
    owner       TEXT NOT NULL,
    name        TEXT NOT NULL DEFAULT '',
    prompt      TEXT NOT NULL DEFAULT '',
    category    TEXT NOT NULL DEFAULT '',
    pinned      BOOLEAN NOT NULL DEFAULT FALSE,
    status      TEXT NOT NULL DEFAULT 'building', -- building | ready | failed
    -- Worker 认领租约：HTTP BeginTurn / Worker CAS 双层防线写入，
    -- 崩溃恢复扫描 status='building' 且租约过期的会话重新入队。
    lease_owner TEXT,
    lease_until TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sessions_owner_idx ON sessions (owner, updated_at DESC);

-- 事件流（Event Stream）：SSE 时间线的唯一事实来源。
-- append-only：seq 每会话从 1 起单调递增、无空洞（done 后所有写入完成）。
CREATE TABLE IF NOT EXISTS events (
    session_id TEXT NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    seq        INT NOT NULL,
    type       TEXT NOT NULL, -- plan | spec | architecture | file | score | done | error | agent | recovered
    agent      TEXT,
    payload    JSONB,
    at         TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (session_id, seq)
);

CREATE TABLE IF NOT EXISTS messages (
    id         BIGSERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    role       TEXT NOT NULL, -- user | agent
    agent      TEXT,
    content    TEXT NOT NULL,
    at         TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS messages_session_idx ON messages (session_id, id);

-- 任务队列（Stage 2 外置队列落地前的持久化记账；Stage 1 进程内队列执行时
-- 同样写 jobs 行，崩溃恢复据此判断哪些会话需要重新入队）。
CREATE TABLE IF NOT EXISTS jobs (
    id          BIGSERIAL PRIMARY KEY,
    kind        TEXT NOT NULL,             -- turn | contest | publish
    session_id  TEXT NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    owner       TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'pending', -- pending | running | done | failed
    attempts    INT NOT NULL DEFAULT 0,
    error       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at  TIMESTAMPTZ,
    finished_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS jobs_status_idx ON jobs (status, id);
