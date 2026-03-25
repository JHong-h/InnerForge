use rusqlite::Connection;
use std::path::Path;
use std::sync::Mutex;

pub struct DbState(pub Mutex<Connection>);

pub fn initialize(db_path: &Path) -> Result<Connection, Box<dyn std::error::Error>> {
    let conn = Connection::open(db_path)?;
    conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;
    run_migrations(&conn)?;
    Ok(conn)
}

fn run_migrations(conn: &Connection) -> Result<(), Box<dyn std::error::Error>> {
    conn.execute_batch(
        "
        CREATE TABLE IF NOT EXISTS ai_configs (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            provider TEXT NOT NULL,
            endpoint TEXT DEFAULT '',
            model_id TEXT NOT NULL,
            api_key TEXT DEFAULT '',
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS periods (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            intention TEXT DEFAULT '',
            start_date TEXT NOT NULL,
            planned_end_date TEXT NOT NULL,
            actual_end_date TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS entries (
            id TEXT PRIMARY KEY,
            period_id TEXT NOT NULL REFERENCES periods(id) ON DELETE CASCADE,
            date TEXT NOT NULL,
            content TEXT DEFAULT '',
            mood INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS attachments (
            id TEXT PRIMARY KEY,
            entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
            relative_path TEXT NOT NULL,
            thumbnail_path TEXT,
            file_name TEXT NOT NULL,
            file_size INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS reports (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            skill_id TEXT NOT NULL,
            period_id TEXT REFERENCES periods(id) ON DELETE SET NULL,
            entry_id TEXT REFERENCES entries(id) ON DELETE SET NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS skill_records (
            id TEXT PRIMARY KEY,
            skill_id TEXT NOT NULL,
            skill_name TEXT NOT NULL,
            input TEXT NOT NULL,
            output TEXT,
            status TEXT DEFAULT 'pending',
            error_message TEXT,
            started_at TEXT NOT NULL,
            completed_at TEXT
        );

        CREATE TABLE IF NOT EXISTS daily_todos (
            id TEXT PRIMARY KEY,
            period_id TEXT NOT NULL REFERENCES periods(id) ON DELETE CASCADE,
            date TEXT NOT NULL,
            title TEXT NOT NULL,
            priority TEXT NOT NULL DEFAULT 'important',
            completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_daily_todos_period_date ON daily_todos(period_id, date);
        ",
    )?;
    Ok(())
}
