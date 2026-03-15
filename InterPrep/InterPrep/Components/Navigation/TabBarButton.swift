import SwiftUI
import DesignSystem

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: TabBarLayout.buttonStackSpacing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.tabBarActive.opacity(TabBarLayout.selectedCircleOpacity))
                            .frame(
                                width: TabBarLayout.selectedCircleSize,
                                height: TabBarLayout.selectedCircleSize
                            )
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: TabBarLayout.iconSize, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .tabBarActive : .tabBarInactive)
                        .scaleEffect(isSelected ? TabBarLayout.selectedScale : 1.0)
                }
                .frame(height: TabBarLayout.iconStackHeight)
                .clipped()

                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .tabBarActive : .tabBarInactive)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(
            .spring(
                response: TabBarLayout.springResponse,
                dampingFraction: TabBarLayout.springDamping
            ),
            value: isSelected
        )
    }
}
