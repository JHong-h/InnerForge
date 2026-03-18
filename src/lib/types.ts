export interface AiConfig {
  id: string;
  name: string;
  provider: "openai" | "anthropic" | "custom";
  endpoint: string;
  model_id: string;
  api_key: string;
  is_default: boolean;
  created_at: string;
}

export interface Period {
  id: string;
  title: string;
  intention: string;
  start_date: string;
  planned_end_date: string;
  actual_end_date: string | null;
  status: "active" | "paused" | "completed" | "archived";
  created_at: string;
}

export interface Entry {
  id: string;
  period_id: string;
  date: string;
  content: string;
  mood: number | null;
  created_at: string;
  updated_at: string;
}

export interface Attachment {
  id: string;
  entry_id: string;
  relative_path: string;
  thumbnail_path: string | null;
  file_name: string;
  file_size: number;
  created_at: string;
}

export interface Report {
  id: string;
  type: string;
  title: string;
  content: string;
  skill_id: string;
  period_id: string | null;
  entry_id: string | null;
  created_at: string;
}

export interface SkillRecord {
  id: string;
  skill_id: string;
  skill_name: string;
  input: string;
  output: string | null;
  status: "pending" | "running" | "completed" | "failed";
  error_message: string | null;
  started_at: string;
  completed_at: string | null;
}
