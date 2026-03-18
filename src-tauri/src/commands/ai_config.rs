use crate::db::DbState;
use crate::models::AiConfig;
use tauri::State;
use uuid::Uuid;
use chrono::Local;

#[tauri::command]
pub fn get_ai_configs(db: State<DbState>) -> Result<Vec<AiConfig>, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, name, provider, endpoint, model_id, api_key, is_default, created_at FROM ai_configs ORDER BY created_at DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| {
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
        })
        .map_err(|e| e.to_string())?;
    let mut configs = Vec::new();
    for row in rows {
        configs.push(row.map_err(|e| e.to_string())?);
    }
    Ok(configs)
}

#[tauri::command]
pub fn create_ai_config(
    db: State<DbState>,
    name: String,
    provider: String,
    endpoint: String,
    model_id: String,
    api_key: String,
    is_default: bool,
) -> Result<AiConfig, String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let now = Local::now().to_rfc3339();

    if is_default {
        conn.execute("UPDATE ai_configs SET is_default = 0", [])
            .map_err(|e| e.to_string())?;
    }

    conn.execute(
        "INSERT INTO ai_configs (id, name, provider, endpoint, model_id, api_key, is_default, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
        rusqlite::params![id, name, provider, endpoint, model_id, api_key, is_default as i32, now],
    )
    .map_err(|e| e.to_string())?;

    Ok(AiConfig {
        id,
        name,
        provider,
        endpoint,
        model_id,
        api_key,
        is_default,
        created_at: now,
    })
}

#[tauri::command]
pub fn update_ai_config(
    db: State<DbState>,
    id: String,
    name: String,
    provider: String,
    endpoint: String,
    model_id: String,
    api_key: String,
    is_default: bool,
) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;

    if is_default {
        conn.execute("UPDATE ai_configs SET is_default = 0", [])
            .map_err(|e| e.to_string())?;
    }

    conn.execute(
        "UPDATE ai_configs SET name=?1, provider=?2, endpoint=?3, model_id=?4, api_key=?5, is_default=?6 WHERE id=?7",
        rusqlite::params![name, provider, endpoint, model_id, api_key, is_default as i32, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn delete_ai_config(db: State<DbState>, id: String) -> Result<(), String> {
    let conn = db.0.lock().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM ai_configs WHERE id = ?1", rusqlite::params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub async fn test_ai_connection(
    db: State<'_, DbState>,
    id: String,
) -> Result<bool, String> {
    let config = {
        let conn = db.0.lock().map_err(|e| e.to_string())?;
        let mut stmt = conn
            .prepare("SELECT id, name, provider, endpoint, model_id, api_key, is_default, created_at FROM ai_configs WHERE id = ?1")
            .map_err(|e| e.to_string())?;
        stmt.query_row(rusqlite::params![id], |row| {
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
        })
        .map_err(|e| e.to_string())?
    };

    let client = reqwest::Client::new();
    let result = match config.provider.as_str() {
        "openai" => {
            let endpoint = if config.endpoint.is_empty() {
                "https://api.openai.com/v1".to_string()
            } else {
                config.endpoint.clone()
            };
            client
                .get(format!("{}/models", endpoint))
                .header("Authorization", format!("Bearer {}", config.api_key))
                .send()
                .await
        }
        "anthropic" => {
            let endpoint = if config.endpoint.is_empty() {
                "https://api.anthropic.com".to_string()
            } else {
                config.endpoint.clone()
            };
            client
                .post(format!("{}/v1/messages", endpoint))
                .header("x-api-key", &config.api_key)
                .header("anthropic-version", "2023-06-01")
                .header("content-type", "application/json")
                .body(serde_json::json!({
                    "model": config.model_id,
                    "max_tokens": 1,
                    "messages": [{"role": "user", "content": "hi"}]
                }).to_string())
                .send()
                .await
        }
        _ => {
            let endpoint = config.endpoint.clone();
            client
                .post(format!("{}/v1/chat/completions", endpoint))
                .header("Authorization", format!("Bearer {}", config.api_key))
                .header("content-type", "application/json")
                .body(serde_json::json!({
                    "model": config.model_id,
                    "max_tokens": 1,
                    "messages": [{"role": "user", "content": "hi"}]
                }).to_string())
                .send()
                .await
        }
    };

    match result {
        Ok(resp) => Ok(resp.status().is_success()),
        Err(e) => Err(e.to_string()),
    }
}
