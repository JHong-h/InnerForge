import { useEffect, useState } from "react";
import { useStore } from "@/lib/store";
import * as api from "@/lib/api";
import type { DailyCompletionStat } from "@/lib/types";
import TodoSection from "@/components/TodoSection";

export default function TodoList() {
  const { periods, loadPeriods } = useStore();
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [selectedPeriodId, setSelectedPeriodId] = useState<string | null>(null);
  const [stats, setStats] = useState<DailyCompletionStat[]>([]);

  const activePeriods = periods.filter(p => p.status === "active");

  useEffect(() => {
    loadPeriods();
  }, []);

  useEffect(() => {
    if (!selectedPeriodId && activePeriods.length > 0) {
      setSelectedPeriodId(activePeriods[0].id);
    }
  }, [periods]);

  useEffect(() => {
    if (selectedPeriodId) {
      api.getPeriodCompletionStats(selectedPeriodId).then(setStats);
    }
  }, [selectedPeriodId]);

  return (
    <div style={{ maxWidth: 640, margin: "0 auto", padding: "1rem" }}>
      {/* 顶部控制栏 */}
      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", marginBottom: "1.5rem", flexWrap: "wrap" }}>
        <h2 style={{ fontSize: "1.2rem", fontWeight: 700, margin: 0 }}>每日待办</h2>
        <input
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          style={inputStyle}
        />
        <select
          value={selectedPeriodId ?? ""}
          onChange={e => setSelectedPeriodId(e.target.value)}
          style={inputStyle}
        >
          {activePeriods.length === 0 && <option value="">无活跃观察期</option>}
          {activePeriods.map(p => (
            <option key={p.id} value={p.id}>{p.title}</option>
          ))}
        </select>
      </div>

      {/* Todo 区块 */}
      {selectedPeriodId ? (
        <TodoSection periodId={selectedPeriodId} date={date} />
      ) : (
        <div style={{ color: "var(--text-secondary)", padding: "2rem 0", textAlign: "center" }}>
          请先创建一个观察期
        </div>
      )}

      {/* 历史完成率 */}
      {stats.length > 0 && (
        <div style={{ marginTop: "2rem" }}>
          <h3 style={{ fontSize: "0.95rem", fontWeight: 600, marginBottom: "0.75rem", color: "var(--text-secondary)" }}>历史完成率</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {stats.map(s => (
              <div key={s.date} style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.82rem" }}>
                <span style={{ width: 90, color: "var(--text-secondary)", flexShrink: 0 }}>{s.date}</span>
                <div style={{ flex: 1, height: 8, background: "var(--bg-tertiary)", borderRadius: 4, overflow: "hidden" }}>
                  <div style={{
                    height: "100%",
                    width: `${s.completion_rate * 100}%`,
                    background: s.completion_rate >= 0.8 ? "var(--success)" : s.completion_rate >= 0.5 ? "var(--warning)" : "var(--danger)",
                    borderRadius: 4,
                  }} />
                </div>
                <span style={{ width: 60, textAlign: "right", fontWeight: 500, flexShrink: 0 }}>
                  {Math.round(s.completion_rate * 100)}%
                </span>
                <span style={{ width: 50, textAlign: "right", color: "var(--text-secondary)", fontSize: "0.75rem", flexShrink: 0 }}>
                  {s.completed_count}/{s.total_count}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  padding: "0.35rem 0.6rem",
  fontSize: "0.85rem",
  background: "var(--bg-tertiary)",
  border: "1px solid var(--border)",
  borderRadius: 6,
  color: "var(--text-primary)",
  outline: "none",
};
