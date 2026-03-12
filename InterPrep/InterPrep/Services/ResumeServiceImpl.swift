//
//  ResumeServiceImpl.swift
//  InterPrep
//
//  Real implementation of ResumeService using NetworkServiceV2
//

import Foundation
import NetworkService
import DiscoveryModule

public final actor ResumeServiceImpl: ResumeService {
    private let networkService: NetworkServiceV2
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func hasResume() async -> Bool {
        let result = await networkService.getUser_ResumeProfile()
        
        switch result {
        case .success(let response):
            // Если есть профиль с данными, значит резюме есть
            return !response.profile.name.isEmpty || !response.profile.email.isEmpty
        case .failure(let error):
            print("❌ Failed to check resume: \(error)")
            return false
        }
    }
}
