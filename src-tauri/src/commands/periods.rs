use crate::db::DbState;
use crate::models::Period;
use tauri::State;
use uuid::Uuid;
use chrono::Local;

#[tauri::command]
pub fn get_periods(db: State<DbState>) -> Result<Vec<Period>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, title, intention, start_date, planned_end_date, actual_end_date, status, created_at FROM periods ORDER BY created_at DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| {
            Ok(Period {
                id: row.get(0)?,
                title: row.get(1)?,
                intention: row.get(2)?,
                start_date: row.get(3)?,
                planned_end_date: row.get(4)?,
                actual_end_date: row.get(5)?,
                status: row.get(6)?,
                created_at: row.get(7)?,
            })
        })
        .map_err(|e| e.to_string())?;
    let mut periods = Vec::new();
    for row in rows {
        periods.push(row.map_err(|e| e.to_string())?);
    }
    Ok(periods)
}

#[tauri::command]
pub fn create_period(
    db: State<DbState>,
    title: String,
    intention: String,
    duration_days: i64,
) -> Result<Period, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Local::now();
    let start_date = now.format("%Y-%m-%d").to_string();
    let planned_end = now
        .checked_add_signed(chrono::Duration::days(duration_days))
        .unwrap_or(now)
        .format("%Y-%m-%d")
        .to_string();
    let created_at = now.to_rfc3339();

    conn.execute(
        "INSERT INTO periods (id, title, intention, start_date, planned_end_date, status, created_at) VALUES (?1, ?2, ?3, ?4, ?5, 'active', ?6)",
        rusqlite::params![id, title, intention, start_date, planned_end, created_at],
    )
    .map_err(|e| e.to_string())?;

    Ok(Period {
        id,
        title,
        intention,
        start_date,
        planned_end_date: planned_end,
        actual_end_date: None,
        status: "active".into(),
        created_at,
    })
}

#[tauri::command]
pub fn update_period_status(
    db: State<DbState>,
    id: String,
    status: String,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let actual_end = if status == "completed" || status == "archived" {
        Some(Local::now().format("%Y-%m-%d").to_string())
    } else {
        None
    };
    conn.execute(
        "UPDATE periods SET status = ?1, actual_end_date = ?2 WHERE id = ?3",
        rusqlite::params![status, actual_end, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn delete_period(db: State<DbState>, id: String) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM periods WHERE id = ?1", rusqlite::params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}
