import { useState, useEffect } from "react";
import { useStore } from "@/lib/store";
import * as api from "@/lib/api";
import type { TodoPriority } from "@/lib/types";

const PRIORITY_CONFIG: Record<TodoPriority, { label: string; color: string; weight: number }> = {
  critical:   { label: "非常重要", color: "var(--danger)",         weight: 4 },
  important:  { label: "重要",     color: "var(--warning)",        weight: 3 },
  secondary:  { label: "次要",     color: "var(--accent)",         weight: 2 },
  deferrable: { label: "可延缓",   color: "var(--text-secondary)", weight: 1 },
};

const PRIORITIES: TodoPriority[] = ["critical", "important", "secondary", "deferrable"];

export default function TodoSection({ periodId, date, compact }: { periodId: string; date: string; compact?: boolean }) {
  const { todos, loadTodos } = useStore();
  const [title, setTitle] = useState("");
  const [priority, setPriority] = useState<TodoPriority>("important");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editPriority, setEditPriority] = useState<TodoPriority>("important");
  const [collapsed, setCollapsed] = useState(false);

  useEffect(() => {
    if (periodId && date) loadTodos(periodId, date);
  }, [periodId, date]);

  const totalWeight = todos.reduce((s, t) => s + PRIORITY_CONFIG[t.priority as TodoPriority].weight, 0);
  const doneWeight = todos.filter(t => t.completed).reduce((s, t) => s + PRIORITY_CONFIG[t.priority as TodoPriority].weight, 0);
  const rate = totalWeight > 0 ? doneWeight / totalWeight : 0;

  const reload = () => loadTodos(periodId, date);

  const handleAdd = async () => {
    const trimmed = title.trim();
    if (!trimmed) return;
    await api.createTodo(periodId, date, trimmed, priority);
    setTitle("");
    reload();
  };

  const handleToggle = async (id: string) => {
    await api.toggleTodo(id);
    reload();
  };

  const handleDelete = async (id: string) => {
    await api.deleteTodo(id);
    reload();
  };

  const handleEditStart = (id: string, currentTitle: string, currentPriority: TodoPriority) => {
    setEditingId(id);
    setEditTitle(currentTitle);
    setEditPriority(currentPriority);
  };

  const handleEditSave = async () => {
    if (!editingId || !editTitle.trim()) return;
    await api.updateTodo(editingId, editTitle.trim(), editPriority);
    setEditingId(null);
    reload();
  };

  const fontSize = compact ? "0.78rem" : "0.85rem";
  const gap = compact ? "0.4rem" : "0.6rem";

  return (
    <div style={{ marginTop: compact ? "0.5rem" : 0 }}>
      {compact && (
        <div
          onClick={() => setCollapsed(!collapsed)}
          style={{ display: "flex", alignItems: "center", gap: 4, cursor: "pointer", fontSize: "0.8rem", color: "var(--text-secondary)", marginBottom: "0.4rem", userSelect: "none" }}
        >
          <span style={{ display: "inline-block", width: 14, fontSize: "0.65rem", transition: "transform 0.15s", transform: collapsed ? "rotate(0deg)" : "rotate(90deg)" }}>▶</span>
          <span>今日待办</span>
          {todos.length > 0 && (
            <span style={{ marginLeft: "auto", fontSize: "0.72rem" }}>
              {Math.round(rate * 100)}%
            </span>
          )}
        </div>
      )}

      {(!compact || !collapsed) && (
        <>
          {/* 完成率进度条 */}
          {todos.length > 0 && (
            <div style={{ marginBottom: gap }}>
              {!compact && (
                <div style={{ display: "flex", justifyContent: "space-between", fontSize, marginBottom: 4 }}>
                  <span style={{ color: "var(--text-secondary)" }}>加权完成率</span>
                  <span style={{ fontWeight: 600 }}>{Math.round(rate * 100)}%</span>
                </div>
              )}
              <div style={{ height: compact ? 3 : 6, background: "var(--bg-tertiary)", borderRadius: 3, overflow: "hidden" }}>
                <div style={{ height: "100%", width: `${rate * 100}%`, background: rate >= 0.8 ? "var(--success)" : rate >= 0.5 ? "var(--warning)" : "var(--danger)", borderRadius: 3, transition: "width 0.3s" }} />
              </div>
            </div>
          )}

          {/* 新建表单 */}
          <div style={{ display: "flex", gap: 4, marginBottom: gap }}>
            <input
              value={title}
              onChange={e => setTitle(e.target.value)}
              onKeyDown={e => e.key === "Enter" && handleAdd()}
              placeholder="添加待办..."
              style={{ flex: 1, padding: compact ? "0.2rem 0.4rem" : "0.3rem 0.6rem", fontSize, background: "var(--bg-tertiary)", border: "1px solid var(--border)", borderRadius: 6, color: "var(--text-primary)", outline: "none" }}
            />
            <select
              value={priority}
              onChange={e => setPriority(e.target.value as TodoPriority)}
              style={{ padding: compact ? "0.2rem" : "0.3rem", fontSize: compact ? "0.72rem" : "0.8rem", background: "var(--bg-tertiary)", border: "1px solid var(--border)", borderRadius: 6, color: "var(--text-primary)", outline: "none" }}
            >
              {PRIORITIES.map(p => (
                <option key={p} value={p}>{PRIORITY_CONFIG[p].label}</option>
              ))}
            </select>
            <button onClick={handleAdd} style={{ padding: compact ? "0.2rem 0.4rem" : "0.3rem 0.6rem", fontSize, background: "var(--accent)", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", whiteSpace: "nowrap" }}>添加</button>
          </div>

          {/* Todo 列表 */}
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {todos.map(todo => (
              <div key={todo.id} style={{ display: "flex", alignItems: "center", gap: 6, padding: compact ? "0.2rem 0" : "0.3rem 0", fontSize }}>
                {editingId === todo.id ? (
                  <>
                    <input
                      value={editTitle}
                      onChange={e => setEditTitle(e.target.value)}
                      onKeyDown={e => e.key === "Enter" && handleEditSave()}
                      style={{ flex: 1, padding: "0.2rem 0.4rem", fontSize, background: "var(--bg-tertiary)", border: "1px solid var(--border)", borderRadius: 4, color: "var(--text-primary)", outline: "none" }}
                      autoFocus
                    />
                    <select
                      value={editPriority}
                      onChange={e => setEditPriority(e.target.value as TodoPriority)}
                      style={{ padding: "0.2rem", fontSize: compact ? "0.7rem" : "0.78rem", background: "var(--bg-tertiary)", border: "1px solid var(--border)", borderRadius: 4, color: "var(--text-primary)" }}
                    >
                      {PRIORITIES.map(p => (
                        <option key={p} value={p}>{PRIORITY_CONFIG[p].label}</option>
                      ))}
                    </select>
                    <button onClick={handleEditSave} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--success)", fontSize }}>✓</button>
                    <button onClick={() => setEditingId(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-secondary)", fontSize }}>✕</button>
                  </>
                ) : (
                  <>
                    <input
                      type="checkbox"
                      checked={todo.completed}
                      onChange={() => handleToggle(todo.id)}
                      style={{ cursor: "pointer", accentColor: "var(--accent)" }}
                    />
                    <span style={{
                      flex: 1,
                      textDecoration: todo.completed ? "line-through" : "none",
                      opacity: todo.completed ? 0.5 : 1,
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}>
                      {todo.title}
                    </span>
                    <span style={{
                      fontSize: compact ? "0.65rem" : "0.72rem",
                      padding: "0.1rem 0.35rem",
                      borderRadius: 4,
                      background: PRIORITY_CONFIG[todo.priority as TodoPriority].color,
                      color: "#fff",
                      whiteSpace: "nowrap",
                      opacity: todo.completed ? 0.5 : 1,
                    }}>
                      {PRIORITY_CONFIG[todo.priority as TodoPriority].label}
                    </span>
                    <button
                      onClick={() => handleEditStart(todo.id, todo.title, todo.priority as TodoPriority)}
                      style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-secondary)", fontSize: compact ? "0.7rem" : "0.78rem", padding: "0 2px" }}
                    >✎</button>
                    <button
                      onClick={() => handleDelete(todo.id)}
                      style={{ background: "none", border: "none", cursor: "pointer", color: "var(--danger)", fontSize: compact ? "0.7rem" : "0.78rem", padding: "0 2px" }}
                    >✕</button>
                  </>
                )}
              </div>
            ))}
            {todos.length === 0 && (
              <div style={{ fontSize, color: "var(--text-secondary)", padding: "0.3rem 0" }}>暂无待办</div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
