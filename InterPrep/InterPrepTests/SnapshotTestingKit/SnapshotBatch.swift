//
//  SnapshotBatch.swift
//  InterPrep
//
//  Batch configurations for different types of snapshot tests
//

import Foundation
import SnapshotTesting

public enum SnapshotBatch {
    case regularFullscreen
    case extendedFullscreen
    case component
    case shape
    
    public var testingEnvironments: [TestingEnvironment] {
        switch self {
        case .regularFullscreen:
            [
                .defaultTestingDevice(.iPhone13Pro, scheme: .light),
                .defaultTestingDevice(.iPhone13Pro, scheme: .dark)
            ]
        case .extendedFullscreen:
            [
                .defaultTestingDevice(.iPhone13Pro, scheme: .light),
                .defaultTestingDevice(.iPhone13Pro, scheme: .dark),
                .defaultTestingDevice(.iPhoneSe, scheme: .light)
            ]
        case .component:
            [
                .sizeThatFits(scheme: .light),
                .sizeThatFits(scheme: .dark)
            ]
        case .shape:
            [
                .sizeThatFits(scheme: .light)
            ]
        }
    }
}
