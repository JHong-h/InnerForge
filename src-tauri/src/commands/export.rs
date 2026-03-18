use crate::db::DbState;
use crate::models::Report;
use tauri::{AppHandle, Manager, State};
use std::fs;
use std::io::Write;

#[tauri::command]
pub fn export_report(
    db: State<DbState>,
    id: String,
    path: String,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let report: Report = conn
        .query_row(
            "SELECT id, type, title, content, skill_id, period_id, entry_id, created_at FROM reports WHERE id = ?1",
            rusqlite::params![id],
            |row| {
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
            },
        )
        .map_err(|e| e.to_string())?;

    let md = format!("# {}\n\n{}\n\n---\n生成时间: {}\n", report.title, report.content, report.created_at);
    let mut file = fs::File::create(&path).map_err(|e| e.to_string())?;
    file.write_all(md.as_bytes()).map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn export_all(
    app: AppHandle,
    db: State<DbState>,
    base_path: String,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let base = std::path::Path::new(&base_path);
    fs::create_dir_all(base).map_err(|e| e.to_string())?;

    // Export periods and entries
    let mut stmt = conn
        .prepare("SELECT id, title, intention, start_date, planned_end_date, status FROM periods ORDER BY start_date")
        .map_err(|e| e.to_string())?;
    let periods: Vec<(String, String, String, String, String, String)> = stmt
        .query_map([], |row| {
            Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?, row.get(5)?))
        })
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    for (pid, title, intention, start, end, status) in &periods {
        let period_dir = base.join(format!("{}_{}", start, title));
        fs::create_dir_all(&period_dir).map_err(|e| e.to_string())?;

        // Period info
        let info = format!("# {}\n\n意图: {}\n时间: {} ~ {}\n状态: {}\n", title, intention, start, end, status);
        fs::write(period_dir.join("_info.md"), info).map_err(|e| e.to_string())?;

        // Entries
        let mut estmt = conn
            .prepare("SELECT id, date, content, mood FROM entries WHERE period_id = ?1 ORDER BY date")
            .map_err(|e| e.to_string())?;
        let entries: Vec<(String, String, String, Option<i32>)> = estmt
            .query_map(rusqlite::params![pid], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
            })
            .map_err(|e| e.to_string())?
            .filter_map(|r| r.ok())
            .collect();

        for (eid, date, content, mood) in &entries {
            let mood_str = mood.map(|m| format!(" (心情: {}/5)", m)).unwrap_or_default();
            let entry_md = format!("# {} {}\n\n{}\n", date, mood_str, content);
            fs::write(period_dir.join(format!("{}.md", date)), entry_md).map_err(|e| e.to_string())?;

            // Copy attachments
            let app_data = app.path().app_data_dir().map_err(|e| e.to_string())?;
            let att_src = app_data.join("attachments").join(eid);
            if att_src.exists() {
                let att_dst = period_dir.join(format!("{}_attachments", date));
                fs::create_dir_all(&att_dst).map_err(|e| e.to_string())?;
                if let Ok(dir) = fs::read_dir(&att_src) {
                    for entry in dir.flatten() {
                        let dest = att_dst.join(entry.file_name());
                        fs::copy(entry.path(), dest).ok();
                    }
                }
            }
        }
    }

    // Export reports
    let reports_dir = base.join("reports");
    fs::create_dir_all(&reports_dir).map_err(|e| e.to_string())?;
    let mut rstmt = conn
        .prepare("SELECT title, type, content, created_at FROM reports ORDER BY created_at")
        .map_err(|e| e.to_string())?;
    let reports: Vec<(String, String, String, String)> = rstmt
        .query_map([], |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)))
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    for (i, (title, rtype, content, created)) in reports.iter().enumerate() {
        let fname = format!("{}_{}.md", i + 1, rtype);
        let md = format!("# {}\n\n类型: {}\n时间: {}\n\n{}\n", title, rtype, created, content);
        fs::write(reports_dir.join(fname), md).map_err(|e| e.to_string())?;
    }

    Ok(())
}
