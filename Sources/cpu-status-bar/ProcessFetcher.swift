import Foundation

struct AppProcess {
    let name: String
    let cpu: Double
    let mem: Double
    let rss: UInt64

    var rssFormatted: String {
        let bytes = rss * 1024
        switch bytes {
        case 1_073_741_824...:
            return String(format: "%.1f GB", Double(bytes) / 1_073_741_824.0)
        case 1_048_576...:
            return String(format: "%.0f MB", Double(bytes) / 1_048_576.0)
        default:
            return String(format: "%.0f KB", Double(bytes) / 1_024.0)
        }
    }
}

struct ProcessList {
    let topCPU: [AppProcess]
    let topMemory: [AppProcess]
}

final class ProcessFetcher {
    func fetch() -> ProcessList {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-A", "-o", "pcpu=", "-o", "pmem=", "-o", "rss=", "-o", "comm=", "-r"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            return ProcessList(topCPU: [], topMemory: [])
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return ProcessList(topCPU: [], topMemory: [])
        }

        var processes = [AppProcess]()

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 4,
                  let cpu = Double(parts[0]),
                  let mem = Double(parts[1]),
                  let rss = UInt64(parts[2]) else { continue }
            let rawName = String(parts[3...].joined(separator: " "))
            let name = URL(fileURLWithPath: rawName).lastPathComponent
            processes.append(AppProcess(name: name, cpu: cpu, mem: mem, rss: rss))
        }

        let topCPU = Array(processes.prefix(3))
        let topMemory = Array(processes.sorted(by: { $0.mem > $1.mem }).prefix(3))

        return ProcessList(topCPU: topCPU, topMemory: topMemory)
    }
}
