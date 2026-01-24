import SwiftUI

struct TabBarPreviewView: View {
    @State private var selectedTab: TabItem = .search

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Нижняя навигация")
                    .font(.title)
                    .fontWeight(.bold)

                Text("5 основных разделов приложения")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    Image(systemName: selectedTab.iconFilled)
                        .font(.title2)
                        .foregroundColor(.tabBarActive)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Текущий раздел:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(selectedTab.title)
                            .font(.headline)
                            .foregroundColor(.tabBarActive)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tabBarActive.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.top, 20)

            Spacer()

            contentPreview

            Spacer()

            TabBarView(selectedTab: $selectedTab)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var contentPreview: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab.iconFilled)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.tabBarActive, .tabBarActive.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(selectedTab.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedTab.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    TabBarPreviewView()
}
