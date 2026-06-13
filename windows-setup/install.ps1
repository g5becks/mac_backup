# Windows setup script
# Run in PowerShell as Administrator:  .\install.ps1
#
# PowerToys replaces: Alfred, BetterSnapTool, ColorSlurp, Karabiner
#   - PowerToys Run       = Spotlight-style launcher (Alt+Space)
#   - FancyZones          = window snap layouts
#   - Color Picker        = system-wide color picker
#   - Keyboard Manager    = key remapping

$wingetPackages = @(
    # ── Utilities ─────────────────────────────────────────────────────────────
    "Microsoft.PowerToys",

    # ── Terminal ──────────────────────────────────────────────────────────────
    "wez.wezterm",

    # ── Browser ───────────────────────────────────────────────────────────────
    "Mozilla.Firefox.DeveloperEdition",

    # ── Communication ─────────────────────────────────────────────────────────
    "Discord.Discord",
    "Telegram.TelegramDesktop",

    # ── Security ──────────────────────────────────────────────────────────────
    "Bitwarden.Bitwarden",

    # ── Productivity ──────────────────────────────────────────────────────────
    "Canva.Canva",
    "ONLYOFFICE.DesktopEditors",

    # ── Media ─────────────────────────────────────────────────────────────────
    "Bytedance.CapCut",

    # ── AI ────────────────────────────────────────────────────────────────────
    "Google.Antigravity"
)

foreach ($pkg in $wingetPackages) {
    Write-Host "Installing $pkg..." -ForegroundColor Cyan
    winget install --id $pkg -e --accept-source-agreements --accept-package-agreements
}

# X (Twitter) — Spring replacement, installed from Microsoft Store
Write-Host "Installing X (Twitter) from Microsoft Store..." -ForegroundColor Cyan
winget install --id 9NBLGGH5L9XT --source msstore --accept-package-agreements

Write-Host ""
Write-Host "Done. Manual steps remaining:" -ForegroundColor Green
Write-Host "  1. Copy wezterm.lua to C:\Users\$env:USERNAME\.wezterm.lua"
Write-Host "     (find it in your yadm repo under windows-setup/wezterm.lua)"
Write-Host "  2. Install Cartograph CF font — or edit wezterm.lua to use JetBrainsMono Nerd Font"
Write-Host "  3. Run 'wsl --install' if WSL is not already set up, then restore yadm backup"
Write-Host ""
Write-Host "Verify any failed packages with: winget search <name>" -ForegroundColor Yellow
