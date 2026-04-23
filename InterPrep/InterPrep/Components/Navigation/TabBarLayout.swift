import SwiftUI

enum TabBarLayout {
    static let barHeight: CGFloat = 68
    static let shadowRadius: CGFloat = 8
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = -2
    static let topCornerRadius: CGFloat = 20

    static let buttonStackSpacing: CGFloat = 4
    /// Круг выделения; iconStackHeight и barHeight подобраны так, чтобы круг не выходил за панель
    static let selectedCircleSize: CGFloat = 48
    static let selectedCircleOpacity: Double = 0.15
    static let iconSize: CGFloat = 24
    static let iconStackHeight: CGFloat = 50
    static let selectedScale: CGFloat = 1.1
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
}
