import { useEffect, useState, useCallback } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useStore } from "@/lib/store";
import type { Period, Entry, Report } from "@/lib/types";

const INDENT = 16;

const reportTypeLabels: Record<string, string> = {
  daily_insight: "每日洞察",
  period_summary: "观察期总结",
  restructure_plan: "重构方案",
};

const statusColors: Record<string, string> = {
  active: "#22c55e",
  paused: "#eab308",
  completed: "#3b82f6",
  archived: "#9ca3af",
};

function Arrow({ open }: { open: boolean }) {
  return (
    <span
      style={{
        display: "inline-block",
        width: 16,
        fontSize: "0.7rem",
        transition: "transform 0.15s",
        transform: open ? "rotate(90deg)" : "rotate(0deg)",
        flexShrink: 0,
      }}
    >
      ▶
    </span>
  );
}

function TreeNode({
  label,
  depth,
  open,
  onToggle,
  active,
  onClick,
  suffix,
  hasChildren,
}: {
  label: string;
  depth: number;
  open?: boolean;
  onToggle?: () => void;
  active?: boolean;
  onClick?: () => void;
  suffix?: React.ReactNode;
  hasChildren?: boolean;
}) {
  return (
    <div
      onClick={(e) => {
        e.stopPropagation();
        if (hasChildren && onToggle) onToggle();
        if (onClick) onClick();
      }}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 4,
        padding: "3px 8px",
        paddingLeft: depth * INDENT + 8,
        cursor: "pointer",
        fontSize: "0.82rem",
        color: active ? "var(--accent)" : "var(--text-secondary)",
        background: active ? "var(--bg-tertiary)" : "transparent",
        whiteSpace: "nowrap",
        overflow: "hidden",
        textOverflow: "ellipsis",
        userSelect: "none",
      }}
    >
      {hasChildren ? <Arrow open={!!open} /> : <span style={{ width: 16, flexShrink: 0 }} />}
      <span style={{ overflow: "hidden", textOverflow: "ellipsis", flex: 1 }}>{label}</span>
      {suffix}
    </div>
  );
}

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const { periods, loadPeriods, sidebarReports, loadSidebarReports, sidebarEntries, loadSidebarEntries } = useStore();

  const [expandedPeriods, setExpandedPeriods] = useState<Record<string, boolean>>({});
  const [periodsOpen, setPeriodsOpen] = useState(true);
  const [reportsOpen, setReportsOpen] = useState(true);
  const [expandedReportTypes, setExpandedReportTypes] = useState<Record<string, boolean>>({});

  useEffect(() => { loadPeriods(); loadSidebarReports(); }, []);

  const togglePeriod = useCallback((id: string) => {
    setExpandedPeriods((prev) => {
      const next = { ...prev, [id]: !prev[id] };
      if (next[id] && !sidebarEntries[id]) loadSidebarEntries(id);
      return next;
    });
  }, [sidebarEntries, loadSidebarEntries]);

  const reportsByType = sidebarReports.reduce<Record<string, Report[]>>((acc, r) => {
    (acc[r.type] ??= []).push(r);
    return acc;
  }, {});

  const isActive = (path: string) => location.pathname === path;

  return (
    <nav style={{ width: 240, borderRight: "1px solid var(--border)", display: "flex", flexDirection: "column", background: "var(--bg-secondary)", overflow: "hidden" }}>
      <div style={{ padding: "0.75rem 1rem", fontWeight: 700, fontSize: "1.1rem" }}>InnerForge</div>
      <div style={{ flex: 1, overflowY: "auto", overflowX: "hidden" }}>
        {/* 观察期 */}
        <TreeNode label="观察期" depth={0} open={periodsOpen} onToggle={() => setPeriodsOpen(!periodsOpen)} hasChildren />
        {periodsOpen && periods.map((p) => (
          <div key={p.id}>
            <TreeNode
              label={p.title}
              depth={1}
              open={!!expandedPeriods[p.id]}
              onToggle={() => togglePeriod(p.id)}
              onClick={() => navigate(`/period/${p.id}`)}
              active={isActive(`/period/${p.id}`)}
              hasChildren
              suffix={<span style={{ width: 8, height: 8, borderRadius: "50%", background: statusColors[p.status] ?? "#9ca3af", flexShrink: 0 }} />}
            />
            {expandedPeriods[p.id] && (sidebarEntries[p.id] ?? []).map((e) => (
              <TreeNode
                key={e.id}
                label={e.date}
                depth={2}
                onClick={() => navigate(`/period/${p.id}/entry/${e.id}`)}
                active={isActive(`/period/${p.id}/entry/${e.id}`)}
              />
            ))}
          </div>
        ))}
        {/* 每日待办 */}
        <TreeNode label="每日待办" depth={0} onClick={() => navigate("/todos")} active={isActive("/todos")} />
        {/* 分析报告 */}
        <TreeNode label="分析报告" depth={0} open={reportsOpen} onToggle={() => setReportsOpen(!reportsOpen)} hasChildren />
        {reportsOpen && Object.entries(reportTypeLabels).map(([type, label]) => {
          const items = reportsByType[type] ?? [];
          if (items.length === 0) return null;
          const typeOpen = !!expandedReportTypes[type];
          return (
            <div key={type}>
              <TreeNode label={label} depth={1} open={typeOpen} onToggle={() => setExpandedReportTypes((p) => ({ ...p, [type]: !p[type] }))} hasChildren />
              {typeOpen && items.map((r) => (
                <TreeNode key={r.id} label={r.title} depth={2} onClick={() => navigate(`/report/${r.id}`)} active={isActive(`/report/${r.id}`)} />
              ))}
            </div>
          );
        })}
      </div>
      {/* 底部设置 */}
      <div style={{ borderTop: "1px solid var(--border)", padding: "0.5rem" }}>
        <div
          onClick={() => navigate("/settings")}
          style={{
            display: "flex", alignItems: "center", gap: "0.5rem", padding: "0.5rem",
            cursor: "pointer", fontSize: "0.85rem", borderRadius: 8,
            color: isActive("/settings") ? "var(--accent)" : "var(--text-secondary)",
            background: isActive("/settings") ? "var(--bg-tertiary)" : "transparent",
          }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
          </svg>
          设置
        </div>
        <div style={{ padding: "0.4rem 0.5rem 0.25rem", fontSize: "0.7rem", color: "var(--text-secondary)", opacity: 0.6 }}>v1.0.0</div>
      </div>
    </nav>
  );
}
