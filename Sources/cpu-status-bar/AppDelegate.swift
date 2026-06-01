import AppKit

private let kMenuTabStop: CGFloat = 190

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let monitor = MonitorService()
    private let fetcher = ProcessFetcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
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
        let item = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func populateMenu(_ menu: NSMenu, with processes: ProcessList) {
        clearDynamicItems(from: menu)

        // ── Top CPU ──
        let cpuHeader = NSMenuItem(title: "Top CPU", action: nil, keyEquivalent: "")
        cpuHeader.isEnabled = false
        menu.addItem(cpuHeader)

        if processes.topCPU.isEmpty {
            addPlaceholder(to: menu, text: "No data")
        } else {
            for p in processes.topCPU {
                menu.addItem(makeMenuRow(name: p.name, value: String(format: "%.1f%%", p.cpu)))
            }
        }

        menu.addItem(NSMenuItem.separator())

        // ── Top Memory ──
        let memHeader = NSMenuItem(title: "Top Memory", action: nil, keyEquivalent: "")
        memHeader.isEnabled = false
        menu.addItem(memHeader)

        if processes.topMemory.isEmpty {
            addPlaceholder(to: menu, text: "No data")
        } else {
            for p in processes.topMemory {
                let value = String(format: "%.1f%% / %@", p.mem, p.rssFormatted)
                menu.addItem(makeMenuRow(name: p.name, value: value))
            }
        }
    }

    private func addPlaceholder(to menu: NSMenu, text: String) {
        let item = NSMenuItem(title: "  \(text)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func makeMenuRow(name: String, value: String) -> NSMenuItem {
        let ps = NSMutableParagraphStyle()
        ps.tabStops = [NSTextTab(textAlignment: .right, location: kMenuTabStop, options: [:])]

        let attrStr = NSAttributedString(
            string: "  \(name)\t\(value)",
            attributes: [.paragraphStyle: ps]
        )

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.attributedTitle = attrStr
        item.isEnabled = false
        return item
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
        let cpuStr = String(format: "CPU: %.0f%%", cpu) as NSString
        let memStr = String(format: "Mem: %.0f%%", mem) as NSString

        let cpuSize = cpuStr.size(withAttributes: [.font: font])
        let memSize = memStr.size(withAttributes: [.font: font])
        let imgWidth = ceil(max(cpuSize.width, memSize.width))

        let thickness = NSStatusBar.system.thickness
        let fontHeight = font.ascender - font.descender
        let totalTextH = fontHeight * 2
        let imgHeight = max(thickness, ceil(totalTextH))

        let image = NSImage(size: NSSize(width: imgWidth, height: imgHeight))
        image.isTemplate = false

        image.lockFocus()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.controlTextColor
        ]

        let topY = imgHeight - (imgHeight - totalTextH) / 2 - fontHeight
        let bottomY = (imgHeight - totalTextH) / 2

        cpuStr.draw(at: NSPoint(x: (imgWidth - cpuSize.width) / 2, y: topY), withAttributes: attrs)
        memStr.draw(at: NSPoint(x: (imgWidth - memSize.width) / 2, y: bottomY), withAttributes: attrs)

        image.unlockFocus()
        return image
    }
}
