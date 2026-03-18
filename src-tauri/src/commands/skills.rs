use crate::db::DbState;
use crate::models::SkillRecord;
use tauri::State;

#[tauri::command]
pub fn get_skill_records(db: State<DbState>, skill_id: Option<String>) -> Result<Vec<SkillRecord>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut records = Vec::new();

    if let Some(sid) = skill_id {
        let mut stmt = conn
            .prepare("SELECT id, skill_id, skill_name, input, output, status, error_message, started_at, completed_at FROM skill_records WHERE skill_id = ?1 ORDER BY started_at DESC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map(rusqlite::params![sid], |row| {
                Ok(SkillRecord {
                    id: row.get(0)?,
                    skill_id: row.get(1)?,
                    skill_name: row.get(2)?,
                    input: row.get(3)?,
                    output: row.get(4)?,
                    status: row.get(5)?,
                    error_message: row.get(6)?,
                    started_at: row.get(7)?,
                    completed_at: row.get(8)?,
                })
            })
            .map_err(|e| e.to_string())?;
        for row in rows {
            records.push(row.map_err(|e| e.to_string())?);
        }
    } else {
        let mut stmt = conn
            .prepare("SELECT id, skill_id, skill_name, input, output, status, error_message, started_at, completed_at FROM skill_records ORDER BY started_at DESC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map([], |row| {
                Ok(SkillRecord {
                    id: row.get(0)?,
                    skill_id: row.get(1)?,
                    skill_name: row.get(2)?,
                    input: row.get(3)?,
                    output: row.get(4)?,
                    status: row.get(5)?,
                    error_message: row.get(6)?,
                    started_at: row.get(7)?,
                    completed_at: row.get(8)?,
                })
            })
            .map_err(|e| e.to_string())?;
        for row in rows {
            records.push(row.map_err(|e| e.to_string())?);
        }
    }

    Ok(records)
}
