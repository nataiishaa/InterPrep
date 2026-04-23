//
//  SnapshotTestCase.swift
//  InterPrep
//
//  Base class for snapshot tests with environment configuration
//

import SnapshotTesting
import XCTest

@MainActor
open class SnapshotTestCase: XCTestCase {
    
    public nonisolated override func invokeTest() {
        withSnapshotTesting(record: recordingMode) {
            super.invokeTest()
            self.executionTimeAllowance = 300 // 5 minutes for batch tests
        }
    }
    
    private nonisolated var recordingMode: SnapshotTestingConfiguration.Record {
        .getFromEnvironment()
    }
}

extension SnapshotTestingConfiguration.Record {
    static func getFromEnvironment() -> Self {
        if let rawValue = ProcessInfo.processInfo.environment["SNAPSHOT_RECORDING_MODE"],
           let mode = SnapshotTestingConfiguration.Record(rawValue: rawValue) {
            return mode
        } else {
            // Default to .missing if not specified
            return .missing
        }
    }
}
