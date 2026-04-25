import Foundation

public protocol SessionInvalidationDelegate: AnyObject, Sendable {
    func sessionDidInvalidate()
}

public actor SessionManager {
    weak var delegate: SessionInvalidationDelegate?
    private var hasInvalidated = false
    
    public init() {}
    
    public func setDelegate(_ delegate: SessionInvalidationDelegate?) {
        self.delegate = delegate
        self.hasInvalidated = false
    }
    
    public func handleUnauthorized() async {
        guard !hasInvalidated else { return }
        guard let delegate = delegate else { return }
        
        hasInvalidated = true
        
        await MainActor.run {
            delegate.sessionDidInvalidate()
        }
    }
    
    public func reset() {
        hasInvalidated = false
    }
}
