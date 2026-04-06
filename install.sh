#!/usr/bin/env bash
# =============================================================================
# Claude Companion — Installer
# Stack: Ghostty + Yazi + Lazygit + git-claude-flow
# Platform: macOS only
# Modes: --auto (one-click, all defaults) | --interactive (step-by-step, default)
# =============================================================================

set -euo pipefail

# =============================================================================
# Argument parsing
# =============================================================================

DRY_RUN=false
INSTALL_MODE=""   # auto | interactive — empty means not yet chosen

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=true ;;
        --auto)        INSTALL_MODE="auto" ;;
        --interactive) INSTALL_MODE="interactive" ;;
        --help|-h)
            echo "Usage: bash install.sh [options]"
            echo ""
            echo "  --auto          One-click install — all defaults, no prompts"
            echo "  --interactive   Step-by-step install with prompts (default)"
            echo "  --dry-run       Simulate the full install flow without executing anything"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg  (use --help for usage)" >&2
            exit 1
            ;;
    esac
done

# =============================================================================
# Color output
# =============================================================================

if [ -t 1 ] && command -v tput &>/dev/null && tput colors &>/dev/null && [ "$(tput colors)" -ge 8 ]; then
    C_RESET=$'\033[0m'
    C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m'
    C_RED=$'\033[0;31m'
    C_CYAN=$'\033[0;36m'
    C_BLUE=$'\033[0;34m'
    C_MAGENTA=$'\033[0;35m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
else
    C_RESET="" C_GREEN="" C_YELLOW="" C_RED="" C_CYAN="" C_BLUE=""
    C_MAGENTA="" C_BOLD="" C_DIM=""
fi

ok()     { echo "${C_GREEN}✓${C_RESET} $*"; }
msg()    { echo "${C_CYAN}→${C_RESET} $*"; }
warn()   { echo "${C_YELLOW}⚠${C_RESET} $*"; }
err()    { echo "${C_RED}✗${C_RESET} $*" >&2; }
die()    { err "$*"; exit 1; }
skip()   { echo "${C_DIM}  ↷ skip: $*${C_RESET}"; }
dryrun() { echo "${C_DIM}  [dry-run]${C_RESET} ${C_YELLOW}$*${C_RESET}"; }

section() {
    echo ""
    echo "${C_BOLD}${C_CYAN}============================================${C_RESET}"
    echo "${C_BOLD}${C_CYAN}  $*${C_RESET}"
    echo "${C_BOLD}${C_CYAN}============================================${C_RESET}"
    echo ""
}
divider() { echo "${C_DIM}--------------------------------------------${C_RESET}"; }
has()     { command -v "$1" &>/dev/null; }

# run <cmd> [args...] — execute for real or print in dry-run mode
run() {
    if $DRY_RUN; then
        dryrun "$*"
    else
        "$@"
    fi
}

# is_auto: true when running in one-click mode
is_auto() { [[ "$INSTALL_MODE" == "auto" ]]; }

# =============================================================================
# TTY-safe input (compatible with pipe execution)
# =============================================================================

read_tty() {
    local __var="$1"
    local __val
    if [ -t 0 ]; then
        read -r __val
    else
        read -r __val < /dev/tty
    fi
    eval "$__var=\$__val"
}

# =============================================================================
# MD5 comparison (macOS: md5 -q)
# =============================================================================

file_md5() {
    md5 -q "$1" 2>/dev/null || echo ""
}

files_identical() {
    local a="$1" b="$2"
    [[ -f "$a" && -f "$b" ]] && [[ "$(file_md5 "$a")" == "$(file_md5 "$b")" ]]
}

# =============================================================================
# Config backup + deploy (with MD5 dedup)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

deploy_config() {
    local src="$SCRIPT_DIR/config/$1"
    local dest="$2"

    if [[ ! -f "$src" ]]; then
        warn "Config source not found: $src — skipping"
        return
    fi

    if $DRY_RUN; then
        if files_identical "$src" "$dest"; then
            dryrun "content identical, skip: $dest"
        elif [[ -f "$dest" ]]; then
            dryrun "cp $dest ${dest}.bak.<timestamp>  (content differs — backup then update)"
            dryrun "cp $src $dest"
        else
            dryrun "cp $src $dest  (new file)"
        fi
        return
    fi

    if files_identical "$src" "$dest"; then
        skip "config already up-to-date → $dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        local bak="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$dest" "$bak"
        msg "Backed up existing config → ${C_DIM}$bak${C_RESET}"
    fi
    cp "$src" "$dest"
    ok "Config deployed → $dest"
}

append_to_zshrc() {
    local line="$1"
    local marker="${2:-$line}"

    if $DRY_RUN; then
        if grep -qF "$marker" "$HOME/.zshrc" 2>/dev/null; then
            dryrun "already in ~/.zshrc, skip: $marker"
        else
            dryrun "echo '$line' >> ~/.zshrc"
        fi
        return
    fi

    if ! grep -qF "$marker" "$HOME/.zshrc" 2>/dev/null; then
        echo "$line" >> "$HOME/.zshrc"
        msg "Added to ~/.zshrc: ${C_DIM}$line${C_RESET}"
    else
        skip "already in ~/.zshrc: ${C_DIM}$marker${C_RESET}"
    fi
}

# =============================================================================
# Banner
# =============================================================================

echo ""
echo "  ${C_BOLD}${C_CYAN}C${C_BLUE}laude${C_RESET} ${C_BOLD}${C_MAGENTA}C${C_RED}ompanion${C_RESET}  —  Developer Suite Installer"
echo "  ${C_DIM}Ghostty · Yazi · Lazygit · git-claude-flow${C_RESET}"
echo ""
if $DRY_RUN; then
    echo "  ${C_BOLD}${C_YELLOW}[DRY-RUN MODE]${C_RESET}  Simulating flow only — nothing will be executed"
    echo ""
fi

# Prompt for mode if not set via argument
if [[ -z "$INSTALL_MODE" ]]; then
    echo "  ${C_BOLD}Select install mode:${C_RESET}"
    echo ""
    echo "  ${C_CYAN}[1]${C_RESET} ${C_BOLD}Interactive${C_RESET}  ${C_DIM}(default)${C_RESET} — step-by-step with confirmation prompts"
    echo "  ${C_CYAN}[2]${C_RESET} ${C_BOLD}Auto${C_RESET}                  — one-click, all defaults, no prompts"
    echo ""
    printf "  Enter option [1-2] (default 1): "
    _mode_input=""
    read_tty _mode_input
    _mode_input="${_mode_input:-1}"
    if [[ "$_mode_input" == "2" ]]; then
        INSTALL_MODE="auto"
    else
        INSTALL_MODE="interactive"
    fi
    echo ""
fi

if is_auto; then
    echo "  ${C_BOLD}${C_GREEN}[AUTO MODE]${C_RESET}         One-click install — all defaults, no prompts"
else
    echo "  ${C_BOLD}${C_CYAN}[INTERACTIVE MODE]${C_RESET}  Step-by-step install with confirmation prompts"
fi
echo ""

# =============================================================================
# STEP 0 — Environment detection
# =============================================================================

section "Environment Detection"

# macOS only
if [[ "$OSTYPE" != "darwin"* ]]; then
    err "This script supports macOS only."
    echo ""
    echo "  Current OS: ${C_BOLD}$OSTYPE${C_RESET}"
    echo "  ${C_DIM}Claude Companion is currently available as a one-click installer for macOS only.${C_RESET}"
    echo ""
    exit 1
fi

ok "macOS $(sw_vers -productVersion) detected."

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    if $DRY_RUN; then
        warn "Xcode Command Line Tools not found."
        dryrun "xcode-select --install"
    else
        msg "Xcode Command Line Tools not found, installing..."
        xcode-select --install
        echo ""
        warn "Complete the installation in the pop-up window, then re-run this script."
        exit 0
    fi
else
    ok "Xcode Command Line Tools ready."
fi

# Homebrew
echo ""
if ! has brew; then
    if $DRY_RUN; then
        warn "Homebrew not found."
        dryrun '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        dryrun 'eval "$(/opt/homebrew/bin/brew shellenv)"  →  append to ~/.zshrc'
    else
        msg "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            append_to_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"' "homebrew shellenv"
        fi
        ok "Homebrew installed."
    fi
else
    ok "Homebrew $(brew --version | head -1 | awk '{print $2}') ready."
fi

# =============================================================================
# STEP 1 — GHOSTTY
# =============================================================================

section "Step 1 / 4 — Ghostty  (GPU-accelerated terminal)"
echo "  ${C_DIM}Native split panes, blur effects — built for Claude Code.${C_RESET}"
echo ""

# Ghostty
if has ghostty && ! $DRY_RUN; then
    ok "Ghostty already installed, skipping."
else
    $DRY_RUN && has ghostty && ok "Ghostty already installed (showing flow in dry-run)."
    run brew install --cask ghostty
    $DRY_RUN || ok "Ghostty installed."
fi

divider

# JetBrains Mono Nerd Font
if ! $DRY_RUN && brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
    ok "JetBrains Mono Nerd Font already installed, skipping."
else
    run brew install --cask font-jetbrains-mono-nerd-font
    $DRY_RUN || ok "JetBrains Mono Nerd Font installed."
fi

divider

# Starship
if has starship && ! $DRY_RUN; then
    ok "Starship already installed, skipping."
else
    $DRY_RUN && has starship && ok "Starship already installed (showing flow in dry-run)."
    run brew install starship
    $DRY_RUN || ok "Starship installed."
fi

# Apply starship preset — compare before overwriting to protect manual customizations
if $DRY_RUN; then
    dryrun "starship preset catppuccin-powerline -o /tmp/starship_preset.toml"
    dryrun "md5 compare /tmp/starship_preset.toml vs ~/.config/starship.toml → backup and update if different"
else
    _starship_tmp="$(mktemp /tmp/starship_preset.XXXXXX.toml)"
    if starship preset catppuccin-powerline -o "$_starship_tmp" 2>/dev/null; then
        _starship_dest="$HOME/.config/starship.toml"
        if files_identical "$_starship_tmp" "$_starship_dest"; then
            skip "Starship preset already up-to-date → ~/.config/starship.toml"
        else
            mkdir -p "$HOME/.config"
            if [[ -f "$_starship_dest" ]]; then
                cp "$_starship_dest" "${_starship_dest}.bak.$(date +%Y%m%d%H%M%S)"
                msg "Backed up existing starship.toml"
            fi
            cp "$_starship_tmp" "$_starship_dest"
            ok "Starship catppuccin-powerline preset applied → ~/.config/starship.toml"
        fi
    else
        warn "starship preset command failed, skipping preset write."
    fi
    rm -f "$_starship_tmp"
fi

# Ask whether to enable Starship in zshrc — skip if already configured
echo ""
if grep -qF "starship init zsh" "$HOME/.zshrc" 2>/dev/null; then
    skip "Starship already enabled in ~/.zshrc."
else
    if is_auto; then
        starship_enable="1"
    else
        echo "  ${C_BOLD}Enable Starship prompt in Ghostty?${C_RESET}  ${C_DIM}(writes to ~/.zshrc)${C_RESET}"
        echo ""
        echo "  ${C_CYAN}[1]${C_RESET} Enable"
        echo "  ${C_CYAN}[2]${C_RESET} Skip"
        echo ""
        printf "  Enter option [1-2] (default 1): "
        read_tty starship_enable
        starship_enable="${starship_enable:-1}"
    fi
    if [[ "$starship_enable" == "1" ]]; then
        append_to_zshrc \
            'if [ "$TERM" = "xterm-ghostty" ]; then eval "$(starship init zsh)"; fi' \
            "starship init zsh"
    fi
fi

divider
msg "Deploying Ghostty config..."
deploy_config "config.ghostty" "$HOME/.config/ghostty/config"

# =============================================================================
# STEP 2 — YAZI
# =============================================================================

section "Step 2 / 4 — Yazi  (terminal file manager)"
echo "  ${C_DIM}Written in Rust — blazing fast file browsing with live preview.${C_RESET}"
echo ""

# Yazi
if has yazi && ! $DRY_RUN; then
    ok "Yazi already installed, skipping."
else
    $DRY_RUN && has yazi && ok "Yazi already installed (showing flow in dry-run)."
    run brew install yazi
    $DRY_RUN || ok "Yazi installed."
fi

divider
# Check if all preview dependencies are already installed before running brew install
_yazi_deps=(jq poppler fd ripgrep bat imagemagick resvg font-symbols-only-nerd-font)
_yazi_missing=()
if ! $DRY_RUN; then
    for _dep in "${_yazi_deps[@]}"; do
        if [[ "$_dep" == font-* ]]; then
            brew list --cask "$_dep" &>/dev/null 2>&1 || _yazi_missing+=("$_dep")
        else
            brew list --formula "$_dep" &>/dev/null 2>&1 || _yazi_missing+=("$_dep")
        fi
    done
fi

if $DRY_RUN; then
    msg "Installing preview dependencies..."
    dryrun "brew install ${_yazi_deps[*]}"
elif [[ ${#_yazi_missing[@]} -eq 0 ]]; then
    skip "all preview dependencies already installed."
else
    msg "Installing missing preview dependencies: ${_yazi_missing[*]}"
    brew install "${_yazi_missing[@]}"
    ok "Preview dependencies installed."
fi

# Catppuccin theme
divider
msg "Installing Yazi Catppuccin themes..."
_yazi_flavors_dir="$HOME/.config/yazi/flavors"
for _flavor in catppuccin-mocha catppuccin-latte; do
    if [[ -d "${_yazi_flavors_dir}/${_flavor}.yazi" ]] && ! $DRY_RUN; then
        skip "Yazi flavor already exists: ${_flavor}"
    else
        $DRY_RUN && [[ -d "${_yazi_flavors_dir}/${_flavor}.yazi" ]] && \
            dryrun "ya pkg add yazi-rs/flavors:${_flavor}  (already exists, showing in dry-run)" && continue
        run ya pkg add "yazi-rs/flavors:${_flavor}"
        $DRY_RUN || ok "Yazi flavor installed: ${_flavor}"
    fi
done

divider
msg "Deploying Yazi config..."
deploy_config "yazi.toml"        "$HOME/.config/yazi/yazi.toml"
deploy_config "yazi.keymap.toml" "$HOME/.config/yazi/keymap.toml"
deploy_config "yazi.theme.toml"  "$HOME/.config/yazi/theme.toml"

# Optional developer tools — auto mode skips by default
divider
echo ""
echo "  ${C_BOLD}Install optional developer tools?${C_RESET}  ${C_DIM}(standalone tools, globally available)${C_RESET}"
echo ""
echo "  ${C_DIM}  fzf    — fuzzy finder for files, command history, and more${C_RESET}"
echo "  ${C_DIM}  zoxide — smart cd with directory memory, jump with: z <keyword>${C_RESET}"
echo "  ${C_DIM}  eza    — modern ls with colors, icons, and Git status${C_RESET}"
echo "  ${C_DIM}  dust   — intuitive disk usage analyzer, locate large files fast${C_RESET}"
echo "  ${C_DIM}  duf    — disk mount info, a better df -h${C_RESET}"
echo ""

if is_auto; then
    devtools_choice="2"
    skip "optional developer tools (auto mode default)."
else
    echo "  ${C_CYAN}[1]${C_RESET} Install"
    echo "  ${C_CYAN}[2]${C_RESET} Skip"
    echo ""
    printf "  Enter option [1-2] (default 1): "
    read_tty devtools_choice
    devtools_choice="${devtools_choice:-1}"
fi

if [[ "$devtools_choice" == "1" ]]; then
    _dev_tools=(fzf zoxide eza dust duf)
    _dev_missing=()
    if ! $DRY_RUN; then
        for _dt in "${_dev_tools[@]}"; do
            brew list --formula "$_dt" &>/dev/null 2>&1 || _dev_missing+=("$_dt")
        done
    fi

    if $DRY_RUN; then
        dryrun "brew install ${_dev_tools[*]}"
        dryrun "append to ~/.zshrc: zoxide init (Ghostty-gated)"
    elif [[ ${#_dev_missing[@]} -eq 0 ]]; then
        skip "all developer tools already installed."
    else
        msg "Installing missing developer tools: ${_dev_missing[*]}"
        brew install "${_dev_missing[@]}"
        ok "Developer tools installed."
    fi

    append_to_zshrc \
        'if [ "$TERM" = "xterm-ghostty" ]; then eval "$(zoxide init zsh)"; fi' \
        "zoxide init zsh"
fi

# =============================================================================
# STEP 3 — LAZYGIT
# =============================================================================

section "Step 3 / 4 — Lazygit  (terminal Git UI)"
echo "  ${C_DIM}Visual diff, interactive staging, commit and push in one keystroke.${C_RESET}"
echo ""

# Lazygit
if has lazygit && ! $DRY_RUN; then
    ok "Lazygit already installed, skipping."
else
    $DRY_RUN && has lazygit && ok "Lazygit already installed (showing flow in dry-run)."
    run brew install lazygit
    $DRY_RUN || ok "Lazygit installed."
fi

divider
msg "Installing git-delta..."
# bat is already installed in Step 2; check only git-delta here
if ! $DRY_RUN && brew list --formula git-delta &>/dev/null 2>&1; then
    ok "git-delta already installed, skipping."
else
    run brew install git-delta
    $DRY_RUN || ok "git-delta installed."
fi

run git config --global core.pager             "delta"
run git config --global interactive.diffFilter "delta --color-only"
run git config --global delta.navigate         true
run git config --global delta.side-by-side     true
run git config --global delta.line-numbers     true
run git config --global delta.theme            "Catppuccin Mocha"
$DRY_RUN || ok "git-delta config written to ~/.gitconfig"

# lazygit alias — skip entirely if any candidate already aliases to lazygit
divider
echo ""

_lazygit_alias_done=false
for candidate in lg lgit lag; do
    if grep -qE "alias ${candidate}=['\"]?lazygit['\"]?" "$HOME/.zshrc" 2>/dev/null; then
        skip "alias '${candidate}' already points to lazygit."
        _lazygit_alias_done=true
        break
    fi
done

if ! $_lazygit_alias_done; then
    AVAIL_ALIASES=()
    for candidate in lg lgit lag; do
        if $DRY_RUN || ! grep -qE "alias ${candidate}=" "$HOME/.zshrc" 2>/dev/null; then
            AVAIL_ALIASES+=("$candidate")
        fi
    done

    if [[ ${#AVAIL_ALIASES[@]} -eq 0 ]]; then
        skip "lg / lgit / lag are all taken by other commands."
    else
        if is_auto; then
            selected="${AVAIL_ALIASES[0]}"
            append_to_zshrc "alias ${selected}=\"lazygit\"" "alias ${selected}="
        else
            echo "  ${C_BOLD}Add a lazygit shell alias to ~/.zshrc?${C_RESET}"
            echo ""
            idx=1
            for c in "${AVAIL_ALIASES[@]}"; do
                if [[ $idx -eq 1 ]]; then
                    echo "  ${C_CYAN}[${idx}]${C_RESET} ${C_BOLD}${c}${C_RESET}  ${C_DIM}(recommended)${C_RESET}"
                else
                    echo "  ${C_CYAN}[${idx}]${C_RESET} ${c}"
                fi
                idx=$((idx + 1))
            done
            echo "  ${C_CYAN}[0]${C_RESET} Skip"
            echo ""
            printf "  Enter option (default 1): "
            read_tty lg_choice
            lg_choice="${lg_choice:-1}"

            if [[ "$lg_choice" == "0" ]]; then
                skip "alias setup."
            elif [[ "$lg_choice" =~ ^[1-9][0-9]*$ ]] && [[ $lg_choice -le ${#AVAIL_ALIASES[@]} ]]; then
                selected="${AVAIL_ALIASES[$((lg_choice - 1))]}"
                append_to_zshrc "alias ${selected}=\"lazygit\"" "alias ${selected}="
            else
                warn "Invalid option, skipping alias setup."
            fi
        fi
    fi
fi

divider
msg "Deploying Lazygit config..."
deploy_config "lazygit.config.yaml" "$HOME/.config/lazygit/config.yml"

# =============================================================================
# STEP 4 — git-claude-flow
# =============================================================================

section "Step 4 / 4 — git-claude-flow  (parallel branch Git workflow)"
echo "  ${C_DIM}A Git workflow tool designed for parallel development with Claude Code.${C_RESET}"
echo "  ${C_DIM}Wraps worktree management and branch switching so multiple Claude Code${C_RESET}"
echo "  ${C_DIM}sessions can progress independently on separate branches.${C_RESET}"
echo ""

# Detect if git-claude-flow is already installed (user mode: ~/.git-claude-flow/git-claude-flow)
_gcf_installed=false
if [[ -f "$HOME/.git-claude-flow/git-claude-flow" ]]; then
    _gcf_installed=true
fi

if $_gcf_installed && ! $DRY_RUN; then
    ok "git-claude-flow already installed, skipping."
else
    $_gcf_installed && $DRY_RUN && ok "git-claude-flow already installed (showing flow in dry-run)."

    if is_auto; then
        gcf_choice="1"
    else
        echo "  ${C_CYAN}[1]${C_RESET} Install"
        echo "  ${C_CYAN}[2]${C_RESET} Skip"
        echo ""
        printf "  Enter option [1-2] (default 1): "
        read_tty gcf_choice
        gcf_choice="${gcf_choice:-1}"
    fi

    if [[ "$gcf_choice" == "1" ]]; then
        echo ""
        msg "Install mode: ${C_BOLD}user${C_RESET}  (default)"
        echo ""

        if is_auto; then
            gcf_alias="claude"
            gcf_cmd="claude"
        else
            echo "  ${C_BOLD}Shell alias:${C_RESET}  ${C_DIM}(the command name registered in ~/.zshrc)${C_RESET}"
            printf "  Enter alias (default: claude): "
            read_tty gcf_alias
            gcf_alias="${gcf_alias:-claude}"

            echo ""
            echo "  ${C_BOLD}Claude Code command:${C_RESET}  ${C_DIM}(the command git-claude-flow uses to launch Claude Code)${C_RESET}"
            printf "  Enter command (default: claude): "
            read_tty gcf_cmd
            gcf_cmd="${gcf_cmd:-claude}"
        fi

        echo ""
        msg "Will run: curl -sSL .../install.sh | bash -s -- --mode user --alias ${gcf_alias} --cmd ${gcf_cmd}"
        echo ""

        if $DRY_RUN; then
            dryrun "curl -sSL https://raw.githubusercontent.com/iliYF/git-claude-flow/main/install.sh | bash -s -- --mode user --alias ${gcf_alias} --cmd ${gcf_cmd}"
        else
            msg "Running git-claude-flow installer..."
            curl -sSL https://raw.githubusercontent.com/iliYF/git-claude-flow/main/install.sh | bash -s -- \
                --mode user \
                --alias "${gcf_alias}" \
                --cmd "${gcf_cmd}"
            ok "git-claude-flow installed."
        fi
    else
        skip "git-claude-flow."
        msg "To install later, run:"
        echo "  ${C_DIM}curl -sSL https://raw.githubusercontent.com/iliYF/git-claude-flow/main/install.sh | bash -s -- --mode user --alias claude --cmd claude${C_RESET}"
    fi
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "${C_BOLD}${C_GREEN}============================================${C_RESET}"
if $DRY_RUN; then
    echo "${C_BOLD}${C_GREEN}  ✓ Claude Companion dry-run complete!${C_RESET}"
else
    echo "${C_BOLD}${C_GREEN}  ✓ Claude Companion installation complete!${C_RESET}"
fi
echo "${C_BOLD}${C_GREEN}============================================${C_RESET}"
echo ""

if $DRY_RUN; then
    echo "  ${C_YELLOW}Dry-run only — nothing was actually installed or modified.${C_RESET}"
    echo "  ${C_DIM}Run bash install.sh (without --dry-run) to perform the real install.${C_RESET}"
else
    echo "${C_BOLD}Installed / configured:${C_RESET}"
    echo ""
    has ghostty  && echo "  ${C_GREEN}✓${C_RESET} Ghostty       — GPU-accelerated terminal"  || echo "  ${C_YELLOW}⚠${C_RESET} Ghostty       — not detected"
    has starship && echo "  ${C_GREEN}✓${C_RESET} Starship      — prompt with Git/CPU/time"  || echo "  ${C_DIM}  Starship      — not installed${C_RESET}"
    has yazi     && echo "  ${C_GREEN}✓${C_RESET} Yazi          — terminal file manager"     || echo "  ${C_YELLOW}⚠${C_RESET} Yazi          — not detected"
    has lazygit  && echo "  ${C_GREEN}✓${C_RESET} Lazygit       — terminal Git UI"           || echo "  ${C_YELLOW}⚠${C_RESET} Lazygit       — not detected"
    has delta    && echo "  ${C_GREEN}✓${C_RESET} git-delta     — beautiful diffs"           || echo "  ${C_DIM}  git-delta     — not installed${C_RESET}"
    echo ""
    echo "${C_BOLD}Launch your workspace:${C_RESET}"
    echo ""
    echo "  ${C_CYAN}1.${C_RESET} Open Ghostty"
    echo "  ${C_CYAN}2.${C_RESET} ${C_BOLD}⌘+D${C_RESET}  → split right → ${C_CYAN}yazi .${C_RESET}"
    echo "  ${C_CYAN}3.${C_RESET} ${C_BOLD}⌘+D${C_RESET}  → split again → ${C_CYAN}lazygit${C_RESET}"
    echo "  ${C_CYAN}4.${C_RESET} ${C_BOLD}⌘+[${C_RESET}  → back to main pane → ${C_CYAN}claude${C_RESET}"
    echo ""
    echo "  ${C_DIM}Reload shell: source ~/.zshrc${C_RESET}"
fi
echo ""
