use crate::db::DbState;
use crate::models::{AiConfig, Entry, Period, Report, SkillRecord};
use crate::commands::todos::query_completion_stats;
use chrono::Utc;
use futures::StreamExt;
use reqwest::Client;
use rusqlite::params;
use serde_json::{json, Value};
use tauri::{AppHandle, Emitter, State};
use uuid::Uuid;

fn get_config_by_id(db: &State<DbState>, id: &str) -> Result<AiConfig, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.query_row(
        "SELECT id, name, provider, endpoint, model_id, api_key, is_default, created_at FROM ai_configs WHERE id = ?1",
        params![id],
        |row| {
            Ok(AiConfig {
                id: row.get(0)?,
                name: row.get(1)?,
                provider: row.get(2)?,
                endpoint: row.get(3)?,
                model_id: row.get(4)?,
                api_key: row.get(5)?,
                is_default: row.get::<_, i32>(6)? != 0,
                created_at: row.get(7)?,
            })
        },
    )
    .map_err(|e| format!("Failed to get AI config: {}", e))
}

async fn call_ai(
    app: &AppHandle,
    config: &AiConfig,
    prompt: &str,
    event_name: &str,
) -> Result<String, String> {
    let client = Client::new();

    let (_url, request) = match config.provider.as_str() {
        "openai" | "custom" => {
            let base = if config.provider == "custom" && !config.endpoint.is_empty() {
                config.endpoint.trim_end_matches('/').to_string()
            } else if config.provider == "openai" && config.endpoint.is_empty() {
                "https://api.openai.com/v1".to_string()
            } else {
                config.endpoint.trim_end_matches('/').to_string()
            };
            let url = format!("{}/chat/completions", base);
            let body = json!({
                "model": config.model_id,
                "stream": true,
                "messages": [{"role": "user", "content": prompt}]
            });
            let req = client
                .post(&url)
                .header("Authorization", format!("Bearer {}", config.api_key))
                .header("Content-Type", "application/json")
                .json(&body);
            (url, req)
        }
        "anthropic" => {
            let base = if config.endpoint.is_empty() {
                "https://api.anthropic.com".to_string()
            } else {
                config.endpoint.trim_end_matches('/').to_string()
            };
            let url = format!("{}/v1/messages", base);
            let body = json!({
                "model": config.model_id,
                "stream": true,
                "max_tokens": 4096,
                "messages": [{"role": "user", "content": prompt}]
            });
            let req = client
                .post(&url)
                .header("x-api-key", &config.api_key)
                .header("anthropic-version", "2023-06-01")
                .header("Content-Type", "application/json")
                .json(&body);
            (url, req)
        }
        _ => return Err(format!("Unsupported provider: {}", config.provider)),
    };

    let response = request.send().await.map_err(|e| format!("Request failed: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().await.unwrap_or_default();
        return Err(format!("API error ({}): {}", status, body));
    }

    let mut stream = response.bytes_stream();
    let mut full_text = String::new();
    let mut buffer = String::new();

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| format!("Stream error: {}", e))?;
        buffer.push_str(&String::from_utf8_lossy(&chunk));

        while let Some(line_end) = buffer.find('\n') {
            let line = buffer[..line_end].trim().to_string();
            buffer = buffer[line_end + 1..].to_string();

            if !line.starts_with("data: ") {
                continue;
            }
            let data = &line[6..];
            if data == "[DONE]" {
                continue;
            }

            if let Ok(parsed) = serde_json::from_str::<Value>(data) {
                let text = match config.provider.as_str() {
                    "openai" | "custom" => parsed["choices"][0]["delta"]["content"]
                        .as_str()
                        .unwrap_or("")
                        .to_string(),
                    "anthropic" => {
                        let event_type = parsed["type"].as_str().unwrap_or("");
                        if event_type == "content_block_delta" {
                            parsed["delta"]["text"]
                                .as_str()
                                .unwrap_or("")
                                .to_string()
                        } else {
                            String::new()
                        }
                    }
                    _ => String::new(),
                };
                if !text.is_empty() {
                    let _ = app.emit(event_name, &text);
                    full_text.push_str(&text);
                }
            }
        }
    }

    let _ = app.emit(event_name, "[DONE]");
    Ok(full_text)
}

fn save_report(
    db: &State<DbState>,
    report_type: &str,
    title: &str,
    content: &str,
    skill_id: &str,
    period_id: Option<String>,
    entry_id: Option<String>,
) -> Result<Report, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();
    conn.execute(
        "INSERT INTO reports (id, type, title, content, skill_id, period_id, entry_id, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
        params![id, report_type, title, content, skill_id, period_id, entry_id, now],
    )
    .map_err(|e| format!("Failed to save report: {}", e))?;
    Ok(Report {
        id,
        report_type: report_type.to_string(),
        title: title.to_string(),
        content: content.to_string(),
        skill_id: skill_id.to_string(),
        period_id,
        entry_id,
        created_at: now,
    })
}

fn save_skill_record(
    db: &State<DbState>,
    skill_id: &str,
    skill_name: &str,
    input: &str,
    output: Option<&str>,
    status: &str,
    error_message: Option<&str>,
) -> Result<SkillRecord, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();
    let completed_at = if status == "completed" || status == "failed" {
        Some(now.clone())
    } else {
        None
    };
    conn.execute(
        "INSERT INTO skill_records (id, skill_id, skill_name, input, output, status, error_message, started_at, completed_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
        params![id, skill_id, skill_name, input, output, status, error_message, now, completed_at],
    )
    .map_err(|e| format!("Failed to save skill record: {}", e))?;
    Ok(SkillRecord {
        id,
        skill_id: skill_id.to_string(),
        skill_name: skill_name.to_string(),
        input: input.to_string(),
        output: output.map(|s| s.to_string()),
        status: status.to_string(),
        error_message: error_message.map(|s| s.to_string()),
        started_at: now,
        completed_at,
    })
}

#[tauri::command]
pub async fn run_daily_insight(
    app: AppHandle,
    db: State<'_, DbState>,
    entry_id: String,
    config_id: String,
) -> Result<Report, String> {
    let config = get_config_by_id(&db, &config_id)?;
    let (content, date, period_id) = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        let (content, date, pid): (String, String, String) = conn
            .query_row(
                "SELECT content, date, period_id FROM entries WHERE id = ?1",
                params![entry_id],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
            )
            .map_err(|e| format!("Failed to get entry: {}", e))?;
        (content, date, pid)
    };

    let prompt = format!(
        "## 每日洞察\n\n请基于以下日记内容，提供深入的心理洞察和建议...\n\n### 日记内容\n{}\n\n### 日期\n{}\n\n请从以下角度分析：\n1. 情绪状态识别\n2. 思维模式分析\n3. 行为模式观察\n4. 积极面肯定\n5. 温和的改善建议",
        content, date
    );

    let skill_id = "daily_insight";
    let result = call_ai(&app, &config, &prompt, "ai-stream-insight").await;

    match result {
        Ok(response_text) => {
            let title = format!("每日洞察 - {}", date);
            save_skill_record(&db, skill_id, "每日洞察", &prompt, Some(&response_text), "completed", None)?;
            save_report(&db, "daily_insight", &title, &response_text, skill_id, Some(period_id), Some(entry_id))
        }
        Err(e) => {
            save_skill_record(&db, skill_id, "每日洞察", &prompt, None, "failed", Some(&e))?;
            Err(e)
        }
    }
}

#[tauri::command]
pub async fn run_period_summary(
    app: AppHandle,
    db: State<'_, DbState>,
    period_id: String,
    config_id: String,
) -> Result<Report, String> {
    let config = get_config_by_id(&db, &config_id)?;
    let (period, entries) = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        let period: Period = conn
            .query_row(
                "SELECT id, title, intention, start_date, planned_end_date, actual_end_date, status, created_at FROM periods WHERE id = ?1",
                params![period_id],
                |row| {
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
                },
            )
            .map_err(|e| format!("Failed to get period: {}", e))?;
        let mut stmt = conn
            .prepare("SELECT id, period_id, date, content, mood, created_at, updated_at FROM entries WHERE period_id = ?1 ORDER BY date ASC")
            .map_err(|e| e.to_string())?;
        let entries: Vec<Entry> = stmt
            .query_map(params![period_id], |row| {
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
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        (period, entries)
    };

    let entries_text: String = entries
        .iter()
        .map(|e| {
            let mood_str = e.mood.map(|m| format!(" (情绪: {}/10)", m)).unwrap_or_default();
            format!("#### {}{}\n{}\n", e.date, mood_str, e.content)
        })
        .collect::<Vec<_>>()
        .join("\n");

    let end_date = period.actual_end_date.as_deref().unwrap_or(&period.planned_end_date);

    let todo_section = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        build_todo_stats_section(&conn, &period_id)?
    };

    let prompt = format!(
        "## 观察期总结\n\n请基于以下观察期的所有日记，生成一份综合总结报告...\n\n### 观察期：{}\n### 意图：{}\n### 时间范围：{} ~ {}\n\n### 日记记录\n{}\n{}\n请从以下角度总结：\n1. 整体情绪趋势\n2. 关键主题和模式\n3. 成长与变化\n4. 核心洞察\n5. 未来建议\n6. 待办执行力与自律趋势",
        period.title, period.intention, period.start_date, end_date, entries_text, todo_section
    );

    let skill_id = "period_summary";
    let result = call_ai(&app, &config, &prompt, "ai-stream-summary").await;

    match result {
        Ok(response_text) => {
            let title = format!("观察期总结 - {}", period.title);
            save_skill_record(&db, skill_id, "观察期总结", &prompt, Some(&response_text), "completed", None)?;
            save_report(&db, "period_summary", &title, &response_text, skill_id, Some(period_id), None)
        }
        Err(e) => {
            save_skill_record(&db, skill_id, "观察期总结", &prompt, None, "failed", Some(&e))?;
            Err(e)
        }
    }
}

#[tauri::command]
pub async fn run_restructure_plan(
    app: AppHandle,
    db: State<'_, DbState>,
    period_id: String,
    config_id: String,
) -> Result<Report, String> {
    let config = get_config_by_id(&db, &config_id)?;
    let (period, entries) = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        let period: Period = conn
            .query_row(
                "SELECT id, title, intention, start_date, planned_end_date, actual_end_date, status, created_at FROM periods WHERE id = ?1",
                params![period_id],
                |row| {
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
                },
            )
            .map_err(|e| format!("Failed to get period: {}", e))?;
        let mut stmt = conn
            .prepare("SELECT id, period_id, date, content, mood, created_at, updated_at FROM entries WHERE period_id = ?1 ORDER BY date ASC")
            .map_err(|e| e.to_string())?;
        let entries: Vec<Entry> = stmt
            .query_map(params![period_id], |row| {
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
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        (period, entries)
    };

    let entries_summary: String = entries
        .iter()
        .map(|e| {
            let mood_str = e.mood.map(|m| format!(" (情绪: {}/10)", m)).unwrap_or_default();
            format!("- {}{}: {}", e.date, mood_str, e.content)
        })
        .collect::<Vec<_>>()
        .join("\n");

    let todo_section = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        build_todo_stats_section(&conn, &period_id)?
    };

    let prompt = format!(
        "## 重构方案\n\n基于观察期的记录和分析，请制定一个具体的自我重构方案...\n\n### 观察期：{}\n### 意图：{}\n\n### 日记摘要\n{}\n{}\n请制定：\n1. 核心目标（3-5个）\n2. 具体行动计划\n3. 每日习惯建议\n4. 里程碑设定\n5. 潜在障碍及应对策略\n6. 自我评估指标\n7. 基于待办完成情况的执行力评估与改善建议",
        period.title, period.intention, entries_summary, todo_section
    );

    let skill_id = "restructure_plan";
    let result = call_ai(&app, &config, &prompt, "ai-stream-restructure").await;

    match result {
        Ok(response_text) => {
            let title = format!("重构方案 - {}", period.title);
            save_skill_record(&db, skill_id, "重构方案", &prompt, Some(&response_text), "completed", None)?;
            save_report(&db, "restructure_plan", &title, &response_text, skill_id, Some(period_id), None)
        }
        Err(e) => {
            save_skill_record(&db, skill_id, "重构方案", &prompt, None, "failed", Some(&e))?;
            Err(e)
        }
    }
}

fn build_todo_stats_section(conn: &rusqlite::Connection, period_id: &str) -> Result<String, String> {
    let stats = query_completion_stats(conn, period_id)?;
    if stats.is_empty() {
        return Ok(String::new());
    }

    let total_w: i64 = stats.iter().map(|s| s.total_weight).sum();
    let done_w: i64 = stats.iter().map(|s| s.completed_weight).sum();
    let overall = if total_w > 0 { done_w as f64 / total_w as f64 } else { 0.0 };

    let mut section = String::from("\n### 每日待办完成情况\n");
    section.push_str(&format!("整体加权完成率：{:.1}%\n", overall * 100.0));
    for s in &stats {
        section.push_str(&format!(
            "- {}：{:.1}%（完成权重 {}/总权重 {}，完成 {}/{} 项）\n",
            s.date,
            s.completion_rate * 100.0,
            s.completed_weight,
            s.total_weight,
            s.completed_count,
            s.total_count
        ));
    }
    section.push('\n');
    Ok(section)
}
