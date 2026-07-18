import { isTauri } from "./bridge";
import type { Language } from "../types";

export const RELEASE_URL = "https://github.com/Mark-0513/quota-float-mood/releases";

export interface UpdateMessages {
  checking: string;
  current: string;
  downloading: (version: string) => string;
  installing: string;
  availableWindows: (version: string) => string;
  availableMac: (version: string) => string;
  failed: string;
}

export async function openReleasePage(): Promise<void> {
  if (!isTauri()) {
    window.open(RELEASE_URL, "_blank", "noopener,noreferrer");
    return;
  }
  const { openUrl } = await import("@tauri-apps/plugin-opener");
  await openUrl(RELEASE_URL);
}

export async function checkForAppUpdate(
  _language: Language,
  messages: UpdateMessages,
  setStatus: (message: string | null) => void,
  manual = false,
): Promise<void> {
  if (!manual) return;
  try {
    await openReleasePage();
  } catch {
    setStatus(messages.failed);
  }
}
