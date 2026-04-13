//
//  NetworkMonitor.swift
//  InterPrep
//
//  Network connectivity monitor for offline mode
//

import Foundation
import Network
import Combine

@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: ConnectionType = .unknown
    
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
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.isConnected = path.status == .satisfied
                
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
    
    deinit {
        monitor.cancel()
    }
}
