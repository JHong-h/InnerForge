import { useEffect, useState } from "react";
import { useStore } from "../lib/store";
import type { Theme } from "../lib/store";
import * as api from "../lib/api";
import type { AiConfig } from "../lib/types";
import { save as saveDialog } from "@tauri-apps/plugin-dialog";

const providers = [
  { value: "openai", label: "OpenAI" },
  { value: "anthropic", label: "Anthropic" },
  { value: "custom", label: "自定义 (OpenAI 兼容)" },
];

export default function Settings() {
  const { aiConfigs, loadAiConfigs, theme, setTheme, reminderEnabled, setReminderEnabled, reminderTime, setReminderTime } = useStore();
  const [editing, setEditing] = useState<Partial<AiConfig> | null>(null);
  const [testing, setTesting] = useState<string | null>(null);
  const [testResult, setTestResult] = useState<Record<string, boolean | null>>({});
  const [checking, setChecking] = useState(false);
  const [updateStatus, setUpdateStatus] = useState<string | null>(null);

  useEffect(() => {
    loadAiConfigs();
  }, []);

  const handleSave = async () => {
    if (!editing || !editing.name?.trim() || !editing.model_id?.trim()) return;
    if (editing.id) {
      await api.updateAiConfig({
        id: editing.id,
        name: editing.name,
        provider: editing.provider || "openai",
        endpoint: editing.endpoint || "",
        model_id: editing.model_id,
        api_key: editing.api_key || "",
        is_default: editing.is_default || false,
      });
    } else {
      await api.createAiConfig({
        name: editing.name,
        provider: editing.provider || "openai",
        endpoint: editing.endpoint || "",
        model_id: editing.model_id,
        api_key: editing.api_key || "",
        is_default: editing.is_default || false,
      });
    }
    setEditing(null);
    await loadAiConfigs();
  };

  const handleTest = async (id: string) => {
    setTesting(id);
    setTestResult((prev) => ({ ...prev, [id]: null }));
    try {
      const ok = await api.testAiConnection(id);
      setTestResult((prev) => ({ ...prev, [id]: ok }));
    } catch {
      setTestResult((prev) => ({ ...prev, [id]: false }));
    }
    setTesting(null);
  };

  const handleDelete = async (id: string) => {
    await api.deleteAiConfig(id);
    await loadAiConfigs();
  };

  const newConfig = () => {
    setEditing({ name: "", provider: "openai", endpoint: "", model_id: "", api_key: "", is_default: aiConfigs.length === 0 });
  };

  const handleExportAll = async () => {
    const path = await saveDialog({ title: "选择导出目录" });
    if (path) {
      try {
        await api.exportAll(path);
        alert("导出成功！");
      } catch (e: any) {
        alert("导出失败: " + e);
      }
    }
  };

  const handleCheckUpdate = async () => {
    setChecking(true);
    setUpdateStatus(null);
    // Simulate version check — in production this would fetch from a remote endpoint
    await new Promise((r) => setTimeout(r, 1500));
    const currentVersion = "1.0.0";
    // Placeholder: always reports latest for now
    setUpdateStatus("latest");
    setChecking(false);
  };

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
        <h1 style={{ fontSize: "1.4rem", fontWeight: 600 }}>设置</h1>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button onClick={handleExportAll} style={btnSecondary}>导出全部数据</button>
          <button onClick={newConfig} style={btnPrimary}>+ 添加 AI 模型</button>
        </div>
      </div>

      {/* 外观主题 */}
      <div style={cardStyle}>
        <h3 style={{ fontWeight: 600, marginBottom: "0.75rem" }}>外观</h3>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          {([
            { value: "light", label: "浅色" },
            { value: "dark", label: "深色" },
            { value: "system", label: "跟随系统" },
          ] as { value: Theme; label: string }[]).map((t) => (
            <button
              key={t.value}
              onClick={() => setTheme(t.value)}
              style={{
                padding: "0.4rem 1rem",
                borderRadius: 8,
                border: theme === t.value ? "2px solid var(--accent)" : "1px solid var(--border)",
                background: theme === t.value ? "var(--accent)" + "18" : "var(--bg-tertiary)",
                color: theme === t.value ? "var(--accent)" : "var(--text-primary)",
                cursor: "pointer",
                fontSize: "0.85rem",
                fontWeight: theme === t.value ? 600 : 400,
              }}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* 每日提醒 */}
      <div style={cardStyle}>
        <h3 style={{ fontWeight: 600, marginBottom: "0.75rem" }}>每日提醒</h3>
        <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", marginBottom: "0.5rem" }}>
          <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", cursor: "pointer", fontSize: "0.9rem" }}>
            <input
              type="checkbox"
              checked={reminderEnabled}
              onChange={(e) => setReminderEnabled(e.target.checked)}
              style={{ width: 16, height: 16, accentColor: "var(--accent)" }}
            />
            启用提醒
          </label>
          <input
            type="time"
            value={reminderTime}
            onChange={(e) => setReminderTime(e.target.value)}
            disabled={!reminderEnabled}
            style={{
              ...inputStyle,
              width: "auto",
              marginBottom: 0,
              opacity: reminderEnabled ? 1 : 0.5,
            }}
          />
        </div>
        <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)" }}>
          仅在有活跃观察期且当天未写日记时提醒
        </p>
      </div>

      {editing && (
        <div style={cardStyle}>
          <h3 style={{ fontWeight: 600, marginBottom: "0.75rem" }}>{editing.id ? "编辑模型" : "新建模型"}</h3>
          <label style={labelStyle}>名称</label>
          <input value={editing.name || ""} onChange={(e) => setEditing({ ...editing, name: e.target.value })} placeholder="例如：GPT-4o" style={inputStyle} />

          <label style={labelStyle}>提供商</label>
          <select value={editing.provider || "openai"} onChange={(e) => setEditing({ ...editing, provider: e.target.value as AiConfig["provider"] })} style={inputStyle}>
            {providers.map((p) => <option key={p.value} value={p.value}>{p.label}</option>)}
          </select>

          <label style={labelStyle}>API Endpoint（留空使用默认）</label>
          <input value={editing.endpoint || ""} onChange={(e) => setEditing({ ...editing, endpoint: e.target.value })} placeholder={editing.provider === "anthropic" ? "https://api.anthropic.com" : "https://api.openai.com/v1"} style={inputStyle} />

          <label style={labelStyle}>模型 ID</label>
          <input value={editing.model_id || ""} onChange={(e) => setEditing({ ...editing, model_id: e.target.value })} placeholder="例如：gpt-4o / claude-sonnet-4-5-20250929" style={inputStyle} />

          <label style={labelStyle}>API Key</label>
          <input type="password" value={editing.api_key || ""} onChange={(e) => setEditing({ ...editing, api_key: e.target.value })} placeholder="sk-..." style={inputStyle} />

          <label style={{ ...labelStyle, display: "flex", alignItems: "center", gap: "0.5rem", cursor: "pointer" }}>
            <input type="checkbox" checked={editing.is_default || false} onChange={(e) => setEditing({ ...editing, is_default: e.target.checked })} />
            设为默认模型
          </label>

          <div style={{ display: "flex", gap: "0.5rem", marginTop: "1rem" }}>
            <button onClick={() => setEditing(null)} style={btnSecondary}>取消</button>
            <button onClick={handleSave} style={btnPrimary} disabled={!editing.name?.trim() || !editing.model_id?.trim()}>保存</button>
          </div>
        </div>
      )}

      {aiConfigs.length === 0 && !editing && (
        <p style={{ color: "var(--text-secondary)" }}>还没有配置 AI 模型，点击上方按钮添加。</p>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.5rem", marginTop: editing ? "1rem" : 0 }}>
        {aiConfigs.map((c) => (
          <div key={c.id} style={cardStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <span style={{ fontWeight: 600 }}>{c.name}</span>
                {c.is_default && <span style={{ marginLeft: "0.5rem", fontSize: "0.7rem", padding: "0.1rem 0.4rem", borderRadius: 10, background: "var(--accent)22", color: "var(--accent)" }}>默认</span>}
              </div>
              <div style={{ display: "flex", gap: "0.4rem" }}>
                <button onClick={() => handleTest(c.id)} disabled={testing === c.id} style={btnSmall}>
                  {testing === c.id ? "测试中..." : "测试连接"}
                </button>
                <button onClick={() => setEditing(c)} style={btnSmall}>编辑</button>
                <button onClick={() => handleDelete(c.id)} style={{ ...btnSmall, color: "var(--danger)" }}>删除</button>
              </div>
            </div>
            <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)", marginTop: "0.25rem" }}>
              {c.provider} · {c.model_id}
            </p>
            {testResult[c.id] !== undefined && testResult[c.id] !== null && (
              <p style={{ fontSize: "0.8rem", marginTop: "0.25rem", color: testResult[c.id] ? "var(--success)" : "var(--danger)" }}>
                {testResult[c.id] ? "连接成功" : "连接失败"}
              </p>
            )}
          </div>
        ))}
      </div>

      {/* 版本信息 */}
      <div style={{ ...cardStyle, marginTop: "1.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <h3 style={{ fontWeight: 600, marginBottom: "0.25rem" }}>关于 InnerForge</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)" }}>当前版本：v1.0.0</p>
          </div>
          <button onClick={handleCheckUpdate} disabled={checking} style={btnSecondary}>
            {checking ? "检查中..." : "检查更新"}
          </button>
        </div>
        {updateStatus && (
          <div style={{
            marginTop: "0.75rem",
            padding: "0.6rem 0.8rem",
            borderRadius: 8,
            background: updateStatus === "latest" ? "var(--success)" + "15" : "var(--accent)" + "15",
            border: `1px solid ${updateStatus === "latest" ? "var(--success)" + "40" : "var(--accent)" + "40"}`,
          }}>
            {updateStatus === "latest" ? (
              <p style={{ fontSize: "0.85rem", color: "var(--success)" }}>已是最新版本</p>
            ) : (
              <div>
                <p style={{ fontSize: "0.85rem", color: "var(--accent)", fontWeight: 500 }}>
                  发现新版本 v{updateStatus}
                </p>
                <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)", marginTop: "0.25rem" }}>
                  请前往官方网站下载最新版本以获取新功能和修复。
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

const btnPrimary: React.CSSProperties = { padding: "0.45rem 1rem", background: "var(--accent)", color: "#fff", border: "none", borderRadius: 8, cursor: "pointer", fontSize: "0.85rem" };
const btnSecondary: React.CSSProperties = { padding: "0.45rem 1rem", background: "var(--bg-tertiary)", color: "var(--text-primary)", border: "1px solid var(--border)", borderRadius: 8, cursor: "pointer", fontSize: "0.85rem" };
const btnSmall: React.CSSProperties = { padding: "0.3rem 0.6rem", background: "var(--bg-tertiary)", color: "var(--text-primary)", border: "1px solid var(--border)", borderRadius: 6, cursor: "pointer", fontSize: "0.75rem" };
const cardStyle: React.CSSProperties = { background: "var(--bg-secondary)", border: "1px solid var(--border)", borderRadius: 10, padding: "1rem", marginBottom: "0.5rem" };
const inputStyle: React.CSSProperties = { width: "100%", padding: "0.5rem 0.7rem", background: "var(--bg-tertiary)", border: "1px solid var(--border)", borderRadius: 8, color: "var(--text-primary)", fontSize: "0.9rem", outline: "none", marginBottom: "0.25rem" };
const labelStyle: React.CSSProperties = { display: "block", marginBottom: "0.2rem", marginTop: "0.6rem", color: "var(--text-secondary)", fontSize: "0.8rem" };
