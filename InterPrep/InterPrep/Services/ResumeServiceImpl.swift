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
            let profile = response.profile
            
            // Считаем, что резюме есть, если заполнены какие-либо ключевые поля
            let hasTargetRoles = !profile.targetRoles.isEmpty
            let hasAreas = !profile.areas.isEmpty
            let hasSkills = !profile.skillsTop.isEmpty
            let hasExperience = profile.hasExperienceLevel
            let hasSalary = profile.hasSalaryMin
            
            return hasTargetRoles || hasAreas || hasSkills || hasExperience || hasSalary
        case .failure:
            return false
        }
    }
}
