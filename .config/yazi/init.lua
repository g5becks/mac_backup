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