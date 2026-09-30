import Foundation

/// macOS reports "memory free %" as `kern.memorystatus_level`; pressure is its
/// complement. Unlike "RAM used", it only climbs when the system is actually short.
enum MemoryPressureMath {
    static func percent(freeLevel: Int?) -> Double? {
        guard let freeLevel else { return nil }
        return Double(100 - min(max(freeLevel, 0), 100))
    }
}
