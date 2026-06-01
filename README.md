# 🖥️ CPU Status Bar

> 一款专为 macOS 设计的轻量级状态栏系统监视器，实时掌握性能与功耗。

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/language-Swift%205.9-orange?logo=swift" alt="Language">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

---

## ✨ 功能特点

- ⚡ **轻量常驻** — 无 Dock 栏图标，纯后台常驻状态栏，极低资源占用。
- 📊 **实时监测** — 每 2 秒动态刷新 CPU 和内存使用百分比。
- 🔍 **智能排查** — 点击下拉菜单，一目了然当前最高占用的应用列表。
- 👔 **优雅对齐** — 智能截断过长应用名，完美支持系统暗黑/明亮模式切换。
- ❌ **快捷强杀** — 支持在菜单中右键 / 快捷关闭高占用 App，并带有防误触弹窗确认。
- 🔒 **单例保证** — 防止应用多开占满状态栏。

---

## 📋 开发环境

| 依赖 | 说明 |
|------|------|
| **macOS** | 13.0 (Ventura) 及以上 |
| **Swift** | 5.9+ |
| **Xcode Command Line Tools** | `xcode-select --install` |

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/Lainnevergiveup/CPU-Status-Bar.git
cd cpu-status-bar
```

### 2. 一键编译 & 运行

```bash
# 编译 Release 版本并启动
make run
```

### 3. 常用命令

```bash
# 仅编译（Release，产物位于 .build/CPU Status Bar.app）
make build

# 编译并打包到项目根目录 CPU Status Bar.app
make dist

# 清理编译产物
make clean
```

编译完成后，也可以直接将 `CPU Status Bar.app` 拖入 `/Applications` 文件夹，设为登录项即可开机自启。

---

## 🏗️ 项目结构

```
Sources/cpu-status-bar/
├── main.swift                  # 应用入口
├── AppDelegate.swift           # 状态栏控制器、菜单、刷新定时器
├── MonitorService.swift        # CPU / 内存采样（host_statistics / vm_statistics64）
├── ProcessFetcher.swift        # 进程列表获取与 Top-N 排序
└── ProcessMenuItemView.swift   # 自定义菜单项视图（应用名截断、强制退出按钮）

Resources/
└── Info.plist                  # LSUIElement = 1，无 Dock 栏图标
```

---

## 📄 开源协议

本项目基于 **MIT License** 开源，详见 [LICENSE](LICENSE) 文件。

---

<p align="center">Made with ❤️ for the macOS community</p>
