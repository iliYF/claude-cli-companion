# Claude Companion：Ghostty + Yazi + Lazygit 高效开发环境

> 打造一套以终端为核心的开发环境，让 Claude Code 从工具升级为真正的开发伙伴。

## 为什么选择这套组合？

Claude Code 生活在终端里。这不是限制，而是超能力——**前提是你的终端环境为此而生**。

大多数开发者把 Claude Code 丢进系统默认终端就算了。他们在文件管理器、Git GUI 和浏览器标签页之间反复切换，每次切换都在消耗注意力。摩擦无处不在：让 Claude 重构一个模块，却没法快速浏览文件树来确认改动；在另一个窗口查看 diff，Claude 的输出早就滚走了。

**Claude Companion 这套组合，彻底消除这种摩擦：**

| 工具 | 职责 | 为什么重要 |
|------|------|------------|
| **Ghostty** | GPU 加速终端 | 原生分屏，零延迟渲染，多面板同时存活 |
| **Yazi** | 终端文件管理器 | 极速文件浏览 + 实时预览，你对文件系统的眼睛 |
| **Lazygit** | 终端 Git UI | 暂存、提交、diff、rebase，全在终端里搞定 |

三者组成一个**三面板驾驶舱**：Claude Code 在主面板工作，你在旁边浏览文件，第三个面板管理 Git——全部在一个 Ghostty 窗口内，全键盘驱动，响应即时。

---

## 一、Ghostty：驾驶舱的底座

### 为什么是 Ghostty？

[Ghostty](https://ghostty.org/) 是 Mitchell Hashimoto（HashiCorp 创始人）打造的终端模拟器，2024 年底正式发布后迅速成为 macOS 上最受关注的终端工具。它对这套工作流的意义在于：

- **原生分屏** — 不需要 tmux，`⌘+D` 直接左右分屏
- **GPU 加速渲染** — Claude 输出再多也不卡
- **毫秒级输入延迟** — 终端用起来像原生 App
- **Quick Terminal** — 全局快捷键从屏幕顶部滑出，随叫随到
- **合理的默认值** — 开箱即用，配置简洁不折腾

### 安装

```bash
# macOS（推荐）
brew install ghostty

# Linux（从源码构建）
git clone https://github.com/ghostty-org/ghostty.git
cd ghostty
zig build -Doptimize=ReleaseFast
```

> **字体推荐**：安装 [Maple Mono NF CN](https://github.com/subframe7536/maple-font)，中英文等宽、内置 Nerd Font 图标，与 Yazi/Lazygit 完美配合。

### 配置详解

配置文件路径：`~/.config/ghostty/config`

```ini
# --- 字体 ---
font-family = "Maple Mono NF CN"
font-size = 14
adjust-cell-height = 2          # 增加行高，阅读更舒适

# --- 主题与颜色 ---
theme = Catppuccin Mocha        # 低对比深色主题，长时间编码护眼

# --- 窗口外观 ---
background-opacity = 0.85       # 轻微透明，保留上下文感知
background-blur-radius = 30     # 毛玻璃效果
macos-titlebar-style = transparent
window-padding-x = 10
window-padding-y = 8
window-save-state = always      # 重启后恢复窗口状态
window-theme = auto

# --- 光标 ---
cursor-style = bar
cursor-style-blink = true
cursor-opacity = 0.8

# --- 鼠标 ---
mouse-hide-while-typing = true  # 打字时自动隐藏鼠标
copy-on-select = clipboard      # 选中即复制

# --- Quick Terminal（全局下拉终端）---
quick-terminal-position = top   # 从屏幕顶部滑入
quick-terminal-screen = mouse   # 出现在鼠标所在屏幕
quick-terminal-autohide = true  # 失去焦点自动隐藏
quick-terminal-animation-duration = 0.15

# --- 安全 ---
clipboard-paste-protection = true
clipboard-paste-bracketed-safe = true

# --- Shell 集成 ---
shell-integration = zsh

# --- Claude 专属优化 ---
# initial-command = /opt/homebrew/bin/claude  # 安装 claude-code 后取消注释
initial-window = true
quit-after-last-window-closed = true
notify-on-command-finish = always   # 命令完成后系统通知，让 Claude 跑着你去喝茶

# --- 性能 ---
scrollback-limit = 25000000     # 大滚动缓冲，Claude 的长输出不丢失

# --- 分屏快捷键 ---
keybind = cmd+d=new_split:right
keybind = cmd+shift+enter=toggle_split_zoom
keybind = cmd+shift+f=toggle_split_zoom
```

### 三面板驾驶舱布局

这是你每天使用的核心布局：

```
┌─────────────────────────────────┬───────────────────┐
│                                 │                   │
│                                 │   Yazi            │
│   Claude Code                   │   文件浏览器       │
│   （主面板）                     │                   │
│                                 ├───────────────────┤
│                                 │                   │
│                                 │   Lazygit         │
│                                 │   Git 管理         │
│                                 │                   │
└─────────────────────────────────┴───────────────────┘
```

**3 秒搭建驾驶舱：**

1. 打开 Ghostty → 当前在主面板
2. `⌘+D` → 右侧分屏 → 运行 `yazi .`
3. 在右侧面板按 `⌘+D` → 再次右下分屏 → 运行 `lazygit`
4. `⌘+[` → 跳回主面板 → 运行 `claude`

驾驶舱就绪，所有面板一个快捷键即达。

---

## 二、Yazi：你对文件系统的眼睛

### 为什么是 Yazi？

Claude Code 修改文件、创建新模块、重组目录结构时，你需要**实时看到发生了什么**。[Yazi](https://yazi-rs.github.io/) 是用 Rust 编写的终端文件管理器，提供：

- **实时文件浏览** — 以思维速度游走项目目录树
- **内置文件预览** — 代码语法高亮、图片、PDF，全在终端里
- **批量操作** — 当 Claude 的建议需要手动微调时，快速重命名、移动、删除
- **标签页 & 书签** — 在多个项目目录间瞬间跳转
- **zoxide 集成** — 智能目录跳转，`z proj` 直达常用目录

### 安装

```bash
# macOS（一次搞定所有依赖）
brew install yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide bat imagemagick

# Arch Linux
pacman -S yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide bat imagemagick

# 通用（Cargo）
cargo install --locked yazi-fm yazi-cli
```

### 配置

`~/.config/yazi/yazi.toml`：

```toml
[manager]
ratio          = [1, 3, 4]   # 左栏(目录树) : 中栏(文件列表) : 右栏(预览)
sort_by        = "natural"
sort_dir_first = true
show_hidden    = true        # 显示隐藏文件，.git 目录清晰可见

[preview]
max_width  = 1200
max_height = 900

[opener]
edit = [
  { run = 'nvim "$@"', block = true, for = "unix" },
]
```

`~/.config/yazi/keymap.toml`（自定义快捷跳转）：

```toml
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
```

### 与 Claude Code 的协作场景

**场景一：Claude 重构模块**

1. 你说：*"把 auth 模块拆分成按策略分开的文件"*
2. Claude 创建 `auth/local.ts`、`auth/oauth.ts`、`auth/jwt.ts`
3. Yazi 面板自动刷新，新文件树立刻出现
4. 在右侧预览面板浏览每个文件的内容
5. 发现问题：*"jwt.ts 里缺少 refresh token 的逻辑"*

**场景二：探索陌生代码库**

1. 在项目根目录打开 Yazi
2. 按 `/` 按文件名搜索
3. 按 `Enter` 预览任意文件（带语法高亮）
4. 用 `z` 借助 zoxide 跳转到常用目录
5. 把上下文喂给 Claude：*"看一下 src/core/engine.rs 第 45 行的 trait bounds，感觉有问题"*

**核心快捷键：**

| 按键 | 功能 |
|------|------|
| `h / l` | 进入父目录 / 子目录 |
| `j / k` | 上下移动 |
| `Space` | 多选文件 |
| `y` | 复制文件路径（粘贴给 Claude！） |
| `/` | 搜索文件名 |
| `z` | zoxide 智能跳转 |
| `.` | 切换隐藏文件显示 |
| `Tab` | 切换标签页 |
| `r` | 刷新当前目录 |

---

## 三、Lazygit：不切换上下文的版本控制

### 为什么是 Lazygit？

Claude Code 会写大量代码。你需要理解改了什么、选择性地暂存、写有意义的提交，偶尔还要回滚。[Lazygit](https://github.com/jesseduffield/lazygit) 在终端内提供完整的 Git GUI：

- **可视化 diff** — 逐行看清 Claude 改了什么
- **交互式暂存** — 暂存单个 hunk 甚至单行，不必整文件
- **分支管理** — 为 Claude 的实验创建独立分支
- **冲突解决** — 可视化 merge 冲突解决器
- **单键操作** — 提交、push、pull、stash、rebase，全是一个键

### 安装

```bash
# macOS
brew install lazygit

# Arch Linux
pacman -S lazygit

# 通用（Go）
go install github.com/jesseduffield/lazygit@latest
```

### 配置

`~/.config/lazygit/config.yml`：

```yaml
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
    pager: delta --dark --paging=never   # 需要安装 git-delta
  autoFetch: true
  autoRefresh: true
  branchLogCmd: "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --"

os:
  editPreset: "nvim"

keybinding:
  universal:
    quit: "q"
    return: "<esc>"
```

> **强烈推荐**：安装 [delta](https://github.com/dandavison/delta)（`brew install git-delta`），让 Lazygit 内的 diff 变成带行号、双栏对比的美观视图。

### 与 Claude Code 的协作场景

**场景一：提交前复查 Claude 的改动**

1. Claude 完成任务：*"好了，我更新了 7 个文件，实现了缓存层。"*
2. 切换到 Lazygit 面板
3. 按 `2` 跳到 Files 面板
4. 逐文件浏览，按 `Enter` 查看 diff
5. 按 `Space` 暂存认可的文件，按 `a` 暂存单个 hunk
6. 按 `c` 填写提交信息

**场景二：为 Claude 创建实验分支**

1. 在 Lazygit 按 `3` 打开 Branches 面板
2. 按 `n` 创建新分支：`experiment/claude-cache-v2`
3. 切回 Claude：*"继续，用更激进的优化方案试试"*
4. 结果好 → merge；结果差 → `d` 删掉分支，换策略

**场景三：撤销 Claude 的失误**

1. Claude 的改动导致测试挂了
2. 在 Lazygit 找到对应提交
3. 按 `d` → `r` revert 提交
4. 或直接按 `z` 撤销最近一次 Git 操作
5. 告诉 Claude：*"那个方案搞挂了 API 测试，换个思路"*

**核心快捷键：**

| 按键 | 功能 |
|------|------|
| `1-5` | 切换面板（Status/Files/Branches/Commits/Stash） |
| `Space` | 暂存 / 取消暂存文件 |
| `a` | 暂存所有 / 暂存 hunk |
| `c` | 提交 |
| `P` | Push |
| `p` | Pull |
| `z` | 撤销上一次操作 |
| `Enter` | 查看 diff / 展开 |
| `n` | 新建分支 |
| `x` | 打开操作菜单 |
| `?` | 显示所有快捷键 |

---

## 四、完整工作流实战

### 启动驾驶舱（30 秒）

打开 Ghostty，然后：

```
主面板：claude
⌘+D 分屏 → 右上面板：yazi .
⌘+D 再分屏 → 右下面板：lazygit
⌘+[ 跳回主面板
```

### 实战案例：给项目添加 REST API 端点

**第一步：给 Claude 下任务**

```
你：添加一个 GET /api/v1/users/:id 接口，要有参数校验、
    错误处理和测试。参照现有接口的写法。
```

**第二步：在 Yazi 里监控（右上面板）**

盯着文件树，看新文件冒出来：
- `src/routes/users.ts` — 路由处理器
- `src/validators/users.ts` — 校验 schema
- `tests/routes/users.test.ts` — 测试文件
- `src/types/user.ts` — 类型定义

Claude 每创建一个文件，Yazi 就刷新一次，实时预览内容。

**第三步：在 Lazygit 里复查（右下面板）**

- 看所有被修改/新建的文件
- 对每个文件做 diff，理解变更
- 确认没有意外修改的文件

**第四步：和 Claude 迭代**

```
你：接口看起来不错，但我在 Yazi 里发现你没更新路由索引文件。
    另外 Lazygit 的 diff 显示你改了数据库配置，是故意的吗？

Claude：两点都说得对。路由索引我来补上……
        数据库配置那里是为新接口加了连接池参数，我加个注释说明一下。
```

**第五步：提交**

在 Lazygit 里：
1. 暂存相关文件
2. 提交：`feat(api): 添加 GET /users/:id 接口及参数校验`
3. Push 到远端

**上下文切换次数：零。** 一切发生在同一个 Ghostty 窗口里。

---

## 五、高阶技巧

### 技巧一：git-claude-flow — Claude 的 Git 工作流增强

[git-claude-flow](https://github.com/iliYF/git-claude-flow) 是专为 Claude Code 设计的 Git 工作流工具，以 user 模式安装：

```bash
claude mcp add --transport http \
  git-claude-flow \
  https://git-claude-flow.vercel.app/mcp \
  --scope user
```

与 Lazygit 配合使用：Claude 通过 git-claude-flow 管理分支和提交策略，你在 Lazygit 里实时看到操作结果并做最终审核。

### 技巧二：Yazi → Claude 文件路径传递

在 Yazi 里找到感兴趣的文件：

1. 按 `y` yanks（复制）文件的绝对路径
2. 切换到 Claude 面板粘贴
3. 精确告诉 Claude：*"看一下 `/src/core/parser.rs`，第 89 行的 lifetime 标注有问题"*

### 技巧三：实验分支命名规范

与 Claude 合作时，建议用统一的分支命名：

```
feat/claude-<功能名>        # Claude 实现的新功能
fix/claude-<问题描述>        # Claude 修复的 Bug
refactor/claude-<模块名>     # Claude 主导的重构
exp/claude-<方案名>-v<版本>  # 探索性实验，可能被丢弃
```

这样在 `git log` 里一眼就能区分哪些是 AI 协作的改动。

### 技巧四：notify-on-command-finish 的妙用

Ghostty 的 `notify-on-command-finish = always` 配合 Claude Code 极其好用：

- 让 Claude 跑长任务（跑测试、构建、数据处理）
- 切到其他窗口做别的事
- 任务完成时收到系统通知
- 回来查看结果，继续迭代

### 技巧五：用 Git Worktree 跑并行实验

在 Lazygit 里（按 `w` 管理 worktree）：

1. 为每个方案创建独立的 worktree
2. 在不同 Ghostty 窗口各开一个 Claude 会话
3. 两个方案同时跑
4. 对比结果，保留赢家，`d` 删掉输家

---

## 六、方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| **VS Code + 终端** | 熟悉、插件丰富 | 重量级，编辑器和终端间频繁切换 |
| **tmux + vim** | 强大、可脚本化 | 学习曲线陡，配置复杂 |
| **Ghostty + Yazi + Lazygit** | 快速、可视、全键盘、配置简洁 | 需要熟悉三个工具 |
| **IDE + AI 插件** | 集成度高 | 响应慢、限制多、Claude Code 功能受限 |

Claude Companion 找到了最佳平衡点：**够可视以至于实用，够终端以至于快速，够简洁以至于不碍事。**

---

## 七、常见问题

### Ghostty 分屏快捷键没反应

确认没有在 tmux 里运行 Ghostty（tmux 会拦截快捷键）。两者选其一，不要套娃。

### Yazi 预览没有语法高亮

安装 `bat`：

```bash
brew install bat
```

### Lazygit diff 太丑

安装 `delta`：

```bash
brew install git-delta
```

在 `~/.gitconfig` 里配置：

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    line-numbers = true
    theme = "Catppuccin Mocha"
```

### 大型仓库下速度慢？

这套工具天生为速度而生：
- **Ghostty**：GPU 渲染，输出多少都不卡
- **Yazi**：Rust 实现，10 万文件的目录瞬间加载
- **Lazygit**：增量 diff 加载，不做全量扫描

---

## 结语

最好的开发环境是那种**让你忘记它存在**的环境。你不会去想 Ghostty——你想的是代码。你不会去操作 Yazi——你在**看**项目。你不会去对抗 Lazygit——你在**理解**变更。

当 Claude Code 在这个驾驶舱里运作，你对 AI 正在对你代码库做什么保持**全局感知**：实时验证改动、提早发现问题、更快迭代。

配置花 10 分钟。收益是永久的。

```
Ghostty  是框架
Yazi     是眼睛
Lazygit  是记忆
Claude   是大脑
```

---

## 参考资料

- [Terminal Power Trio: Ghostty + Yazi + Lazygit for Efficient Development](https://dev.to/wonderlab/terminal-power-trio-ghostty-yazi-lazygit-for-efficient-development-3iop)
- [2026 年 macOS 最快终端 Ghostty：安装、美化、配置一篇搞定](https://www.ypplog.cn/ghostty-macos-terminal-2026/)
- [花 10 分钟，把终端打造成「生产力武器」：Ghostty + Yazi + Lazygit 配置全流程](https://x.com/moon_kites/status/2026507603652784624)
- [git-claude-flow](https://github.com/iliYF/git-claude-flow)

---

*本项目使用 Claude Companion 构建。所有文件由 Claude Code 编写，在 Yazi 里浏览，通过 Lazygit 提交——全程在一个 Ghostty 窗口内完成。*
