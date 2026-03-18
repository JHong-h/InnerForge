import { useState } from "react";
import { useStore } from "../lib/store";
import * as api from "../lib/api";
import { useNavigate } from "react-router-dom";

export default function Onboarding() {
  const [step, setStep] = useState(0);
  const [title, setTitle] = useState("");
  const [intention, setIntention] = useState("");
  const [days, setDays] = useState(30);
  const setOnboarded = useStore((s) => s.setOnboarded);
  const loadPeriods = useStore((s) => s.loadPeriods);
  const navigate = useNavigate();

  const handleCreate = async () => {
    if (!title.trim()) return;
    await api.createPeriod(title.trim(), intention.trim(), days);
    await loadPeriods();
    setOnboarded(true);
    navigate("/");
  };

  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", background: "var(--bg-primary)" }}>
      <div style={{ maxWidth: 480, width: "100%", padding: "2rem" }}>
        {step === 0 && (
          <div>
            <h1 style={{ fontSize: "1.8rem", marginBottom: "0.5rem" }}>欢迎使用 InnerForge</h1>
            <p style={{ color: "var(--text-secondary)", marginBottom: "2rem", lineHeight: 1.7 }}>
              InnerForge 是你的内在观察与成长工具。通过记录日记、追踪情绪、AI 辅助分析，帮助你更好地认识自己。
            </p>
            <button onClick={() => setStep(1)} style={btnStyle}>
              开始使用
            </button>
          </div>
        )}
        {step === 1 && (
          <div>
            <h2 style={{ fontSize: "1.4rem", marginBottom: "1.5rem" }}>创建你的第一个观察期</h2>
            <label style={labelStyle}>标题</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="例如：三月自我观察"
              style={inputStyle}
            />
            <label style={labelStyle}>意图（可选）</label>
            <textarea
              value={intention}
              onChange={(e) => setIntention(e.target.value)}
              placeholder="你希望在这段时间里观察什么？"
              rows={3}
              style={{ ...inputStyle, resize: "vertical" }}
            />
            <label style={labelStyle}>持续天数</label>
            <input
              type="number"
              value={days}
              onChange={(e) => setDays(Number(e.target.value))}
              min={1}
              max={365}
              style={inputStyle}
            />
            <div style={{ display: "flex", gap: "0.75rem", marginTop: "1.5rem" }}>
              <button onClick={() => { setOnboarded(true); navigate("/"); }} style={{ ...btnStyle, background: "var(--bg-tertiary)" }}>
                跳过
              </button>
              <button onClick={handleCreate} style={btnStyle} disabled={!title.trim()}>
                创建观察期
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

const btnStyle: React.CSSProperties = {
  padding: "0.6rem 1.5rem",
  background: "var(--accent)",
  color: "#fff",
  border: "none",
  borderRadius: 8,
  cursor: "pointer",
  fontSize: "0.95rem",
};

const labelStyle: React.CSSProperties = {
  display: "block",
  marginBottom: "0.3rem",
  marginTop: "1rem",
  color: "var(--text-secondary)",
  fontSize: "0.85rem",
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "0.6rem 0.8rem",
  background: "var(--bg-tertiary)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  color: "var(--text-primary)",
  fontSize: "0.95rem",
  outline: "none",
};
