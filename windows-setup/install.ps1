# Windows setup script
# Run in PowerShell as Administrator:  .\install.ps1
# Verify any uncertain package IDs first with:  winget search <name>

$packages = @(
    # ── Terminal & Window Management ──────────────────────────────────────────
    "Microsoft.PowerToys",          # Snap layouts, color picker, keyboard remapper, spotlight-style launcher
    "wez.wezterm",                  # Terminal emulator

    # ── Browsers ─────────────────────────────────────────────────────────────
    "Google.Chrome",
    "Mozilla.Firefox.DeveloperEdition",

    # ── Communication ─────────────────────────────────────────────────────────
    "Discord.Discord",
    "Telegram.TelegramDesktop",

    # ── Security ──────────────────────────────────────────────────────────────
    "Bitwarden.Bitwarden",

    # ── Office & Productivity ─────────────────────────────────────────────────
    "ONLYOFFICE.DesktopEditors",
    "Canva.Canva",
    "Obsidian.Obsidian",

    # ── Media ─────────────────────────────────────────────────────────────────
    "Spotube.Spotube",
    "Bytedance.CapCut",

    # ── Development ───────────────────────────────────────────────────────────
    "Microsoft.VisualStudioCode",   # Install the WSL extension after setup
    "Zed.Zed",
    "JetBrains.Toolbox",            # Install WebStorm from inside Toolbox
    "SourceGit.SourceGit",

    # ── Utilities ─────────────────────────────────────────────────────────────
    "7zip.7zip",
    "Microsoft.PowerShell"          # Latest PowerShell (pwsh), separate from built-in Windows PS
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Cyan
    winget install --id $pkg -e --accept-source-agreements --accept-package-agreements
}

Write-Host ""
Write-Host "Done. Manual steps remaining:" -ForegroundColor Green
Write-Host "  1. Copy wezterm.lua to C:\Users\$env:USERNAME\.wezterm.lua"
Write-Host "  2. Install Cartograph CF font (or swap to JetBrainsMono Nerd Font in wezterm.lua)"
Write-Host "  3. In VS Code: install the 'WSL' extension and set WSL as default profile"
Write-Host "  4. In JetBrains Toolbox: install WebStorm"
Write-Host "  5. hide.me VPN: download from hide.me/en/download (no winget package)"
Write-Host "  6. TradingView: use the web app or Microsoft Store"
Write-Host "  7. Run 'wsl --install' if WSL is not already set up"
