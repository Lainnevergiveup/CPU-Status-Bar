// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cpu-status-bar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "cpu-status-bar",
            path: "Sources/cpu-status-bar"
        )
    ]
)
