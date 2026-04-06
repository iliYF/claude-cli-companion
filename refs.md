# 安装指南

## 安装过滤
### ghostty 安装

- Homebrew 安装  `Ghostty`
```
brew install --cask ghostty
```

- 加上彩虹状态栏（显示 Git、时间、CPU）
```
brew install starship
starship preset catppuccin-powerline -o ~/.config/starship.toml
```
然后在 ~/.zshrc 最底部添加：
```
if [ "$TERM_PROGRAM" = "ghostty" ]; then
    echo "Enable Starship for Ghostty"
    eval "$(starship init zsh)" # 如果用 bash，改为 bash
fi
```

- 字体安装
```
brew install --cask font-jetbrains-mono-nerd-font
```

- 其他工具
btop 颜值最高的系统监控，CPU、内存、GPU、进程、网速
glow 终端里直接预览 Markdown

### 安装yazi
```
brew install yazi
```

```
brew install ffmpegthumbnailer sevenzip jq poppler fd ripgrep fzf zoxide imagemagick
brew install yazi ffmpeg-full sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick-full font-symbols-only-nerd-font
```

```
eval "$(zoxide init zsh)"  # 添加到 ~/.zshrc
```

```
~/.config/yazi/yazi.toml
```

安装并设置主题
```
ya pkg add yazi-rs/flavors:catppuccin-mocha
ya pkg add yazi-rs/flavors:catppuccin-latte
```

Set the content of your `theme.toml` to enable it as your dark flavor:

~/.config/yazi/theme.toml

```
[flavor]
dark = "catppuccin-mocha"
light = "catppuccin-latte"
```

### 安装lazygit
```
brew install lazygit
```

```
brew install git-delta bat eza dust duf
```

设置配置
```
~/.config/lazygit/config.yml
```

设置别名 `lg`
```
echo 'alias lg="lazygit"' >> ~/.zshrc
source ~/.zshrc
```

- 加载配置
- 安装[git-claude-flow](https://github.com/iliYF/git-claude-flow) 使用user模式

## 参考借鉴:

[Terminal Power Trio: Ghostty + Yazi + Lazygit for Efficient Development](https://dev.to/wonderlab/terminal-power-trio-ghostty-yazi-lazygit-for-efficient-development-3iop)
[2026 年 macOS 最快终端 Ghostty：安装、美化、配置一篇搞定](https://www.ypplog.cn/ghostty-macos-terminal-2026/)
[花10 分钟时间，把终端打造成“生产力武器”：Ghostty + Yazi + Lazygit 配置全流程](https://x.com/moon_kites/status/2026507603652784624)