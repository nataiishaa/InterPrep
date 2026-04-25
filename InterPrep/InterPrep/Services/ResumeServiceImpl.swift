//
//  ResumeServiceImpl.swift
//  InterPrep
//
//  Real implementation of ResumeService using NetworkServiceV2
//

import DiscoveryModule
import Foundation
import NetworkService

public final actor ResumeServiceImpl: ResumeService {
    private let networkService: NetworkServiceV2
    private var cachedHasResume: Bool?
    private var lastCheckTime: Date?
    private let cacheValidityDuration: TimeInterval = 60
    
    private static let persistedHasResumeKey = "com.interprep.last_known_has_resume"
    
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
            UserDefaults.standard.set(hasResumeValue, forKey: Self.persistedHasResumeKey)
        case .failure(let error):
            // Cold start offline: in-memory cache is empty; use last successful value instead of false.
            if error.isConnectionError,
               UserDefaults.standard.object(forKey: Self.persistedHasResumeKey) != nil {
                let stored = UserDefaults.standard.bool(forKey: Self.persistedHasResumeKey)
                cachedHasResume = stored
                lastCheckTime = Date()
                return stored
            }
            hasResumeValue = false
        }
        
        cachedHasResume = hasResumeValue
        lastCheckTime = Date()
        
        return hasResumeValue
    }
    
    public func invalidateCache() async {
        cachedHasResume = nil
        lastCheckTime = nil
        UserDefaults.standard.removeObject(forKey: Self.persistedHasResumeKey)
    }
}
