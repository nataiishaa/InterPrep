//
//  State.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation

/*
 
 STATE - СОСТОЯНИЕ ЭКРАНА
 
 Это центральная часть архитектуры, которая:
 - Хранит все данные экрана (items, isLoading, errorMessage и т.д.)
 - Определяет Input (действия от пользователя)
 - Определяет Feedback (результаты после эффектов)
 - Определяет Effect (асинхронные операции)
 - Содержит функцию reduce() для изменения состояния
 
 Пример использования см. в Architecture/Examples/ExampleState.swift
 
 */

/// Message type that wraps Input and Feedback
public enum Message<Input, Feedback> {
    case input(Input)
    case feedback(Feedback)
}

/// Protocol for State management
public protocol FeatureState {
    associatedtype Input
    associatedtype Feedback
    associatedtype Effect
    
    /// Reduces state based on incoming message (Input or Feedback)
    /// Returns optional Effect that should be handled by EffectHandler
    @MainActor
    static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect?
}
