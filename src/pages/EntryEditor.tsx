import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import * as api from "../lib/api";
import type { Entry } from "../lib/types";
import MoodPicker from "../components/MoodPicker";
import MarkdownPreview from "../components/MarkdownPreview";

export default function EntryEditor() {
  const { periodId, entryId } = useParams();
  const navigate = useNavigate();
  const [entry, setEntry] = useState<Entry | null>(null);
  const [content, setContent] = useState("");
  const [mood, setMood] = useState<number | null>(null);
  const [preview, setPreview] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!periodId || !entryId) return;
    api.getEntries(periodId).then((entries) => {
      const e = entries.find((x) => x.id === entryId);
      if (e) {
        setEntry(e);
        setContent(e.content);
        setMood(e.mood);
      }
    });
  }, [periodId, entryId]);

  const save = async () => {
    if (!entryId) return;
    setSaving(true);
    await api.updateEntry(entryId, content, mood);
    setSaving(false);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 3rem)" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <button onClick={() => navigate(`/period/${periodId}`)} style={{ background: "none", border: "none", color: "var(--text-secondary)", cursor: "pointer" }}>← 返回</button>
          <span style={{ fontWeight: 600 }}>{entry?.date}</span>
          <MoodPicker value={mood} onChange={setMood} />
          {saving && <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>保存中...</span>}
        </div>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button onClick={() => setPreview(!preview)} style={btn}>{preview ? "编辑" : "预览"}</button>
          <button onClick={save} style={btn}>保存</button>
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
          onBlur={save}
          placeholder="写下你的观察和感受..."
          style={{ flex: 1, padding: "1rem", background: "var(--bg-secondary)", border: "1px solid var(--border)", borderRadius: 8, color: "var(--text-primary)", fontSize: "0.95rem", lineHeight: 1.7, resize: "none", outline: "none", fontFamily: "inherit" }}
        />
      )}
    </div>
  );
}

const btn: React.CSSProperties = {
  padding: "0.3rem 0.7rem",
  background: "var(--bg-tertiary)",
  color: "var(--text-primary)",
  border: "1px solid var(--border)",
  borderRadius: 6,
  cursor: "pointer",
  fontSize: "0.8rem",
};
