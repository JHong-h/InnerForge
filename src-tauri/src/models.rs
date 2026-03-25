use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiConfig {
    pub id: String,
    pub name: String,
    pub provider: String,
    pub endpoint: String,
    pub model_id: String,
    pub api_key: String,
    pub is_default: bool,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Period {
    pub id: String,
    pub title: String,
    pub intention: String,
    pub start_date: String,
    pub planned_end_date: String,
    pub actual_end_date: Option<String>,
    pub status: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entry {
    pub id: String,
    pub period_id: String,
    pub date: String,
    pub content: String,
    pub mood: Option<i32>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Attachment {
    pub id: String,
    pub entry_id: String,
    pub relative_path: String,
    pub thumbnail_path: Option<String>,
    pub file_name: String,
    pub file_size: i64,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Report {
    pub id: String,
    #[serde(rename = "type")]
    pub report_type: String,
    pub title: String,
    pub content: String,
    pub skill_id: String,
    pub period_id: Option<String>,
    pub entry_id: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillRecord {
    pub id: String,
    pub skill_id: String,
    pub skill_name: String,
    pub input: String,
    pub output: Option<String>,
    pub status: String,
    pub error_message: Option<String>,
    pub started_at: String,
    pub completed_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyTodo {
    pub id: String,
    pub period_id: String,
    pub date: String,
    pub title: String,
    pub priority: String,
    pub completed: bool,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyCompletionStat {
    pub date: String,
    pub total_count: i64,
    pub completed_count: i64,
    pub total_weight: i64,
    pub completed_weight: i64,
    pub completion_rate: f64,
}
