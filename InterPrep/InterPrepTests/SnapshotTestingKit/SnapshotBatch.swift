import Foundation
import SnapshotTesting
import SwiftUI

public struct TestingEnvironment {
    public enum DefaultTestingDevice: String {
        case iPhone15Pro
        case iPhone13Pro
        case iPhoneSe

        public var viewImageConfig: ViewImageConfig {
            switch self {
            case .iPhone15Pro:
                return .iPhone13Pro // closest available
            case .iPhone13Pro:
                return .iPhone13Pro
            case .iPhoneSe:
                return .iPhoneSe
            }
        }
    }

    public enum Scheme: String, CaseIterable {
        case light
        case dark

        public var traitCollection: UITraitCollection {
            switch self {
            case .light:
                return UITraitCollection(userInterfaceStyle: .light)
            case .dark:
                return UITraitCollection(userInterfaceStyle: .dark)
            }
        }

        public var colorScheme: ColorScheme {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    public let layout: SwiftUISnapshotLayout
    public let scheme: Scheme
    public let descriptionComponents: [String]

    public static func defaultTestingDevice(
        _ device: DefaultTestingDevice,
        scheme: Scheme
    ) -> Self {
        self.init(
            layout: .device(config: device.viewImageConfig),
            scheme: scheme,
            descriptionComponents: [device.rawValue, scheme.rawValue]
        )
    }

    public static func sizeThatFits(scheme: Scheme) -> Self {
        self.init(
            layout: .sizeThatFits,
            scheme: scheme,
            descriptionComponents: ["sizeThatFits", scheme.rawValue]
        )
    }

    public static func fixed(width: CGFloat, height: CGFloat, scheme: Scheme) -> Self {
        self.init(
            layout: .fixed(width: width, height: height),
            scheme: scheme,
            descriptionComponents: ["fixed", scheme.rawValue]
        )
    }
}

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
