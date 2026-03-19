import { create } from "zustand";
import type { Period, Entry, Report, AiConfig } from "./types";
import * as api from "./api";

export type Theme = "light" | "dark" | "system";

interface AppState {
  // 数据
  periods: Period[];
  entries: Entry[];
  reports: Report[];
  aiConfigs: AiConfig[];

  // 侧边栏数据
  sidebarReports: Report[];
  sidebarEntries: Record<string, Entry[]>;

  // UI 状态
  activePeriodId: string | null;
  activeEntryId: string | null;
  aiStreaming: boolean;
  aiStreamText: string;
  onboarded: boolean;
  theme: Theme;
  reminderEnabled: boolean;
  reminderTime: string;

  // Actions
  loadPeriods: () => Promise<void>;
  loadEntries: (periodId: string) => Promise<void>;
  loadReports: (type?: string) => Promise<void>;
  loadAiConfigs: () => Promise<void>;
  loadSidebarReports: () => Promise<void>;
  loadSidebarEntries: (periodId: string) => Promise<void>;
  setActivePeriod: (id: string | null) => void;
  setActiveEntry: (id: string | null) => void;
  setAiStreaming: (streaming: boolean) => void;
  appendAiStreamText: (text: string) => void;
  resetAiStreamText: () => void;
  setOnboarded: (v: boolean) => void;
  setTheme: (theme: Theme) => void;
  setReminderEnabled: (v: boolean) => void;
  setReminderTime: (time: string) => void;
}

export const useStore = create<AppState>((set, get) => ({
  periods: [],
  entries: [],
  reports: [],
  aiConfigs: [],
  sidebarReports: [],
  sidebarEntries: {},
  activePeriodId: null,
  activeEntryId: null,
  aiStreaming: false,
  aiStreamText: "",
  onboarded: localStorage.getItem("onboarded") === "true",
  theme: (localStorage.getItem("theme") as Theme) || "system",
  reminderEnabled: localStorage.getItem("reminderEnabled") === "true",
  reminderTime: localStorage.getItem("reminderTime") || "21:00",

  loadPeriods: async () => {
    const periods = await api.getPeriods();
    set({ periods });
  },
  loadEntries: async (periodId: string) => {
    const entries = await api.getEntries(periodId);
    set({ entries });
  },
  loadReports: async (type?: string) => {
    const reports = await api.getReports(type);
    set({ reports });
  },
  loadAiConfigs: async () => {
    const aiConfigs = await api.getAiConfigs();
    set({ aiConfigs });
  },
  loadSidebarReports: async () => {
    const sidebarReports = await api.getReports();
    set({ sidebarReports });
  },
  loadSidebarEntries: async (periodId: string) => {
    const entries = await api.getEntries(periodId);
    set((s) => ({ sidebarEntries: { ...s.sidebarEntries, [periodId]: entries } }));
  },
  setActivePeriod: (id) => set({ activePeriodId: id }),
  setActiveEntry: (id) => set({ activeEntryId: id }),
  setAiStreaming: (streaming) => set({ aiStreaming: streaming }),
  appendAiStreamText: (text) =>
    set((s) => ({ aiStreamText: s.aiStreamText + text })),
  resetAiStreamText: () => set({ aiStreamText: "" }),
  setOnboarded: (v) => {
    localStorage.setItem("onboarded", String(v));
    set({ onboarded: v });
  },
  setTheme: (theme) => {
    localStorage.setItem("theme", theme);
    const resolved = theme === "system"
      ? (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
      : theme;
    document.documentElement.setAttribute("data-theme", resolved);
    set({ theme });
  },
  setReminderEnabled: (v) => {
    localStorage.setItem("reminderEnabled", String(v));
    set({ reminderEnabled: v });
  },
  setReminderTime: (time) => {
    localStorage.setItem("reminderTime", time);
    set({ reminderTime: time });
  },
}));
