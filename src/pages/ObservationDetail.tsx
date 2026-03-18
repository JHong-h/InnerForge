import { useEffect, useState, useCallback, useRef } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import { useStore } from "../lib/store";
import * as api from "../lib/api";
import type { Period, Entry } from "../lib/types";
import MoodPicker from "../components/MoodPicker";
import MarkdownPreview from "../components/MarkdownPreview";
import { listen } from "@tauri-apps/api/event";
import { open as openDialog } from "@tauri-apps/plugin-dialog";

const moodEmojis: Record<number, string> = { 1: "😞", 2: "😔", 3: "😐", 4: "🙂", 5: "😊" };

export default function ObservationDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const { entries, loadEntries, aiConfigs, loadAiConfigs } = useStore();
  const [period, setPeriod] = useState<Period | null>(null);
  const [selectedEntry, setSelectedEntry] = useState<Entry | null>(null);
  const [content, setContent] = useState("");
  const [mood, setMood] = useState<number | null>(null);
  const [preview, setPreview] = useState(false);
  const [saving, setSaving] = useState(false);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiText, setAiText] = useState("");
  const [showAiResult, setShowAiResult] = useState(false);
  const newEntryHandled = useRef(false);

  useEffect(() => {
    if (!id) return;
    loadEntries(id);
    loadAiConfigs();
    api.getPeriods().then((ps) => {
      const p = ps.find((x) => x.id === id);
      if (p) setPeriod(p);
    });
  }, [id]);

  // Handle ?newEntry=1 from keyboard shortcut
  useEffect(() => {
    if (searchParams.get("newEntry") === "1" && id && !newEntryHandled.current) {
      newEntryHandled.current = true;
      handleNewEntry();
      setSearchParams({}, { replace: true });
    }
  }, [searchParams, id]);

  useEffect(() => {
    if (selectedEntry) {
      setContent(selectedEntry.content);
      setMood(selectedEntry.mood);
    }
  }, [selectedEntry?.id]);

  const saveEntry = useCallback(async () => {
    if (!selectedEntry) return;
    setSaving(true);
    await api.updateEntry(selectedEntry.id, content, mood);
    setSaving(false);
    if (id) await loadEntries(id);
  }, [selectedEntry, content, mood, id]);

  // Auto-save on blur
  const handleBlur = () => { saveEntry(); };

  const handleNewEntry = async () => {
    if (!id) return;
    const today = new Date().toISOString().slice(0, 10);
    const entry = await api.createEntry(id, today);
    await loadEntries(id);
    setSelectedEntry(entry);
  };

  const handleDeleteEntry = async (entryId: string) => {
    await api.deleteEntry(entryId);
    if (id) await loadEntries(id);
    if (selectedEntry?.id === entryId) {
      setSelectedEntry(null);
      setContent("");
      setMood(null);
    }
  };

  const handleAddImage = async () => {
    if (!selectedEntry) return;
    const file = await openDialog({
      multiple: false,
      filters: [{ name: "Images", extensions: ["png", "jpg", "jpeg", "gif", "webp"] }],
    });
    if (file) {
      const att = await api.addAttachment(selectedEntry.id, file);
      setContent((prev) => prev + `\n![${att.file_name}](attachment://${att.relative_path})\n`);
    }
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    if (!selectedEntry) return;
    const files = e.dataTransfer.files;
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      if (file.type.startsWith("image/")) {
        // Tauri drag-drop provides the file path
        const path = (file as any).path || file.name;
        if (path && path !== file.name) {
          const att = await api.addAttachment(selectedEntry.id, path);
          setContent((prev) => prev + `\n![${att.file_name}](attachment://${att.relative_path})\n`);
        }
      }
    }
  };

  const [aiTitle, setAiTitle] = useState("AI 分析");

  const runAi = async (type: "insight" | "summary" | "restructure") => {
    const defaultConfig = aiConfigs.find((c) => c.is_default) || aiConfigs[0];
    if (!defaultConfig) { alert("请先在设置中配置 AI 模型"); return; }

    setAiLoading(true);
    setAiText("");
    setShowAiResult(true);

    const eventMap = { insight: "ai-stream-insight", summary: "ai-stream-summary", restructure: "ai-stream-restructure" };
    const titleMap = { insight: "AI 每日洞察", summary: "观察期总结", restructure: "重构方案" };
    setAiTitle(titleMap[type]);

    const unlisten = await listen<string>(eventMap[type], (event) => {
      if (event.payload === "[DONE]") return;
      setAiText((prev) => prev + event.payload);
    });

    try {
      if (type === "insight" && selectedEntry) {
        await api.runDailyInsight(selectedEntry.id, defaultConfig.id);
      } else if (type === "summary" && id) {
        await api.runPeriodSummary(id, defaultConfig.id);
      } else if (type === "restructure" && id) {
        await api.runRestructurePlan(id, defaultConfig.id);
      }
    } catch (e: any) {
      setAiText((prev) => prev + "\n\n错误: " + e);
    } finally {
      setAiLoading(false);
      unlisten();
    }
  };

  const handleRunInsight = () => runAi("insight");

  return (
    <div style={{ display: "flex", height: "calc(100vh - 3rem)", gap: "1rem" }}>
      {/* Left: Entry list */}
      <div style={{ width: 260, flexShrink: 0, display: "flex", flexDirection: "column", borderRight: "1px solid var(--border)", paddingRight: "1rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
          <div>
            <button onClick={() => navigate("/")} style={{ background: "none", border: "none", color: "var(--text-secondary)", cursor: "pointer", fontSize: "0.85rem" }}>← 返回</button>
            <h2 style={{ fontSize: "1.1rem", fontWeight: 600, marginTop: "0.25rem" }}>{period?.title}</h2>
          </div>
        </div>
        <button onClick={handleNewEntry} style={btnPrimary}>+ 写日记</button>
        <div style={{ display: "flex", gap: "0.4rem", marginTop: "0.5rem" }}>
          <button onClick={() => runAi("summary")} disabled={aiLoading} style={{ ...btnSmall, flex: 1, fontSize: "0.75rem" }}>观察期总结</button>
          <button onClick={() => runAi("restructure")} disabled={aiLoading} style={{ ...btnSmall, flex: 1, fontSize: "0.75rem" }}>重构方案</button>
        </div>
        <div style={{ flex: 1, overflow: "auto", marginTop: "0.75rem" }}>
          {entries.map((e) => (
            <div
              key={e.id}
              onClick={() => setSelectedEntry(e)}
              style={{
                padding: "0.6rem 0.75rem",
                borderRadius: 8,
                cursor: "pointer",
                background: selectedEntry?.id === e.id ? "var(--bg-tertiary)" : "transparent",
                marginBottom: "0.25rem",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: "0.9rem" }}>{e.date}</span>
                <span>{e.mood ? moodEmojis[e.mood] : ""}</span>
              </div>
              <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)", marginTop: "0.15rem", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {e.content.slice(0, 50) || "空白日记"}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Right: Editor */}
      <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
        {selectedEntry ? (
          <>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem", flexShrink: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
                <span style={{ fontWeight: 600 }}>{selectedEntry.date}</span>
                <MoodPicker value={mood} onChange={(v) => { setMood(v); }} />
                {saving && <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>保存中...</span>}
              </div>
              <div style={{ display: "flex", gap: "0.5rem" }}>
                <button onClick={() => setPreview(!preview)} style={btnSmall}>
                  {preview ? "编辑" : "预览"}
                </button>
                <button onClick={handleAddImage} style={btnSmall}>图片</button>
                <button onClick={handleRunInsight} disabled={aiLoading || !content.trim()} style={{ ...btnSmall, background: "var(--accent)", color: "#fff" }}>
                  {aiLoading ? "分析中..." : "AI 洞察"}
                </button>
                <button onClick={saveEntry} style={btnSmall}>保存</button>
                <button onClick={() => handleDeleteEntry(selectedEntry.id)} style={{ ...btnSmall, color: "var(--danger)" }}>删除</button>
              </div>
            </div>
            {preview ? (
              <div style={{ flex: 1, overflow: "auto", padding: "1rem", background: "var(--bg-secondary)", borderRadius: 8 }}>
                <MarkdownPreview content={content} />
              </div>
            ) : (
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                onBlur={handleBlur}
                onDrop={handleDrop}
                onDragOver={(e) => e.preventDefault()}
                placeholder="写下你的观察和感受..."
                style={{
                  flex: 1,
                  padding: "1rem",
                  background: "var(--bg-secondary)",
                  border: "1px solid var(--border)",
                  borderRadius: 8,
                  color: "var(--text-primary)",
                  fontSize: "0.95rem",
                  lineHeight: 1.7,
                  resize: "none",
                  outline: "none",
                  fontFamily: "inherit",
                }}
              />
            )}
          </>
        ) : (
          <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", color: "var(--text-secondary)" }}>
            选择一篇日记或创建新日记
          </div>
        )}
      </div>

      {/* AI Result Modal */}
      {showAiResult && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100 }} onClick={() => !aiLoading && setShowAiResult(false)}>
          <div style={{ background: "var(--bg-secondary)", borderRadius: 12, padding: "1.5rem", maxWidth: 600, width: "90%", maxHeight: "80vh", overflow: "auto" }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontWeight: 600 }}>{aiTitle}</h3>
              {!aiLoading && <button onClick={() => setShowAiResult(false)} style={{ background: "none", border: "none", color: "var(--text-secondary)", cursor: "pointer", fontSize: "1.2rem" }}>✕</button>}
            </div>
            <MarkdownPreview content={aiText || "正在分析..."} />
          </div>
        </div>
      )}
    </div>
  );
}

const btnPrimary: React.CSSProperties = {
  padding: "0.45rem 1rem",
  background: "var(--accent)",
  color: "#fff",
  border: "none",
  borderRadius: 8,
  cursor: "pointer",
  fontSize: "0.85rem",
  width: "100%",
};

const btnSmall: React.CSSProperties = {
  padding: "0.3rem 0.7rem",
  background: "var(--bg-tertiary)",
  color: "var(--text-primary)",
  border: "1px solid var(--border)",
  borderRadius: 6,
  cursor: "pointer",
  fontSize: "0.8rem",
};
