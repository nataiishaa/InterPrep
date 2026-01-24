//
//  EffectHandler.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation

/*
 
 EFFECT HANDLER - ОБРАБОТЧИК ЭФФЕКТОВ
 
 Это место, где происходят все side-effects:
 - Сетевые запросы (API calls)
 - Работа с базой данных
 - Аналитика
 - Навигация (через делегаты)
 - Любые операции с внешними зависимостями
 
 EffectHandler:
 - Всегда является Actor (для безопасности)
 - Получает Effect из State
 - Возвращает Feedback обратно в State
 - Может содержать зависимости (Services)
 
 Пример использования см. в Architecture/Examples/ExampleEffectHandler.swift
 
 */

/// Protocol for handling effects with external dependencies
public protocol EffectHandler<S>: Actor {
    associatedtype S: FeatureState
    
    /// Handles effect and returns optional Feedback
    func handle(effect: S.Effect) async -> S.Feedback?
}

/// Default empty EffectHandler for screens without effects
public final actor DummyEffectHandler<S: FeatureState>: EffectHandler {
    public init() {}
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        return nil
    }
}
