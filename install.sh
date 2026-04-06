#!/usr/bin/env bash
# =============================================================================
# Claude Companion — 一键安装脚本
# 工具链：Ghostty + Yazi + Lazygit + git-claude-flow
# 支持：macOS (Homebrew) / Linux (apt / pacman)
# =============================================================================

set -euo pipefail

# ─── 颜色 ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── 工具函数 ─────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[✓]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[✗]${RESET}    $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}━━━  $*  ━━━${RESET}"; }
ask()     { echo -e "${YELLOW}[?]${RESET}    $*"; }

# ─── 脚本所在目录（config 文件的相对路径基准）────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
   ___  _                  _        ___                          _
  / __\| |  __ _  _   _  __| | ___  / __\  ___   _ __ ___  _ __  __ _ _ __  (_)  ___   _ __
 / /   | | / _` || | | |/ _` |/ _ \/ /    / _ \ | '_ ` _ \| '_ \/ _` | '_ \ | | / _ \ | '_ \
/ /____| || (_| || |_| | (_| |  __/ /____| (_) || | | | | | |_) | (_| | | | || || (_) || | | |
\____/ |_| \__,_| \__,_|\__,_|\___|\____/ \___/ |_| |_| |_| .__/ \__,_|_| |_||_| \___/ |_| |_|
                                                            |_|
  Ghostty + Yazi + Lazygit + git-claude-flow
EOF
echo -e "${RESET}"

# ─── 检测操作系统 ─────────────────────────────────────────────────────────────
step "检测运行环境"

OS=""
PKG_MANAGER=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  PKG_MANAGER="brew"
  info "检测到 macOS $(sw_vers -productVersion)"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
  PKG_MANAGER="pacman"
  info "检测到 Arch Linux"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
  PKG_MANAGER="apt"
  info "检测到 Debian/Ubuntu $(cat /etc/debian_version)"
else
  error "不支持的操作系统。当前仅支持 macOS、Arch Linux 和 Debian/Ubuntu。"
  exit 1
fi

# ─── 辅助：检查命令是否存在 ───────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

# ─── Step 1：包管理器 ─────────────────────────────────────────────────────────
step "1/7  包管理器"

if [[ "$OS" == "macos" ]]; then
  if ! has brew; then
    info "未检测到 Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # 加入 PATH（Apple Silicon）
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew 安装完成"
  else
    success "Homebrew 已安装 ($(brew --version | head -1))"
    info "更新 Homebrew..."
    brew update --quiet
  fi
elif [[ "$OS" == "arch" ]]; then
  info "使用 pacman，确保 base-devel 已安装..."
  sudo pacman -Sy --needed --noconfirm base-devel
elif [[ "$OS" == "debian" ]]; then
  info "更新 apt 索引..."
  sudo apt-get update -qq
fi

# ─── Step 2：Ghostty ──────────────────────────────────────────────────────────
step "2/7  Ghostty（GPU 加速终端）"

install_ghostty() {
  if [[ "$OS" == "macos" ]]; then
    if has ghostty; then
      success "Ghostty 已安装，跳过"
    else
      info "通过 Homebrew 安装 Ghostty..."
      brew install ghostty
      success "Ghostty 安装完成"
    fi
  elif [[ "$OS" == "arch" ]]; then
    if has ghostty; then
      success "Ghostty 已安装，跳过"
    else
      info "通过 pacman 安装 Ghostty..."
      sudo pacman -S --noconfirm ghostty || {
        warn "官方源中未找到 Ghostty，尝试通过 AUR (yay) 安装..."
        if has yay; then
          yay -S --noconfirm ghostty
        else
          warn "请手动安装 Ghostty：https://ghostty.org/docs/install/binary"
        fi
      }
    fi
  elif [[ "$OS" == "debian" ]]; then
    if has ghostty; then
      success "Ghostty 已安装，跳过"
    else
      warn "Debian/Ubuntu 官方源暂无 Ghostty，请手动下载安装包："
      warn "  https://ghostty.org/docs/install/binary"
      warn "安装完成后重新运行此脚本，或按 Enter 跳过继续..."
      read -r
    fi
  fi
}
install_ghostty

# ─── Step 3：Yazi 及其依赖 ────────────────────────────────────────────────────
step "3/7  Yazi（终端文件管理器）"

install_yazi() {
  if [[ "$OS" == "macos" ]]; then
    info "安装 Yazi 及所有预览依赖..."
    brew install yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide bat imagemagick
    success "Yazi 安装完成"
  elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --needed --noconfirm yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide bat imagemagick
    success "Yazi 安装完成"
  elif [[ "$OS" == "debian" ]]; then
    sudo apt-get install -y fd-find ripgrep fzf zoxide bat imagemagick poppler-utils
    # Yazi 本体需要 cargo 或手动安装
    if has cargo; then
      cargo install --locked yazi-fm yazi-cli
    else
      warn "未检测到 cargo，正在安装 Rust..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      # shellcheck source=/dev/null
      source "$HOME/.cargo/env"
      cargo install --locked yazi-fm yazi-cli
    fi
    success "Yazi 安装完成"
  fi
}
install_yazi

# ─── Step 4：Lazygit ──────────────────────────────────────────────────────────
step "4/7  Lazygit（终端 Git UI）"

install_lazygit() {
  if has lazygit; then
    success "Lazygit 已安装 ($(lazygit --version | head -1))"
    return
  fi

  if [[ "$OS" == "macos" ]]; then
    brew install lazygit
  elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm lazygit
  elif [[ "$OS" == "debian" ]]; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
      | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -Lo /tmp/lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
  fi
  success "Lazygit 安装完成"
}
install_lazygit

# ─── Step 5：辅助工具（git-delta、Nerd Font）─────────────────────────────────
step "5/7  辅助工具（git-delta / Maple Mono NF CN）"

# git-delta（美化 diff）
if ! has delta; then
  info "安装 git-delta（美化 diff 渲染）..."
  if [[ "$OS" == "macos" ]]; then
    brew install git-delta
  elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm git-delta
  elif [[ "$OS" == "debian" ]]; then
    DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" \
      | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -Lo /tmp/delta.deb \
      "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
    sudo dpkg -i /tmp/delta.deb
    rm -f /tmp/delta.deb
  fi
  success "git-delta 安装完成"
else
  success "git-delta 已安装，跳过"
fi

# Maple Mono NF CN 字体（macOS）
if [[ "$OS" == "macos" ]]; then
  if fc-list 2>/dev/null | grep -qi "Maple Mono"; then
    success "Maple Mono NF CN 字体已安装，跳过"
  else
    info "安装 Maple Mono NF CN 字体..."
    brew install --cask font-maple-mono-nf-cn 2>/dev/null || {
      warn "Cask 安装失败，请手动下载字体："
      warn "  https://github.com/subframe7536/maple-font/releases"
    }
    success "Maple Mono NF CN 安装完成"
  fi
fi

# ─── Step 6：写入配置文件 ─────────────────────────────────────────────────────
step "6/7  写入配置文件"

# --- Ghostty ---
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
GHOSTTY_CONFIG_FILE="$GHOSTTY_CONFIG_DIR/config"

mkdir -p "$GHOSTTY_CONFIG_DIR"

if [[ -f "$GHOSTTY_CONFIG_FILE" ]]; then
  ask "已检测到 Ghostty 配置文件 ($GHOSTTY_CONFIG_FILE)，是否覆盖？[y/N] "
  read -r REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    cp "$GHOSTTY_CONFIG_FILE" "${GHOSTTY_CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    info "原配置已备份"
    cp "$SCRIPT_DIR/config/ghostty-config" "$GHOSTTY_CONFIG_FILE"
    success "Ghostty 配置已写入 $GHOSTTY_CONFIG_FILE"
  else
    info "跳过 Ghostty 配置覆盖"
  fi
else
  cp "$SCRIPT_DIR/config/ghostty-config" "$GHOSTTY_CONFIG_FILE"
  success "Ghostty 配置已写入 $GHOSTTY_CONFIG_FILE"
fi

# --- Yazi ---
YAZI_CONFIG_DIR="$HOME/.config/yazi"
mkdir -p "$YAZI_CONFIG_DIR"

if [[ ! -f "$YAZI_CONFIG_DIR/yazi.toml" ]]; then
  cat > "$YAZI_CONFIG_DIR/yazi.toml" << 'YAZI_TOML'
[manager]
ratio          = [1, 3, 4]
sort_by        = "natural"
sort_dir_first = true
show_hidden    = true

[preview]
max_width  = 1200
max_height = 900

[opener]
edit = [
  { run = 'nvim "$@"', block = true, for = "unix" },
]
YAZI_TOML
  success "Yazi 配置已写入 $YAZI_CONFIG_DIR/yazi.toml"
else
  success "Yazi 配置已存在，跳过"
fi

if [[ ! -f "$YAZI_CONFIG_DIR/keymap.toml" ]]; then
  cat > "$YAZI_CONFIG_DIR/keymap.toml" << 'YAZI_KEYMAP'
[[manager.prepend_keymap]]
on   = ["g", "h"]
run  = "cd ~"
desc = "跳转到 Home 目录"

[[manager.prepend_keymap]]
on   = ["g", "c"]
run  = "cd ~/.config"
desc = "跳转到配置目录"

[[manager.prepend_keymap]]
on   = ["g", "r"]
run  = "cd ~/CodeHub"
desc = "跳转到代码仓库根目录"
YAZI_KEYMAP
  success "Yazi keymap 已写入 $YAZI_CONFIG_DIR/keymap.toml"
else
  success "Yazi keymap 已存在，跳过"
fi

# --- Lazygit ---
LAZYGIT_CONFIG_DIR="$HOME/.config/lazygit"
mkdir -p "$LAZYGIT_CONFIG_DIR"

if [[ ! -f "$LAZYGIT_CONFIG_DIR/config.yml" ]]; then
  cat > "$LAZYGIT_CONFIG_DIR/config.yml" << 'LAZYGIT_YAML'
gui:
  showIcons: true
  nerdFontsVersion: "3"
  theme:
    activeBorderColor:
      - "#89b4fa"
      - bold
    inactiveBorderColor:
      - "#585b70"
    selectedLineBgColor:
      - "#313244"
  showCommandLog: false
  showBottomLine: false

git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
  autoFetch: true
  autoRefresh: true
  branchLogCmd: "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --"

os:
  editPreset: "nvim"

keybinding:
  universal:
    quit: "q"
    return: "<esc>"
LAZYGIT_YAML
  success "Lazygit 配置已写入 $LAZYGIT_CONFIG_DIR/config.yml"
else
  success "Lazygit 配置已存在，跳过"
fi

# --- git-delta gitconfig ---
if has delta && ! git config --global core.pager | grep -q delta; then
  info "配置 git 全局 delta pager..."
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global delta.line-numbers true
  git config --global delta.theme "Catppuccin Mocha"
  success "git-delta 全局配置完成"
fi

# ─── Step 7：git-claude-flow（user 模式）──────────────────────────────────────
step "7/7  git-claude-flow（Claude Code Git 工作流增强）"

install_git_claude_flow() {
  # 检查 claude CLI 是否存在
  if ! has claude; then
    warn "未检测到 claude CLI，跳过 git-claude-flow 安装。"
    warn "安装 Claude Code 后，请手动运行以下命令："
    warn "  claude mcp add --transport http git-claude-flow \\"
    warn "    https://git-claude-flow.your-domain.com/mcp"
    return
  fi

  info "通过 claude MCP 安装 git-claude-flow（user 模式）..."

  # 检查是否已安装
  if claude mcp list 2>/dev/null | grep -q "git-claude-flow"; then
    success "git-claude-flow 已安装，跳过"
    return
  fi

  # 使用 npm user 模式安装
  if has npm; then
    npm install -g git-claude-flow 2>/dev/null && {
      success "git-claude-flow (npm) 安装完成"
    } || {
      warn "npm 安装失败，请参考：https://github.com/iliYF/git-claude-flow"
    }
  elif has npx; then
    info "将使用 npx 按需运行 git-claude-flow"
    success "git-claude-flow 可通过 npx git-claude-flow 使用"
  else
    warn "未检测到 npm/npx，请安装 Node.js 后手动安装 git-claude-flow："
    warn "  npm install -g git-claude-flow"
    warn "  项目地址：https://github.com/iliYF/git-claude-flow"
  fi
}
install_git_claude_flow

# ─── 完成摘要 ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}  ✅  Claude Companion 安装完成！${RESET}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${RESET}"
echo ""
echo -e "${BOLD}已安装 / 已配置：${RESET}"
has ghostty  && echo -e "  ${GREEN}✓${RESET} Ghostty   — GPU 加速终端" || echo -e "  ${YELLOW}⚠${RESET} Ghostty   — 未安装或需手动安装"
has yazi     && echo -e "  ${GREEN}✓${RESET} Yazi      — 终端文件管理器" || echo -e "  ${YELLOW}⚠${RESET} Yazi      — 未安装"
has lazygit  && echo -e "  ${GREEN}✓${RESET} Lazygit   — 终端 Git UI" || echo -e "  ${YELLOW}⚠${RESET} Lazygit   — 未安装"
has delta    && echo -e "  ${GREEN}✓${RESET} git-delta — 美化 diff 渲染" || echo -e "  ${YELLOW}⚠${RESET} git-delta — 未安装"
echo ""
echo -e "${BOLD}下一步：${RESET}"
echo -e "  1. 打开 ${CYAN}Ghostty${RESET}"
echo -e "  2. ${CYAN}⌘+D${RESET} 右侧分屏  →  输入 ${CYAN}yazi .${RESET}"
echo -e "  3. 在右侧再按 ${CYAN}⌘+D${RESET} 分屏  →  输入 ${CYAN}lazygit${RESET}"
echo -e "  4. ${CYAN}⌘+[${RESET} 跳回主面板  →  输入 ${CYAN}claude${RESET}"
echo ""
echo -e "  📖 完整使用指南：${CYAN}docs/guide.zh.md${RESET}"
echo ""

# 如果 Ghostty 配置里有注释掉的 initial-command，提示用户
if grep -q "^# initial-command" "$HOME/.config/ghostty/config" 2>/dev/null; then
  echo -e "${YELLOW}💡 提示：${RESET}安装好 Claude Code 后，取消注释 Ghostty 配置中的以下行："
  echo -e "     ${CYAN}~/.config/ghostty/config${RESET}"
  echo -e "     ${CYAN}initial-command = /opt/homebrew/bin/claude${RESET}"
  echo -e "   这样 Ghostty 新窗口将自动启动 claude。"
  echo ""
fi
