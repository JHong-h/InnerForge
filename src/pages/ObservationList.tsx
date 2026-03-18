import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useStore } from "../lib/store";
import * as api from "../lib/api";

const statusLabels: Record<string, string> = {
  active: "进行中",
  paused: "已暂停",
  completed: "已完成",
  archived: "已归档",
};

const statusColors: Record<string, string> = {
  active: "var(--success)",
  paused: "var(--warning)",
  completed: "var(--accent)",
  archived: "var(--text-secondary)",
};

export default function ObservationList() {
  const { periods, loadPeriods } = useStore();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState("");
  const [intention, setIntention] = useState("");
  const [days, setDays] = useState(30);
  const [menuId, setMenuId] = useState<string | null>(null);

  useEffect(() => {
    loadPeriods();
  }, []);

  // Handle ?new=1 from keyboard shortcut
  useEffect(() => {
    if (searchParams.get("new") === "1") {
      setShowCreate(true);
      setSearchParams({}, { replace: true });
    }
  }, [searchParams]);

  const handleCreate = async () => {
    if (!title.trim()) return;
    await api.createPeriod(title.trim(), intention.trim(), days);
    await loadPeriods();
    setShowCreate(false);
    setTitle("");
    setIntention("");
    setDays(30);
  };

  const handleStatus = async (id: string, status: string) => {
    await api.updatePeriodStatus(id, status);
    await loadPeriods();
    setMenuId(null);
  };

  const handleDelete = async (id: string) => {
    await api.deletePeriod(id);
    await loadPeriods();
    setMenuId(null);
  };

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
        <h1 style={{ fontSize: "1.4rem", fontWeight: 600 }}>观察期</h1>
        <button onClick={() => setShowCreate(!showCreate)} style={btnPrimary}>
          + 新建观察期
        </button>
      </div>

      {showCreate && (
        <div style={cardStyle}>
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="标题" style={inputStyle} />
          <textarea value={intention} onChange={(e) => setIntention(e.target.value)} placeholder="意图（可选）" rows={2} style={{ ...inputStyle, resize: "vertical", marginTop: "0.5rem" }} />
          <div style={{ display: "flex", gap: "0.5rem", alignItems: "center", marginTop: "0.5rem" }}>
            <label style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>天数</label>
            <input type="number" value={days} onChange={(e) => setDays(Number(e.target.value))} min={1} max={365} style={{ ...inputStyle, width: 80 }} />
            <div style={{ flex: 1 }} />
            <button onClick={() => setShowCreate(false)} style={btnSecondary}>取消</button>
            <button onClick={handleCreate} style={btnPrimary} disabled={!title.trim()}>创建</button>
          </div>
        </div>
      )}

      {periods.length === 0 && !showCreate && (
        <p style={{ color: "var(--text-secondary)", marginTop: "2rem" }}>还没有观察期，点击上方按钮创建一个吧。</p>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem" }}>
        {periods.map((p) => (
          <div
            key={p.id}
            style={cardStyle}
            onClick={() => navigate(`/period/${p.id}`)}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <span style={{ fontWeight: 600, fontSize: "1.05rem" }}>{p.title}</span>
                <span style={{
                  marginLeft: "0.75rem",
                  fontSize: "0.75rem",
                  padding: "0.15rem 0.5rem",
                  borderRadius: 12,
                  background: statusColors[p.status] + "22",
                  color: statusColors[p.status],
                }}>
                  {statusLabels[p.status]}
                </span>
              </div>
              <div style={{ position: "relative" }}>
                <button
                  onClick={(e) => { e.stopPropagation(); setMenuId(menuId === p.id ? null : p.id); }}
                  style={{ background: "none", border: "none", color: "var(--text-secondary)", cursor: "pointer", fontSize: "1.2rem", padding: "0.25rem 0.5rem" }}
                >
                  ⋯
                </button>
                {menuId === p.id && (
                  <div style={menuStyle} onClick={(e) => e.stopPropagation()}>
                    {p.status === "active" && <button style={menuItemStyle} onClick={() => handleStatus(p.id, "paused")}>暂停</button>}
                    {p.status === "paused" && <button style={menuItemStyle} onClick={() => handleStatus(p.id, "active")}>恢复</button>}
                    {(p.status === "active" || p.status === "paused") && <button style={menuItemStyle} onClick={() => handleStatus(p.id, "completed")}>结束</button>}
                    {p.status === "completed" && <button style={menuItemStyle} onClick={() => handleStatus(p.id, "archived")}>归档</button>}
                    <button style={{ ...menuItemStyle, color: "var(--danger)" }} onClick={() => handleDelete(p.id)}>删除</button>
                  </div>
                )}
              </div>
            </div>
            {p.intention && <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", marginTop: "0.35rem" }}>{p.intention}</p>}
            <p style={{ color: "var(--text-secondary)", fontSize: "0.8rem", marginTop: "0.25rem" }}>
              {p.start_date} ~ {p.actual_end_date || p.planned_end_date}
            </p>
          </div>
        ))}
      </div>
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
};

const btnSecondary: React.CSSProperties = {
  padding: "0.45rem 1rem",
  background: "var(--bg-tertiary)",
  color: "var(--text-primary)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  cursor: "pointer",
  fontSize: "0.85rem",
};

const cardStyle: React.CSSProperties = {
  background: "var(--bg-secondary)",
  border: "1px solid var(--border)",
  borderRadius: 10,
  padding: "1rem",
  cursor: "pointer",
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "0.5rem 0.7rem",
  background: "var(--bg-tertiary)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  color: "var(--text-primary)",
  fontSize: "0.9rem",
  outline: "none",
};

const menuStyle: React.CSSProperties = {
  position: "absolute",
  right: 0,
  top: "100%",
  background: "var(--bg-tertiary)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  padding: "0.25rem 0",
  zIndex: 10,
  minWidth: 100,
};

const menuItemStyle: React.CSSProperties = {
  display: "block",
  width: "100%",
  padding: "0.4rem 0.8rem",
  background: "none",
  border: "none",
  color: "var(--text-primary)",
  cursor: "pointer",
  fontSize: "0.85rem",
  textAlign: "left",
};
