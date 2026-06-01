import AppKit
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let monitor = MonitorService()
    private let fetcher = ProcessFetcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isAlreadyRunning() else {
            NSApp.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "退出应用", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.addItem(NSMenuItem.separator())
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
        updateStats()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    // MARK: - Single instance

    private func isAlreadyRunning() -> Bool {
        let currentPid = ProcessInfo.processInfo.processIdentifier
        let bundleId = Bundle.main.bundleIdentifier ?? "com.lain.cpu-status-bar"
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        return apps.contains(where: { $0.processIdentifier != currentPid })
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        clearDynamicItems(from: menu)
        addLoadingItem(to: menu)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let processes = self.fetcher.fetch()
            DispatchQueue.main.async {
                self.populateMenu(menu, with: processes)
            }
        }
    }

    // MARK: - Menu building

    private func clearDynamicItems(from menu: NSMenu) {
        while menu.items.count > 2 {
            menu.removeItem(at: 2)
        }
    }

    private func addLoadingItem(to menu: NSMenu) {
        let item = NSMenuItem(title: "加载中...", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func populateMenu(_ menu: NSMenu, with processes: ProcessList) {
        clearDynamicItems(from: menu)

        // ── Top CPU ──
        let cpuHeader = NSMenuItem(title: "CPU 占用最高", action: nil, keyEquivalent: "")
        cpuHeader.isEnabled = false
        menu.addItem(cpuHeader)

        if processes.topCPU.isEmpty {
            addPlaceholder(to: menu, text: "暂无数据")
        } else {
            for p in processes.topCPU {
                addProcessItem(to: menu, process: p, showCPU: true)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // ── Top Memory ──
        let memHeader = NSMenuItem(title: "内存占用最高", action: nil, keyEquivalent: "")
        memHeader.isEnabled = false
        menu.addItem(memHeader)

        if processes.topMemory.isEmpty {
            addPlaceholder(to: menu, text: "暂无数据")
        } else {
            for p in processes.topMemory {
                let value = String(format: "%.1f%% / %@", p.mem, p.rssFormatted)
                addProcessItem(to: menu, process: p, showCPU: false, customValue: value)
            }
        }

        // ── Hint ──
        menu.addItem(NSMenuItem.separator())
        let hint = NSMenuItem(title: "点击 ✕ 或右键强制关闭应用", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        hint.attributedTitle = NSAttributedString(
            string: "点击 ✕ 或右键强制关闭应用",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(hint)
    }

    private func addProcessItem(to menu: NSMenu, process: AppProcess, showCPU: Bool, customValue: String? = nil) {
        let value: String
        if let customValue {
            value = customValue
        } else {
            value = String(format: "%.1f%%", process.cpu)
        }

        let view = ProcessMenuItemView(name: process.name, value: value)
        view.onTerminate = { [weak self] in
            self?.confirmAndTerminate(name: process.name, pid: process.pid)
        }

        let item = NSMenuItem()
        item.view = view
        menu.addItem(item)
    }

    private func addPlaceholder(to menu: NSMenu, text: String) {
        let item = NSMenuItem(title: "  \(text)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    // MARK: - Termination

    private func confirmAndTerminate(name: String, pid: Int32) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "确认强制关闭 \(name)？"
            alert.informativeText = "这可能会导致未保存的数据丢失。"
            alert.addButton(withTitle: "强制关闭")
            alert.addButton(withTitle: "取消")
            alert.alertStyle = .warning

            if alert.runModal() == .alertFirstButtonReturn {
                if let app = NSRunningApplication(processIdentifier: pid) {
                    app.forceTerminate()
                } else {
                    kill(pid, SIGTERM)
                }
            }
        }
    }

    // MARK: - Status bar

    private func updateStats() {
        let cpu = monitor.sampleCPU()
        let mem = monitor.sampleMemory()
        statusItem.button?.image = makeStatusImage(cpu: cpu, mem: mem)
        statusItem.button?.imagePosition = .imageOnly
    }

    private func makeStatusImage(cpu: Double, mem: Double) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        let cpuStr = String(format: "CPU %.0f%%", cpu) as NSString
        let memStr = String(format: "内存 %.0f%%", mem) as NSString

        let cpuSize = cpuStr.size(withAttributes: [.font: font])
        let memSize = memStr.size(withAttributes: [.font: font])
        let imgWidth = ceil(max(cpuSize.width, memSize.width))

        let thickness = NSStatusBar.system.thickness
        let fontHeight = font.ascender - font.descender
        let totalTextH = fontHeight * 2
        let imgHeight = max(thickness, ceil(totalTextH))

        let image = NSImage(size: NSSize(width: imgWidth, height: imgHeight))
        image.isTemplate = true

        image.lockFocus()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]

        let topY = imgHeight - (imgHeight - totalTextH) / 2 - fontHeight
        let bottomY = (imgHeight - totalTextH) / 2

        cpuStr.draw(at: NSPoint(x: (imgWidth - cpuSize.width) / 2, y: topY), withAttributes: attrs)
        memStr.draw(at: NSPoint(x: (imgWidth - memSize.width) / 2, y: bottomY), withAttributes: attrs)

        image.unlockFocus()
        return image
    }
}
