//
//  ResumeServicing.swift
//  InterPrep
//
//  Created by Наталья Захарова on 26/4/2026.
//

public protocol ResumeServicing: Actor {
    func hasResume() async -> Bool
    func invalidateCache() async
}
