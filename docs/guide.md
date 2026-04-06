# Claude Companion: Ghostty + Yazi + Lazygit for Efficient Development

> Build a terminal-native development environment that turns Claude Code from a tool into a teammate.

## Why This Stack?

Claude Code lives in the terminal. That's not a limitation — it's a superpower, **if** your terminal environment is built for it.

Most developers drop Claude Code into a default terminal and call it a day. They alt-tab between file explorers, git GUIs, and browser tabs, losing context with every switch. The friction is real: you ask Claude to refactor a module, but you can't quickly browse the file tree to verify the changes. You review a diff in one window while Claude's output scrolls away in another.

**The Claude Companion stack eliminates this friction entirely:**

| Tool | Role | Why It Matters |
|------|------|----------------|
| **Ghostty** | GPU-accelerated terminal | Native splits, zero-lag rendering, keeps multiple panes alive |
| **Yazi** | Terminal file manager | Blazing-fast file browsing with preview — your eyes on the filesystem |
| **Lazygit** | Terminal git UI | Stage, commit, diff, rebase — all without leaving the terminal |

Together, they form a **three-pane cockpit** where Claude Code operates in one pane, you browse files in another, and manage git in a third — all within a single Ghostty window, all keyboard-driven, all instantaneous.

---

## 1. Ghostty: The Foundation

### Why Ghostty?

[Ghostty](https://ghostty.org/) is a terminal emulator built by Mitchell Hashimoto (of HashiCorp fame). It matters for this workflow because of:

- **Native splits** — no tmux needed (though it works with tmux too)
- **GPU-accelerated rendering** — Claude's verbose output never causes lag
- **Sub-millisecond input latency** — the terminal feels like a native app
- **Minimal config** — sane defaults that stay out of your way

### Installation

```bash
# macOS
brew install ghostty

# Linux (build from source)
git clone https://github.com/ghostty-org/ghostty.git
cd ghostty
zig build -Doptimize=ReleaseFast
```

### Configuration

Create `~/.config/ghostty/config`:

```ini
# === Font ===
font-family = "JetBrains Mono"
font-size = 14

# === Theme ===
# A low-contrast dark theme reduces eye strain during long coding sessions
theme = catppuccin-mocha

# === Window ===
window-padding-x = 8
window-padding-y = 4
window-decoration = false
macos-titlebar-style = hidden

# === Behavior ===
copy-on-select = clipboard
confirm-close-surface = false
mouse-hide-while-typing = true

# === Keybindings for Splits ===
# These are the keys that let you fly between panes
keybind = super+d=new_split:right
keybind = super+shift+d=new_split:down
keybind = super+alt+left=goto_split:left
keybind = super+alt+right=goto_split:right
keybind = super+alt+up=goto_split:up
keybind = super+alt+down=goto_split:down
keybind = super+w=close_surface
```

### The Three-Pane Layout

This is the core layout you'll use every day:

```
┌─────────────────────────────┬──────────────────┐
│                             │                  │
│                             │   Yazi           │
│   Claude Code               │   (file browser) │
│   (main pane)               │                  │
│                             ├──────────────────┤
│                             │                  │
│                             │   Lazygit        │
│                             │   (git UI)       │
│                             │                  │
└─────────────────────────────┴──────────────────┘
```

**Setup sequence** (takes 3 seconds):

1. Open Ghostty → you're in the main pane
2. `⌘+D` → split right → launch `yazi`
3. `⌘+Shift+D` → split down (in the right pane) → launch `lazygit`
4. `⌘+Alt+Left` → jump back to the main pane → launch `claude`

You now have a full development cockpit. Every pane is one keybinding away.

---

## 2. Yazi: Your Eyes on the Filesystem

### Why Yazi?

When Claude Code edits files, creates new modules, or restructures directories, you need to **see** what happened — instantly. [Yazi](https://yazi-rs.github.io/) is a terminal file manager written in Rust that gives you:

- **Real-time file browsing** — navigate your project tree at the speed of thought
- **Built-in file preview** — syntax-highlighted code, images, PDFs, all in the terminal
- **Bulk operations** — rename, move, delete files when Claude's suggestions need manual tweaks
- **Bookmarks & tabs** — jump between project directories instantly

### Installation

```bash
# macOS
brew install yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font

# Arch Linux
pacman -S yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide imagemagick

# Cargo (universal)
cargo install --locked yazi-fm yazi-cli
```

### Configuration

Create `~/.config/yazi/yazi.toml`:

```toml
[manager]
ratio = [1, 3, 4]        # directory tree : file list : preview
sort_by = "natural"
sort_dir_first = true
show_hidden = true

[preview]
max_width = 1000
max_height = 1000

[opener]
edit = [
    { run = 'nvim "$@"', block = true, for = "unix" },
]

[plugin]
prepend_previewers = [
    { name = "*.md",  run = "glow" },
    { name = "*.json", run = "jq" },
]
```

Create `~/.config/yazi/keymap.toml` (essential shortcuts):

```toml
[[manager.prepend_keymap]]
on   = ["g", "r"]
run  = "cd ~/CodeHub"
desc = "Go to code repository root"

[[manager.prepend_keymap]]
on   = ["g", "c"]
run  = "cd ~/.config"
desc = "Go to config directory"
```

### Workflow with Claude Code

Here's where Yazi becomes indispensable:

**Scenario: Claude refactors a module**

1. You tell Claude: *"Refactor the auth module into separate files for each strategy"*
2. Claude creates `auth/local.ts`, `auth/oauth.ts`, `auth/jwt.ts`
3. In the Yazi pane, press `r` to refresh — you instantly see the new file tree
4. Navigate to each file, preview the contents in the right panel
5. If something looks off, you tell Claude: *"The jwt.ts file is missing the refresh token logic"*

**Scenario: Exploring an unfamiliar codebase**

1. Open Yazi in the project root
2. Use `/` to search for files by name
3. Press `Enter` to preview any file with syntax highlighting
4. Use `z` (zoxide integration) to jump to frequently visited directories
5. Feed context to Claude: *"Look at src/core/engine.rs — the trait bounds on line 45 seem wrong"*

**Key Yazi shortcuts to memorize:**

| Key | Action |
|-----|--------|
| `h/l` | Navigate parent/child directory |
| `j/k` | Move up/down in file list |
| `Space` | Select file (for bulk operations) |
| `/` | Search files |
| `z` | Jump via zoxide |
| `w` | Manage tasks (copy/move progress) |
| `.` | Toggle hidden files |
| `Tab` | Switch to next tab |

---

## 3. Lazygit: Version Control Without Context Switching

### Why Lazygit?

Claude Code writes code. Sometimes a lot of code. You need to understand what changed, stage selectively, write meaningful commits, and occasionally revert. [Lazygit](https://github.com/jesseduffield/lazygit) gives you a full git GUI inside the terminal.

- **Visual diffs** — see exactly what Claude changed, line by line
- **Interactive staging** — stage individual hunks or lines, not just whole files
- **Branch management** — create feature branches for Claude experiments
- **Conflict resolution** — visual merge conflict resolver
- **One-key operations** — commit, push, pull, stash, rebase — all single keystrokes

### Installation

```bash
# macOS
brew install lazygit

# Arch Linux
pacman -S lazygit

# Go (universal)
go install github.com/jesseduffield/lazygit@latest
```

### Configuration

Create `~/.config/lazygit/config.yml`:

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
```

> **Tip**: Install [delta](https://github.com/dandavison/delta) (`brew install git-delta`) for beautiful side-by-side diffs inside Lazygit.

### Workflow with Claude Code

**Scenario: Reviewing Claude's changes before committing**

1. Claude finishes a task — *"Done. I've updated 7 files to implement the caching layer."*
2. Switch to the Lazygit pane (`⌘+Alt+Right` then `⌘+Alt+Down`)
3. Press `2` to jump to the Files panel
4. Navigate each file, press `Enter` to see the diff
5. Press `Space` to stage files you approve
6. Press `a` to stage individual hunks for partial changes
7. Press `c` to commit with a descriptive message

**Scenario: Creating an experimental branch for Claude**

1. In Lazygit, press `3` to go to the Branches panel
2. Press `n` to create a new branch: `experiment/claude-refactor`
3. Switch back to Claude: *"Go ahead and try the aggressive optimization approach"*
4. If it works → merge. If not → `d` to delete the branch and go back

**Scenario: Undoing Claude's mistakes**

1. Claude makes a change that breaks tests
2. In Lazygit, navigate to the commit
3. Press `d` → `r` to revert the commit
4. Or press `z` to undo the last git operation
5. Tell Claude: *"That approach broke the API tests. Let's try a different strategy."*

**Key Lazygit shortcuts to memorize:**

| Key | Action |
|-----|--------|
| `1-5` | Switch between panels (Status/Files/Branches/Commits/Stash) |
| `Space` | Stage/unstage file |
| `a` | Stage all / Stage hunk |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `z` | Undo last action |
| `Enter` | View diff / Expand |
| `/` | Search |
| `x` | Open action menu |
| `?` | Show all keybindings |

---

## 4. The Integrated Workflow

Now let's see how all three tools work together in a real development session.

### Session Start (30 seconds)

```bash
# Terminal 1: Open Ghostty and set up the cockpit
ghostty

# Split right, launch Yazi
# ⌘+D
yazi .

# Split the right pane down, launch Lazygit
# ⌘+Shift+D
lazygit

# Jump back to the main pane
# ⌘+Alt+Left

# Start Claude Code
claude
```

### Real-World Example: Adding a REST API Endpoint

**Step 1: Give Claude the task**

```
You: Add a GET /api/v1/users/:id endpoint with proper validation,
     error handling, and tests. Follow the patterns in the existing
     endpoints.
```

**Step 2: Monitor in Yazi** (right pane, top)

Watch as new files appear:
- `src/routes/users.ts` — new route handler
- `src/validators/users.ts` — validation schema
- `tests/routes/users.test.ts` — test file
- `src/types/user.ts` — type definitions

Preview each file as Claude creates it. Catch issues early.

**Step 3: Review in Lazygit** (right pane, bottom)

- See all modified/created files highlighted
- Diff each file to understand the changes
- Check that no unintended files were modified

**Step 4: Iterate with Claude**

```
You: The endpoint looks good, but I noticed in Yazi that you didn't
     update the route index file. Also, the diff in Lazygit shows
     you modified the database config — was that intentional?

Claude: You're right on both counts. Let me fix the route index...
        The database config change was to add the connection pool
        setting needed for the new endpoint. Let me add a comment
        explaining why.
```

**Step 5: Commit**

In Lazygit:
1. Stage the relevant files
2. Commit: `feat(api): add GET /users/:id endpoint with validation`
3. Push to remote

**Total context switches: zero.** Everything happened in one Ghostty window.

---

## 5. Power Tips

### Tip 1: Shell Aliases for Quick Setup

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Launch the full cockpit in one command
claude-dev() {
    local project_dir="${1:-.}"
    cd "$project_dir"
    echo "🚀 Starting Claude Companion..."
    echo "  → Split right (⌘+D) and run: yazi ."
    echo "  → Split down (⌘+Shift+D) and run: lazygit"
    echo "  → Jump back (⌘+Alt+Left) — Claude is ready"
    claude
}
```

### Tip 2: Yazi-to-Claude File Handoff

When you find an interesting file in Yazi, you can quickly reference it in Claude:

1. In Yazi, press `y` to yank (copy) the file path
2. Switch to the Claude pane
3. Paste the path: *"Look at `/src/core/engine.rs` — the error handling needs work"*

### Tip 3: Lazygit Commit Message Conventions

When working with Claude, adopt a commit prefix convention:

```
feat:     Claude-implemented feature
fix:      Claude-fixed bug  
refactor: Claude-driven refactoring
test:     Claude-written tests
```

This makes it easy to trace which changes were AI-assisted in `git log`.

### Tip 4: Watch Mode in Yazi

Yazi automatically refreshes the file list. When Claude is writing multiple files, you can watch the progress in real-time — files appear as they're created, sizes update as content is written.

### Tip 5: Git Worktrees for Parallel Experiments

Use Lazygit's worktree support to run parallel Claude experiments:

1. In Lazygit, press `w` to manage worktrees
2. Create a new worktree for each experimental approach
3. Run separate Claude sessions in each
4. Compare results, keep the winner

---

## 6. Comparison: Why This Stack Wins

| Approach | Pros | Cons |
|----------|------|------|
| **VS Code + Terminal** | Familiar, extensions | Heavy, context switching between editor and terminal |
| **tmux + vim** | Powerful, scriptable | Steep learning curve, complex config |
| **Ghostty + Yazi + Lazygit** | Fast, visual, keyboard-driven, minimal config | Requires learning three tools |
| **IDE with AI plugin** | Integrated | Slow, opinionated, limited Claude Code features |

The Claude Companion stack hits the sweet spot: **visual enough to be useful, terminal-native enough to be fast, and minimal enough to stay out of your way.**

---

## 7. Troubleshooting

### Ghostty splits not working

Make sure you're using Ghostty's native split keybindings, not tmux's. If you're inside tmux, Ghostty splits are intercepted by tmux. Choose one or the other.

### Yazi preview not showing syntax highlighting

Install `bat` for syntax highlighting in previews:

```bash
brew install bat
```

### Lazygit diff looks ugly

Install `delta` for beautiful diffs:

```bash
brew install git-delta
```

Add to `~/.gitconfig`:

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    line-numbers = true
```

### Performance with large repos

All three tools are built for speed:
- **Ghostty**: GPU rendering handles any output volume
- **Yazi**: Rust-based, handles 100k+ files
- **Lazygit**: Incremental diff loading, no full repo scan

---

## Conclusion

The best development environment is the one that **disappears**. You don't think about Ghostty — you think about the code. You don't operate Yazi — you *see* the project. You don't fight Lazygit — you *understand* the changes.

When Claude Code operates inside this cockpit, you maintain **full situational awareness** of what the AI is doing to your codebase. You can verify changes in real-time, catch mistakes early, and iterate faster.

The setup takes 10 minutes. The productivity gain lasts forever.

```
Ghostty for the frame.
Yazi for the eyes.
Lazygit for the memory.
Claude Code for the brain.
```

---

*Built with the Claude Companion stack. Every file in this project was written with Claude Code, browsed in Yazi, and committed through Lazygit — all inside a single Ghostty window.*
