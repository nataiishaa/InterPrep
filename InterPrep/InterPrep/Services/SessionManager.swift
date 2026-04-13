//
//  SessionManager.swift
//  InterPrep
//
//  Manages user session and handles unauthorized errors globally
//

import Foundation

public protocol SessionInvalidationDelegate: AnyObject, Sendable {
    func sessionDidInvalidate()
}

public actor SessionManager: NetworkResponseObserver {
    weak var delegate: SessionInvalidationDelegate?
    private var hasInvalidated = false
    
    public init() {}
    
    public func setDelegate(_ delegate: SessionInvalidationDelegate?) {
        self.delegate = delegate
        self.hasInvalidated = false
    }
    
    public func observe(request: URLRequest, response: HTTPURLResponse?, data: Data?, error: Error?) async {
        if let httpResponse = response, httpResponse.statusCode == 401 {
            await handleUnauthorized()
        }
        
        if let networkError = error as? NetworkError, case .unauthorized = networkError {
            await handleUnauthorized()
        }
    }
    
    private func handleUnauthorized() async {
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
