// @vitest-environment jsdom

import { beforeEach, describe, expect, it, vi } from "vitest";
import { checkForAppUpdate, RELEASE_URL } from "./appUpdate";

describe("Quota Float Mood release channel", () => {
  beforeEach(() => vi.restoreAllMocks());

  it("points to the Mark-0513 latest release", () => {
    expect(RELEASE_URL).toBe("https://github.com/Mark-0513/quota-float-mood/releases/latest");
  });

  it("does nothing for automatic checks until a fork-owned updater exists", async () => {
    const status = vi.fn();
    const open = vi.spyOn(window, "open");
    await checkForAppUpdate("zh-CN", messages, status, false);
    expect(status).not.toHaveBeenCalled();
    expect(open).not.toHaveBeenCalled();
  });
});

const messages = {
  checking: "checking",
  current: "current",
  downloading: (version: string) => version,
  installing: "installing",
  availableWindows: (version: string) => version,
  availableMac: (version: string) => version,
  failed: "failed",
};
