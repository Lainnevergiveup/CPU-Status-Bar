import AppKit

final class ProcessMenuItemView: NSView {
    var onTerminate: (() -> Void)?

    private let nameField: NSTextField
    private let valueField: NSTextField
    private let closeButton: NSButton

    static let itemWidth: CGFloat = 280
    static let itemHeight: CGFloat = 22

    init(name: String, value: String) {
        let frame = NSRect(x: 0, y: 0, width: Self.itemWidth, height: Self.itemHeight)
        let displayName = name.count > 22 ? String(name.prefix(19)) + "..." : name

        // Left-aligned name
        nameField = NSTextField(labelWithString: displayName)
        nameField.font = .systemFont(ofSize: NSFont.systemFontSize)
        nameField.lineBreakMode = .byTruncatingTail
        nameField.maximumNumberOfLines = 1
        nameField.drawsBackground = false
        nameField.isBezeled = false

        // Right-aligned value
        valueField = NSTextField(labelWithString: value)
        valueField.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        valueField.alignment = .right
        valueField.maximumNumberOfLines = 1
        valueField.drawsBackground = false
        valueField.isBezeled = false

        // Small close button
        closeButton = NSButton(frame: .zero)
        closeButton.title = "✕"
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.font = NSFont.systemFont(ofSize: 9)
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = nil
        closeButton.action = #selector(ProcessMenuItemView.closeClicked)

        super.init(frame: frame)

        let margin: CGFloat = 12
        let btnW: CGFloat = 14
        let btnMargin: CGFloat = 4
        let valueW: CGFloat = 105
        let nameW: CGFloat = frame.width - margin - valueW - btnMargin - btnW - margin
        // nameW ≈ 280 - 12 - 105 - 4 - 14 - 8 = 137

        nameField.frame = NSRect(x: margin, y: 0, width: nameW, height: frame.height)

        let valueX = frame.width - margin - btnMargin - btnW - valueW
        valueField.frame = NSRect(x: valueX, y: 0, width: valueW, height: frame.height)

        let btnX = frame.width - margin - btnW
        closeButton.frame = NSRect(x: btnX, y: (frame.height - btnW) / 2, width: btnW, height: btnW)

        addSubview(nameField)
        addSubview(valueField)
        addSubview(closeButton)

        closeButton.target = self
        toolTip = "右键或点击 ✕ 强制关闭 \(name)"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Actions

    @objc private func closeClicked() {
        onTerminate?()
    }

    override func rightMouseUp(with event: NSEvent) {
        onTerminate?()
    }
}
