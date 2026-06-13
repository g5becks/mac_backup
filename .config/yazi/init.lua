-- Yazi init.lua - Helix integration support
-- This enables starting Yazi at the git project root when YAZI_START_AT_ROOT=1 is set

if os.getenv("YAZI_START_AT_ROOT") then
  local root = io.popen("git rev-parse --show-toplevel 2>/dev/null"):read("*a")
  if root and root ~= "" then
    ya.manager_emit("cd", { root:gsub("[\r\n]", "") })
  end
end
