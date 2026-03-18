use crate::db::DbState;
use crate::models::Report;
use tauri::State;

#[tauri::command]
pub fn get_reports(db: State<DbState>, report_type: Option<String>) -> Result<Vec<Report>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut reports = Vec::new();

    if let Some(rt) = report_type {
        let mut stmt = conn
            .prepare("SELECT id, type, title, content, skill_id, period_id, entry_id, created_at FROM reports WHERE type = ?1 ORDER BY created_at DESC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map(rusqlite::params![rt], |row| {
                Ok(Report {
                    id: row.get(0)?,
                    report_type: row.get(1)?,
                    title: row.get(2)?,
                    content: row.get(3)?,
                    skill_id: row.get(4)?,
                    period_id: row.get(5)?,
                    entry_id: row.get(6)?,
                    created_at: row.get(7)?,
                })
            })
            .map_err(|e| e.to_string())?;
        for row in rows {
            reports.push(row.map_err(|e| e.to_string())?);
        }
    } else {
        let mut stmt = conn
            .prepare("SELECT id, type, title, content, skill_id, period_id, entry_id, created_at FROM reports ORDER BY created_at DESC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map([], |row| {
                Ok(Report {
                    id: row.get(0)?,
                    report_type: row.get(1)?,
                    title: row.get(2)?,
                    content: row.get(3)?,
                    skill_id: row.get(4)?,
                    period_id: row.get(5)?,
                    entry_id: row.get(6)?,
                    created_at: row.get(7)?,
                })
            })
            .map_err(|e| e.to_string())?;
        for row in rows {
            reports.push(row.map_err(|e| e.to_string())?);
        }
    }

    Ok(reports)
}

#[tauri::command]
pub fn delete_report(db: State<DbState>, id: String) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM reports WHERE id = ?1", rusqlite::params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}
