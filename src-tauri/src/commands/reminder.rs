use crate::db::DbState;
use chrono::Local;
use tauri::State;

#[tauri::command]
pub fn check_should_remind(db: State<DbState>) -> Result<bool, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let today = Local::now().format("%Y-%m-%d").to_string();

    // Check if there are any active observation periods
    let active_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM periods WHERE status = 'active'",
            [],
            |row| row.get(0),
        )
        .map_err(|e| e.to_string())?;

    if active_count == 0 {
        return Ok(false);
    }

    // Check if today already has an entry under any active period
    let entry_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM entries e JOIN periods p ON e.period_id = p.id WHERE p.status = 'active' AND e.date = ?1",
            rusqlite::params![today],
            |row| row.get(0),
        )
        .map_err(|e| e.to_string())?;

    Ok(entry_count == 0)
}
