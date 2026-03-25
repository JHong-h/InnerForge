import { invoke } from "@tauri-apps/api/core";
import type { AiConfig, Period, Entry, Attachment, Report, SkillRecord, DailyTodo, DailyCompletionStat } from "./types";

// AI 配置
export const getAiConfigs = () => invoke<AiConfig[]>("get_ai_configs");
export const createAiConfig = (config: {
  name: string;
  provider: string;
  endpoint: string;
  model_id: string;
  api_key: string;
  is_default: boolean;
}) => invoke<AiConfig>("create_ai_config", config);
export const updateAiConfig = (config: {
  id: string;
  name: string;
  provider: string;
  endpoint: string;
  model_id: string;
  api_key: string;
  is_default: boolean;
}) => invoke<void>("update_ai_config", config);
export const deleteAiConfig = (id: string) => invoke<void>("delete_ai_config", { id });
export const testAiConnection = (id: string) => invoke<boolean>("test_ai_connection", { id });

// 观察期
export const getPeriods = () => invoke<Period[]>("get_periods");
export const createPeriod = (title: string, intention: string, durationDays: number) =>
  invoke<Period>("create_period", { title, intention, durationDays });
export const updatePeriodStatus = (id: string, status: string) =>
  invoke<void>("update_period_status", { id, status });
export const deletePeriod = (id: string) => invoke<void>("delete_period", { id });

// 日记
export const getEntries = (periodId: string) => invoke<Entry[]>("get_entries", { periodId });
export const createEntry = (periodId: string, date: string) =>
  invoke<Entry>("create_entry", { periodId, date });
export const updateEntry = (id: string, content: string, mood: number | null) =>
  invoke<void>("update_entry", { id, content, mood });
export const deleteEntry = (id: string) => invoke<void>("delete_entry", { id });
export const addAttachment = (entryId: string, filePath: string) =>
  invoke<Attachment>("add_attachment", { entryId, filePath });

// AI 分析
export const runDailyInsight = (entryId: string, configId: string) =>
  invoke<Report>("run_daily_insight", { entryId, configId });
export const runPeriodSummary = (periodId: string, configId: string) =>
  invoke<Report>("run_period_summary", { periodId, configId });
export const runRestructurePlan = (periodId: string, configId: string) =>
  invoke<Report>("run_restructure_plan", { periodId, configId });

// 报告
export const getReports = (reportType?: string) =>
  invoke<Report[]>("get_reports", { reportType: reportType ?? null });
export const deleteReport = (id: string) => invoke<void>("delete_report", { id });
export const exportReport = (id: string, path: string) =>
  invoke<void>("export_report", { id, path });
export const exportAll = (basePath: string) => invoke<void>("export_all", { basePath });

// 提醒
export const checkShouldRemind = () => invoke<boolean>("check_should_remind");

// 更新
export const checkForUpdate = () => invoke<{ has_update: boolean; version: string; download_url: string }>("check_for_update");
export const downloadAndInstallUpdate = (downloadUrl: string) => invoke<void>("download_and_install_update", { downloadUrl });

// Skill 记录
export const getSkillRecords = (skillId?: string) =>
  invoke<SkillRecord[]>("get_skill_records", { skillId: skillId ?? null });

// 每日待办
export const createTodo = (periodId: string, date: string, title: string, priority: string) =>
  invoke<DailyTodo>("create_todo", { periodId, date, title, priority });
export const getTodosByDate = (periodId: string, date: string) =>
  invoke<DailyTodo[]>("get_todos_by_date", { periodId, date });
export const updateTodo = (id: string, title: string, priority: string) =>
  invoke<DailyTodo>("update_todo", { id, title, priority });
export const toggleTodo = (id: string) =>
  invoke<DailyTodo>("toggle_todo", { id });
export const deleteTodo = (id: string) =>
  invoke<void>("delete_todo", { id });
export const getPeriodCompletionStats = (periodId: string) =>
  invoke<DailyCompletionStat[]>("get_period_completion_stats", { periodId });
