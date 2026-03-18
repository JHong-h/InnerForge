import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useStore } from "../lib/store";

const typeLabels: Record<string, string> = {
  daily_insight: "每日洞察",
  period_summary: "观察期总结",
  restructure_plan: "重构方案",
};

const typeColors: Record<string, string> = {
  daily_insight: "var(--accent)",
  period_summary: "var(--success)",
  restructure_plan: "var(--warning)",
};

export default function ReportList() {
  const { reports, loadReports } = useStore();
  const navigate = useNavigate();
  const [filter, setFilter] = useState<string | undefined>(undefined);

  useEffect(() => {
    loadReports(filter);
  }, [filter]);

  return (
    <div>
      <h1 style={{ fontSize: "1.4rem", fontWeight: 600, marginBottom: "1rem" }}>分析报告</h1>

      <div style={{ display: "flex", gap: "0.5rem", marginBottom: "1.5rem" }}>
        {[
          { value: undefined, label: "全部" },
          { value: "daily_insight", label: "每日洞察" },
          { value: "period_summary", label: "观察期总结" },
          { value: "restructure_plan", label: "重构方案" },
        ].map((f) => (
          <button
            key={f.label}
            onClick={() => setFilter(f.value)}
            style={{
              padding: "0.35rem 0.8rem",
              borderRadius: 6,
              border: "1px solid var(--border)",
              background: filter === f.value ? "var(--accent)" : "var(--bg-tertiary)",
              color: filter === f.value ? "#fff" : "var(--text-primary)",
              cursor: "pointer",
              fontSize: "0.8rem",
            }}
          >
            {f.label}
          </button>
        ))}
      </div>

      {reports.length === 0 && (
        <p style={{ color: "var(--text-secondary)" }}>暂无报告。在日记中使用 AI 洞察功能生成报告。</p>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
        {reports.map((r) => (
          <div
            key={r.id}
            onClick={() => navigate(`/report/${r.id}`)}
            style={{
              background: "var(--bg-secondary)",
              border: "1px solid var(--border)",
              borderRadius: 10,
              padding: "0.85rem 1rem",
              cursor: "pointer",
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
                <span style={{
                  fontSize: "0.7rem",
                  padding: "0.1rem 0.45rem",
                  borderRadius: 10,
                  background: (typeColors[r.type] || "var(--accent)") + "22",
                  color: typeColors[r.type] || "var(--accent)",
                }}>
                  {typeLabels[r.type] || r.type}
                </span>
                <span style={{ fontWeight: 500, fontSize: "0.95rem" }}>{r.title}</span>
              </div>
              <span style={{ fontSize: "0.75rem", color: "var(--text-secondary)" }}>
                {r.created_at.slice(0, 10)}
              </span>
            </div>
            <p style={{ fontSize: "0.8rem", color: "var(--text-secondary)", marginTop: "0.3rem", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
              {r.content.slice(0, 100)}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
