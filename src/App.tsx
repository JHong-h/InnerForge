import { useEffect } from "react";
import { BrowserRouter, Routes, Route, useNavigate } from "react-router-dom";
import { save as saveDialog } from "@tauri-apps/plugin-dialog";
import { useStore } from "./lib/store";
import * as api from "./lib/api";
import Layout from "./components/Layout";
import Onboarding from "./components/Onboarding";
import ObservationList from "./pages/ObservationList";
import ObservationDetail from "./pages/ObservationDetail";
import EntryEditor from "./pages/EntryEditor";
import ReportList from "./pages/ReportList";
import ReportDetail from "./pages/ReportDetail";
import Settings from "./pages/Settings";

function GlobalShortcuts() {
  const navigate = useNavigate();
  const periods = useStore((s) => s.periods);

  useEffect(() => {
    const handleKeyDown = async (e: KeyboardEvent) => {
      if (!e.metaKey || !e.shiftKey) return;

      switch (e.key.toUpperCase()) {
        case "N":
          e.preventDefault();
          navigate("/?new=1");
          break;
        case "D": {
          e.preventDefault();
          const activePeriod = periods.find((p) => p.status === "active");
          if (activePeriod) {
            navigate(`/period/${activePeriod.id}?newEntry=1`);
          }
          break;
        }
        case "E": {
          e.preventDefault();
          const path = await saveDialog({ title: "导出数据到文件夹" });
          if (path) {
            await api.exportAll(path);
          }
          break;
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [navigate, periods]);

  return null;
}

export default function App() {
  const onboarded = useStore((s) => s.onboarded);
  const theme = useStore((s) => s.theme);

  // Initialize theme on mount
  useEffect(() => {
    const resolved = theme === "system"
      ? (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
      : theme;
    document.documentElement.setAttribute("data-theme", resolved);

    // Listen for system theme changes
    if (theme === "system") {
      const mq = window.matchMedia("(prefers-color-scheme: dark)");
      const handler = (e: MediaQueryListEvent) => {
        document.documentElement.setAttribute("data-theme", e.matches ? "dark" : "light");
      };
      mq.addEventListener("change", handler);
      return () => mq.removeEventListener("change", handler);
    }
  }, [theme]);

  return (
    <BrowserRouter>
      <GlobalShortcuts />
      <Routes>
        {!onboarded && <Route path="*" element={<Onboarding />} />}
        <Route element={<Layout />}>
          <Route path="/" element={<ObservationList />} />
          <Route path="/period/:id" element={<ObservationDetail />} />
          <Route path="/period/:periodId/entry/:entryId" element={<EntryEditor />} />
          <Route path="/reports" element={<ReportList />} />
          <Route path="/report/:id" element={<ReportDetail />} />
          <Route path="/settings" element={<Settings />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
