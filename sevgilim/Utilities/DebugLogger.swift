//
//  DebugLogger.swift
//  sevgilim
//
//  Central debug logging utility - only prints in DEBUG builds
//

import Foundation

/// Debug-only logging function. Compiles to nothing in Release builds.
/// - Parameter message: The message to log
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}
