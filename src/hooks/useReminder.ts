import { useEffect, useRef } from "react";
import { useStore } from "../lib/store";
import { checkShouldRemind } from "../lib/api";
import {
  isPermissionGranted,
  requestPermission,
  sendNotification,
} from "@tauri-apps/plugin-notification";

export function useReminder() {
  const reminderEnabled = useStore((s) => s.reminderEnabled);
  const reminderTime = useStore((s) => s.reminderTime);
  const lastNotifiedDate = useRef<string>("");

  useEffect(() => {
    if (!reminderEnabled) return;

    const check = async () => {
      const now = new Date();
      const hhmm = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
      const today = now.toISOString().slice(0, 10);

      if (hhmm !== reminderTime) return;
      if (lastNotifiedDate.current === today) return;

      try {
        const shouldRemind = await checkShouldRemind();
        if (!shouldRemind) return;

        let granted = await isPermissionGranted();
        if (!granted) {
          const permission = await requestPermission();
          granted = permission === "granted";
        }
        if (!granted) return;

        sendNotification({
          title: "InnerForge",
          body: "今天还没写日记哦，花几分钟记录一下吧 ✍️",
        });
        lastNotifiedDate.current = today;
      } catch {
        // silently ignore
      }
    };

    check();
    const timer = setInterval(check, 60_000);
    return () => clearInterval(timer);
  }, [reminderEnabled, reminderTime]);
}
