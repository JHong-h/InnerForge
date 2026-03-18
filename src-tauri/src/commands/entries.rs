use crate::db::DbState;
use crate::models::{Entry, Attachment};
use tauri::{AppHandle, Manager, State};
use uuid::Uuid;
use chrono::Local;
use std::fs;

#[tauri::command]
pub fn get_entries(db: State<DbState>, period_id: String) -> Result<Vec<Entry>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, period_id, date, content, mood, created_at, updated_at FROM entries WHERE period_id = ?1 ORDER BY date DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(rusqlite::params![period_id], |row| {
            Ok(Entry {
                id: row.get(0)?,
                period_id: row.get(1)?,
                date: row.get(2)?,
                content: row.get(3)?,
                mood: row.get(4)?,
                created_at: row.get(5)?,
                updated_at: row.get(6)?,
            })
        })
        .map_err(|e| e.to_string())?;
    let mut entries = Vec::new();
    for row in rows {
        entries.push(row.map_err(|e| e.to_string())?);
    }
    Ok(entries)
}

#[tauri::command]
pub fn create_entry(
    db: State<DbState>,
    period_id: String,
    date: String,
) -> Result<Entry, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Local::now().to_rfc3339();

    conn.execute(
        "INSERT INTO entries (id, period_id, date, content, mood, created_at, updated_at) VALUES (?1, ?2, ?3, '', NULL, ?4, ?4)",
        rusqlite::params![id, period_id, date, now],
    )
    .map_err(|e| e.to_string())?;

    Ok(Entry {
        id,
        period_id,
        date,
        content: String::new(),
        mood: None,
        created_at: now.clone(),
        updated_at: now,
    })
}

#[tauri::command]
pub fn update_entry(
    db: State<DbState>,
    id: String,
    content: String,
    mood: Option<i32>,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let now = Local::now().to_rfc3339();
    conn.execute(
        "UPDATE entries SET content = ?1, mood = ?2, updated_at = ?3 WHERE id = ?4",
        rusqlite::params![content, mood, now, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn delete_entry(db: State<DbState>, id: String) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM entries WHERE id = ?1", rusqlite::params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn add_attachment(
    app: AppHandle,
    db: State<DbState>,
    entry_id: String,
    file_path: String,
) -> Result<Attachment, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Local::now().to_rfc3339();

    let source = std::path::Path::new(&file_path);
    let file_name = source
        .file_name()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();
    let file_size = fs::metadata(source).map(|m| m.len() as i64).unwrap_or(0);

    let app_data = app.path().app_data_dir().map_err(|e| e.to_string())?;
    let relative = format!("{}/{}", entry_id, file_name);
    let dest_dir = app_data.join("attachments").join(&entry_id);
    fs::create_dir_all(&dest_dir).map_err(|e| e.to_string())?;
    let dest = dest_dir.join(&file_name);
    fs::copy(source, &dest).map_err(|e| e.to_string())?;

    conn.execute(
        "INSERT INTO attachments (id, entry_id, relative_path, file_name, file_size, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        rusqlite::params![id, entry_id, relative, file_name, file_size, now],
    )
    .map_err(|e| e.to_string())?;

    Ok(Attachment {
        id,
        entry_id,
        relative_path: relative,
        thumbnail_path: None,
        file_name,
        file_size,
        created_at: now,
    })
}
