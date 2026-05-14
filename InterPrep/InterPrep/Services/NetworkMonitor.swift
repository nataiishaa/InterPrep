import CFNetwork
import Combine
import Foundation
import Network

@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: ConnectionType = .unknown
    @Published public private(set) var isVPNActive: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.interprep.networkmonitor")

    public enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
        isVPNActive = Self.detectVPN()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.isConnected = path.status == .satisfied
                self.isVPNActive = Self.detectVPN()

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }
            }
        }

        monitor.start(queue: queue)
    }

    private static func detectVPN() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = cfDict["__SCOPED__"] as? [String: Any] else {
            return false
        }
        let vpnPrefixes = ["tap", "tun", "ppp", "ipsec", "utun", "ipsec0"]
        return scoped.keys.contains { key in
            vpnPrefixes.contains(where: { key.hasPrefix($0) })
        }
    }

    deinit {
        monitor.cancel()
    }
}
