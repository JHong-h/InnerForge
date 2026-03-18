const moods = [
  { value: 1, emoji: "😞", label: "很差" },
  { value: 2, emoji: "😔", label: "不好" },
  { value: 3, emoji: "😐", label: "一般" },
  { value: 4, emoji: "🙂", label: "不错" },
  { value: 5, emoji: "😊", label: "很好" },
];

interface Props {
  value: number | null;
  onChange: (v: number | null) => void;
}

export default function MoodPicker({ value, onChange }: Props) {
  return (
    <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
      <span style={{ fontSize: "0.8rem", color: "var(--text-secondary)", marginRight: "0.25rem" }}>心情</span>
      {moods.map((m) => (
        <button
          key={m.value}
          onClick={() => onChange(value === m.value ? null : m.value)}
          title={m.label}
          style={{
            fontSize: "1.3rem",
            background: value === m.value ? "var(--bg-tertiary)" : "transparent",
            border: value === m.value ? "1px solid var(--accent)" : "1px solid transparent",
            borderRadius: 8,
            padding: "0.25rem 0.4rem",
            cursor: "pointer",
            opacity: value === m.value ? 1 : 0.5,
            transition: "all 0.15s",
          }}
        >
          {m.emoji}
        </button>
      ))}
    </div>
  );
}
