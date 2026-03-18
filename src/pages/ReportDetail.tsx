import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useStore } from "../lib/store";
import * as api from "../lib/api";
import type { Report } from "../lib/types";
import MarkdownPreview from "../components/MarkdownPreview";
import { save as saveDialog } from "@tauri-apps/plugin-dialog";

const typeLabels: Record<string, string> = {
  daily_insight: "每日洞察",
  period_summary: "观察期总结",
  restructure_plan: "重构方案",
};

export default function ReportDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { reports, loadReports } = useStore();
  const [report, setReport] = useState<Report | null>(null);

  useEffect(() => {
    loadReports().then(() => {});
  }, []);

  useEffect(() => {
    if (id && reports.length > 0) {
      const r = reports.find((x) => x.id === id);
      if (r) setReport(r);
    }
  }, [id, reports]);

  const handleExport = async () => {
    if (!report) return;
    const path = await saveDialog({
      defaultPath: `${report.title}.md`,
      filters: [{ name: "Markdown", extensions: ["md"] }],
    });
    if (path) {
      await api.exportReport(report.id, path);
    }
  };

  const handleDelete = async () => {
    if (!report) return;
    await api.deleteReport(report.id);
    navigate("/reports");
  };

  if (!report) {
    return <div style={{ color: "var(--text-secondary)" }}>加载中...</div>;
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 3rem)" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem", flexShrink: 0 }}>
        <div>
          <button onClick={() => navigate("/reports")} style={{ background: "none", border: "none", color: "var(--text-secondary)", cursor: "pointer", fontSize: "0.85rem" }}>← 返回报告列表</button>
          <h2 style={{ fontSize: "1.2rem", fontWeight: 600, marginTop: "0.25rem" }}>{report.title}</h2>
          <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.25rem", alignItems: "center" }}>
            <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>
              {typeLabels[report.type] || report.type}
            </span>
            <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>
              {report.created_at.slice(0, 10)}
            </span>
          </div>
        </div>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button onClick={handleExport} style={btn}>导出</button>
          <button onClick={handleDelete} style={{ ...btn, color: "var(--danger)" }}>删除</button>
        </div>
      </div>
      <div style={{ flex: 1, overflow: "auto", padding: "1.5rem", background: "var(--bg-secondary)", borderRadius: 8 }}>
        <MarkdownPreview content={report.content} />
      </div>
    </div>
  );
}

const btn: React.CSSProperties = {
  padding: "0.35rem 0.8rem",
  background: "var(--bg-tertiary)",
  color: "var(--text-primary)",
  border: "1px solid var(--border)",
  borderRadius: 6,
  cursor: "pointer",
  fontSize: "0.8rem",
};
