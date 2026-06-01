import Foundation

final class MonitorService {
    private var prevUser: UInt64 = 0
    private var prevSystem: UInt64 = 0
    private var prevIdle: UInt64 = 0
    private var prevNice: UInt64 = 0
    private var hasPreviousSample = false

    func sampleCPU() -> Double {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let user = UInt64(cpuLoad.cpu_ticks.0)
        let system = UInt64(cpuLoad.cpu_ticks.1)
        let idle = UInt64(cpuLoad.cpu_ticks.2)
        let nice = UInt64(cpuLoad.cpu_ticks.3)

        defer {
            prevUser = user
            prevSystem = system
            prevIdle = idle
            prevNice = nice
            hasPreviousSample = true
        }

        guard hasPreviousSample else { return 0 }

        let userDelta = user &- prevUser
        let systemDelta = system &- prevSystem
        let idleDelta = idle &- prevIdle
        let niceDelta = nice &- prevNice

        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
        guard totalDelta > 0 else { return 0 }

        let usedDelta = userDelta + systemDelta + niceDelta
        return Double(usedDelta) / Double(totalDelta) * 100.0
    }

    func sampleMemory() -> Double {
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = UInt64(vm_kernel_page_size)
        let totalMemory = ProcessInfo.processInfo.physicalMemory

        let active = UInt64(vmStat.active_count)
        let wired = UInt64(vmStat.wire_count)
        let compressed = UInt64(vmStat.compressor_page_count)

        let usedMemory = (active + wired + compressed) * pageSize
        let percentage = Double(usedMemory) / Double(totalMemory) * 100.0

        return min(percentage, 100.0)
    }
}
