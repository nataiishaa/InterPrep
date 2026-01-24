import SwiftUI
import DesignSystem

struct TabBarView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .frame(height: TabBarLayout.barHeight)
        .background(tabBarBackground)
        .shadow(
            color: shadowColor,
            radius: TabBarLayout.shadowRadius,
            x: TabBarLayout.shadowX,
            y: TabBarLayout.shadowY
        )
    }

    private var tabBarBackground: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : .white
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1)
    }
}

#Preview("Light Mode") {
    VStack {
        Spacer()
        TabBarView(selectedTab: .constant(.search))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack {
        Spacer()
        TabBarView(selectedTab: .constant(.search))
    }
    .preferredColorScheme(.dark)
}
