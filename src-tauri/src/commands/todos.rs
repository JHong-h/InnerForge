use crate::db::DbState;
use crate::models::{DailyTodo, DailyCompletionStat};
use chrono::Utc;
use rusqlite::params;
use tauri::State;
use uuid::Uuid;

#[tauri::command]
pub fn create_todo(
    db: State<'_, DbState>,
    period_id: String,
    date: String,
    title: String,
    priority: String,
) -> Result<DailyTodo, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();
    conn.execute(
        "INSERT INTO daily_todos (id, period_id, date, title, priority, completed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, 0, ?6)",
        params![id, period_id, date, title, priority, now],
    )
    .map_err(|e| format!("Failed to create todo: {}", e))?;
    Ok(DailyTodo {
        id,
        period_id,
        date,
        title,
        priority,
        completed: false,
        created_at: now,
    })
}

#[tauri::command]
pub fn get_todos_by_date(
    db: State<'_, DbState>,
    period_id: String,
    date: String,
) -> Result<Vec<DailyTodo>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, period_id, date, title, priority, completed, created_at FROM daily_todos WHERE period_id = ?1 AND date = ?2 ORDER BY created_at ASC")
        .map_err(|e| e.to_string())?;
    let todos = stmt
        .query_map(params![period_id, date], |row| {
            Ok(DailyTodo {
                id: row.get(0)?,
                period_id: row.get(1)?,
                date: row.get(2)?,
                title: row.get(3)?,
                priority: row.get(4)?,
                completed: row.get::<_, i32>(5)? != 0,
                created_at: row.get(6)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(todos)
}

#[tauri::command]
pub fn update_todo(
    db: State<'_, DbState>,
    id: String,
    title: String,
    priority: String,
) -> Result<DailyTodo, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE daily_todos SET title = ?1, priority = ?2 WHERE id = ?3",
        params![title, priority, id],
    )
    .map_err(|e| format!("Failed to update todo: {}", e))?;
    conn.query_row(
        "SELECT id, period_id, date, title, priority, completed, created_at FROM daily_todos WHERE id = ?1",
        params![id],
        |row| {
            Ok(DailyTodo {
                id: row.get(0)?,
                period_id: row.get(1)?,
                date: row.get(2)?,
                title: row.get(3)?,
                priority: row.get(4)?,
                completed: row.get::<_, i32>(5)? != 0,
                created_at: row.get(6)?,
            })
        },
    )
    .map_err(|e| format!("Failed to get updated todo: {}", e))
}

#[tauri::command]
pub fn toggle_todo(
    db: State<'_, DbState>,
    id: String,
) -> Result<DailyTodo, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE daily_todos SET completed = CASE WHEN completed = 0 THEN 1 ELSE 0 END WHERE id = ?1",
        params![id],
    )
    .map_err(|e| format!("Failed to toggle todo: {}", e))?;
    conn.query_row(
        "SELECT id, period_id, date, title, priority, completed, created_at FROM daily_todos WHERE id = ?1",
        params![id],
        |row| {
            Ok(DailyTodo {
                id: row.get(0)?,
                period_id: row.get(1)?,
                date: row.get(2)?,
                title: row.get(3)?,
                priority: row.get(4)?,
                completed: row.get::<_, i32>(5)? != 0,
                created_at: row.get(6)?,
            })
        },
    )
    .map_err(|e| format!("Failed to get toggled todo: {}", e))
}

#[tauri::command]
pub fn delete_todo(
    db: State<'_, DbState>,
    id: String,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM daily_todos WHERE id = ?1", params![id])
        .map_err(|e| format!("Failed to delete todo: {}", e))?;
    Ok(())
}

#[tauri::command]
pub fn get_period_completion_stats(
    db: State<'_, DbState>,
    period_id: String,
) -> Result<Vec<DailyCompletionStat>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    query_completion_stats(&conn, &period_id)
}

pub fn query_completion_stats(
    conn: &rusqlite::Connection,
    period_id: &str,
) -> Result<Vec<DailyCompletionStat>, String> {
    let mut stmt = conn
        .prepare(
            "SELECT date,
                COUNT(*) as total_count,
                SUM(CASE WHEN completed=1 THEN 1 ELSE 0 END) as completed_count,
                SUM(CASE priority WHEN 'critical' THEN 4 WHEN 'important' THEN 3 WHEN 'secondary' THEN 2 WHEN 'deferrable' THEN 1 ELSE 1 END) as total_weight,
                SUM(CASE WHEN completed=1 THEN CASE priority WHEN 'critical' THEN 4 WHEN 'important' THEN 3 WHEN 'secondary' THEN 2 WHEN 'deferrable' THEN 1 ELSE 1 END ELSE 0 END) as completed_weight
            FROM daily_todos WHERE period_id=?1
            GROUP BY date ORDER BY date ASC",
        )
        .map_err(|e| e.to_string())?;
    let stats = stmt
        .query_map(params![period_id], |row| {
            let total_weight: i64 = row.get(3)?;
            let completed_weight: i64 = row.get(4)?;
            let completion_rate = if total_weight > 0 {
                completed_weight as f64 / total_weight as f64
            } else {
                0.0
            };
            Ok(DailyCompletionStat {
                date: row.get(0)?,
                total_count: row.get(1)?,
                completed_count: row.get(2)?,
                total_weight,
                completed_weight,
                completion_rate,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(stats)
}
