
[中文](README.md) | [English](README.en.md)

# Claude Companion

> One command. A terminal environment built for Claude Code.

![Claude Companion cockpit](term.png)

---

## Install

- Remote install
```bash
curl -fsSL https://raw.githubusercontent.com/iliYF/claude-cli-companion/main/install.sh | bash
```

- Remote install (interactive mode)
```
curl -fsSL https://raw.githubusercontent.com/iliYF/claude-cli-companion/main/install.sh | bash -s -- --interactive
```

- Remote install (auto mode)
```
curl -fsSL https://raw.githubusercontent.com/iliYF/claude-cli-companion/main/install.sh | bash -s -- --auto
```

Or clone and run locally:

```bash
git clone https://github.com/iliYF/claude-cli-companion.git
cd claude-companion
bash install.sh
```

### Install Modes

**Interactive mode** is for first-time installs, or when you want to customize tool aliases or skip certain components. The installer pauses and asks wherever a decision is needed.

**Auto mode** is for when you just want to get up and running fast. No interruptions — all options use sensible defaults and the install completes in minutes.

---

## Why Does This Project Exist?

Claude Code lives in the terminal, but most people pair it with a generic setup. They Alt+Tab between a file manager, a Git GUI, and an editor — losing context with every switch. **The tools are powerful. The gaps between them are where you bleed.** Claude Companion puts everything in one cockpit and closes those gaps.

---

### Full Situational Awareness

A three-pane cockpit: Claude Code works on the left, Yazi shows live filesystem changes on the top right, Lazygit tracks every line of code on the bottom right. One shortcut to switch panes — you always know what Claude is doing.

### Catch Problems Early

In a traditional workflow, you wait for Claude to finish — then discover it went sideways. In this cockpit, you **see** new files appearing in Yazi and **watch** the diff growing in Lazygit as it happens. Something looks wrong? Interrupt immediately, correct course, instead of untangling it at the end.

### Keyboard-Driven, Never Leave the Terminal

Ghostty's native splits, Yazi's Vim-style navigation, Lazygit's single-key operations — the entire workflow is keyboard-driven. Your hands never leave the keyboard. Your focus never leaves the terminal. Context stays intact.

### Configs Tuned for Claude Code Collaboration

None of these configs are generic defaults — every setting was considered with Claude Code in mind:

- **Ghostty**: Massive scroll buffer (25M lines) to preserve Claude's full output; command completion notifications so you know when a long task finishes; frosted glass and Catppuccin theme for comfortable long sessions
- **Yazi**: Auto-refreshing file list, syntax-highlighted previews, zoxide quick-jump — browsing code Claude touched feels effortless
- **Lazygit**: delta-rendered diffs, line-by-line staging, one-key revert — when Claude gets it wrong, you're back in three seconds

### One Command Sets Everything Up

No manually configuring each tool. No hunting through docs to compare options. No "I installed the font but the icons don't show" rabbit hole.

---

## Tool Roles

| Tool | Role | Why this one |
|------|------|--------------|
| **Ghostty** | GPU-accelerated terminal, provides the split-pane frame | Native splits without tmux, zero-latency rendering, handles Claude's heavy output without stuttering |
| **Yazi** | The eyes of the filesystem | Written in Rust, blazing fast, real-time file preview — see exactly what Claude is doing on disk |
| **Lazygit** | Version control memory | Visual diffs, line-level staging, easy revert — review and roll back every change Claude makes |

---

## What Gets Installed

| Component | Purpose | Required |
|-----------|---------|----------|
| **Ghostty config** | Split-pane layout, theme, keybindings | ✅ |
| **JetBrainsMono Nerd Font** | Icon-capable monospace font for the full stack | ✅ |
| **Starship** | Cross-shell prompt with git and Claude context | Optional |
| **Yazi** | Terminal file manager — browse files Claude creates in real time | ✅ |
| **Lazygit** | Terminal git UI — review and commit Claude's changes | ✅ |
| **git-delta** | Beautiful diffs inside Lazygit | Optional (dev tools) |
| **git-claude-flow** | Git workflow helper optimized for Claude Code sessions | Optional |
| **Dev tools** | `bat`, `fd`, `ripgrep`, `fzf`, `zoxide` — Yazi enhancements | Optional |

---

## Auto Mode Defaults

| Prompt | Default |
|--------|---------|
| Enable Starship | Yes |
| Optional dev tools | Skip |
| Lazygit shell alias | First available (`lg` → `lzg` → `lazygit`) |
| Install git-claude-flow | Yes |
| gcf alias | `claude` |
| gcf command | `claude` |

---

## After Install

Open Ghostty and set up the three-pane cockpit:

1. `⌘+D` — split right → run `yazi .`
2. `⌘+Shift+D` — split the right pane down → run `lazygit`
3. `⌘+Alt+Left` — jump back to the main pane → run `claude`

Every pane is one shortcut away. No context switching. Full situational awareness.

---

## Related

- [Ghostty](https://ghostty.org/) — GPU-accelerated terminal emulator
- [Yazi](https://yazi-rs.github.io/) — Blazing-fast terminal file manager
- [Lazygit](https://github.com/jesseduffield/lazygit) — Terminal UI for git
- [git-claude-flow](https://github.com/yili/git-claude-flow) — Git workflow CLI for Claude Code sessions

---
