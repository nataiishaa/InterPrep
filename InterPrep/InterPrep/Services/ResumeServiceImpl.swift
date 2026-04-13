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
    private var cachedHasResume: Bool?
    private var lastCheckTime: Date?
    private let cacheValidityDuration: TimeInterval = 60
    
    public init(networkService: NetworkServiceV2 = .shared) {
        self.networkService = networkService
    }
    
    public func hasResume() async -> Bool {
        if let cached = cachedHasResume,
           let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < cacheValidityDuration {
            return cached
        }
        
        let result = await networkService.getUser_ResumeProfile()
        
        let hasResumeValue: Bool
        switch result {
        case .success(let response):
            let profile = response.profile
            
            let hasTargetRoles = !profile.targetRoles.isEmpty
            let hasAreas = !profile.areas.isEmpty
            let hasSkills = !profile.skillsTop.isEmpty
            let hasExperience = profile.hasExperienceLevel
            let hasSalary = profile.hasSalaryMin
            
            hasResumeValue = hasTargetRoles || hasAreas || hasSkills || hasExperience || hasSalary
        case .failure:
            hasResumeValue = false
        }
        
        cachedHasResume = hasResumeValue
        lastCheckTime = Date()
        
        return hasResumeValue
    }
    
    public func invalidateCache() {
        cachedHasResume = nil
        lastCheckTime = nil
    }
}
