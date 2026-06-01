import Darwin
import Foundation

struct SelfStats {
    let cpu: Double
    let memoryMB: Double
}

final class SelfMonitor {
    private var prevUser: time_value_t?
    private var prevSystem: time_value_t?
    private var prevWallTime: Date?

    func sample() -> SelfStats {
        let memoryMB = residentMemoryMB()

        var info = task_thread_times_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info_data_t>.size / MemoryLayout<integer_t>.size)

        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_THREAD_TIMES_INFO), $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return SelfStats(cpu: 0, memoryMB: memoryMB) }

        let now = Date()
        let curUser = info.user_time
        let curSystem = info.system_time
        var cpuPercent = 0.0

        if let prevUser, let prevSystem, let prevWallTime {
            let userDelta = timevalToSeconds(curUser) - timevalToSeconds(prevUser)
            let sysDelta  = timevalToSeconds(curSystem) - timevalToSeconds(prevSystem)
            let wallDelta = now.timeIntervalSince(prevWallTime)
            if wallDelta > 0 {
                cpuPercent = min((userDelta + sysDelta) / wallDelta * 100.0, 100.0)
            }
        }

        prevUser = curUser
        prevSystem = curSystem
        prevWallTime = now

        return SelfStats(cpu: cpuPercent, memoryMB: memoryMB)
    }

    private func residentMemoryMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)

        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }

    private func timevalToSeconds(_ tv: time_value_t) -> Double {
        Double(tv.seconds) + Double(tv.microseconds) / 1_000_000.0
    }
}
