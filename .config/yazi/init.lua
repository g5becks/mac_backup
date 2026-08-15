-- Git-root detection (existing)
if os.getenv("YAZI_START_AT_ROOT") then
  local root = io.popen("git rev-parse --show-toplevel 2>/dev/null"):read("*a")
  if root and root ~= "" then
    ya.manager_emit("cd", { root:gsub("[\r\n]", "") })
  end
end

-- Batch 1: official plugins
require("git"):setup()
require("full-border"):setup()
require("vscode-git-colors"):setup()
require("mobile-auto-layout"):setup({
  threshold = 90,
  parent_max = 30,
  current_max = 30,
  min_width = 16,      -- raised from 10 — floor for how narrow parent can get
  reading_frac = 0.10,
  padding = 9,
  previewers = { "vscode-git-gutter", "code" },
})