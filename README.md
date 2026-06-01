# SysMonitor

A lightweight macOS menu bar app that displays real-time CPU and memory usage. Click to see top resource-consuming processes.

## Features

- **Live CPU & Memory** — 2-line display in the menu bar, refreshed every 2 seconds
- **Top Processes** — Click the status bar item to see top 3 CPU and top 3 memory consumers
- **No Dock icon** — Runs as a background agent (`LSUIElement`)
- **Low overhead** — Uses `host_statistics` / `vm_statistics64` kernel APIs directly

## Requirements

- macOS 13+
- Xcode Command Line Tools (or Swift 5.9+ toolchain)

## Build

```bash
# Debug build
swift build

# Release build → .build/SysMonitor.app
make build

# Release build → SysMonitor.app (in project root)
make dist
```

## Run

```bash
make run
```

Or drag `SysMonitor.app` (after `make dist`) into your Applications folder.

## Project Structure

```
Sources/cpu-status-bar/
├── main.swift              # App entry point
├── AppDelegate.swift       # Status bar, menu, timer
├── MonitorService.swift    # CPU & memory sampling via host_statistics
└── ProcessFetcher.swift    # Process list via ps, top-N ranking

Resources/
└── Info.plist              # LSUIElement, bundle metadata
```

## License

MIT
