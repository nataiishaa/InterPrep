//
//  DiscoveryView.swift
//  InterPrep
//
//  Discovery screen - passive view
//

import DesignSystem
import SwiftUI

public struct DiscoveryView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    
    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        VStack(spacing: Layout.rootStackSpacing) {
            header
            
            if model.isOfflineMode {
                OfflineBanner(showCachedHint: true)
            }
            
            if model.errorMessage != nil && model.vacancies.isEmpty {
                NoConnectionView(onRetry: model.onRetry)
            } else if model.hasResume {
                if model.isLoading && model.vacancies.isEmpty {
                    loadingView
                } else if model.vacancies.isEmpty {
                    emptyStateView
                } else {
                    vacanciesList
                }
            } else {
                uploadResumeEmptyState
            }
        }
        .background(Color.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: Layout.safeAreaBottomInset)
        }
    }
    
    @ViewBuilder
    private var header: some View {
        VStack(spacing: Layout.headerOuterSpacing) {
            HStack(spacing: Layout.headerRowSpacing) {
                HStack(spacing: Layout.searchInnerSpacing) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)
                    
                    TextField("Поиск вакансий...", text: Binding(
                        get: { model.searchQuery },
                        set: { model.onSearchQueryChanged($0) }
                    ))
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        model.onSearchSubmitted()
                    }
                    
                    if !model.searchQuery.isEmpty {
                        Button {
                            model.onSearchQueryChanged("")
                            model.onSearchSubmitted()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, Layout.searchHorizontalPadding)
                .padding(.vertical, Layout.searchVerticalPadding)
                .background(Color.fieldBackground)
                .cornerRadius(Layout.searchCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.searchCornerRadius)
                        .stroke(Color.divider.opacity(0.5), lineWidth: Layout.searchStrokeWidth)
                )
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.headerTopPadding)
            
            HStack(spacing: Layout.tabSpacing) {
                filterTab(
                    title: "Вакансии",
                    isSelected: model.selectedFilter == .all,
                    action: { model.onFilterChanged(.all) }
                )
                
                filterTab(
                    title: "Избранное",
                    isSelected: model.selectedFilter == .favorites,
                    action: { model.onFilterChanged(.favorites) }
                )
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.bottom, Layout.headerBottomPadding)
        .background(Color.cardBackground)
    }
    
    @ViewBuilder
    private func filterTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.tabVerticalPadding)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.brandPrimary, .brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.fieldBackground
                        }
                    }
                )
                .cornerRadius(Layout.tabCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.tabCornerRadius)
                        .stroke(isSelected ? Color.clear : Color.divider.opacity(0.5), lineWidth: Layout.tabStrokeWidth)
                )
                .shadow(
                    color: isSelected ? .brandPrimary.opacity(0.3) : .clear,
                    radius: isSelected ? Layout.tabSelectedShadowRadius : .zero,
                    x: .zero,
                    y: isSelected ? Layout.tabSelectedShadowY : .zero
                )
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: Layout.loadingStackSpacing) {
            Spacer()
            ProgressView()
                .scaleEffect(Layout.loadingProgressScale)
                .tint(.brandPrimary)
            Text("Загрузка вакансий...")
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Layout.emptyStackSpacing) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.emptyIconSide, height: Layout.emptyIconSide)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: Layout.emptyTextSpacing) {
                Text("Вакансий пока нет")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textOnBackground)
                
                Text("Попробуйте изменить фильтр\nили зайти позже")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
    
    @ViewBuilder
    private var uploadResumeEmptyState: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundPrimary,
                    Color.brandPrimary.opacity(colorScheme == .dark ? 0.15 : 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: Layout.uploadOuterSpacing) {
                Spacer()
                    .frame(minHeight: Layout.uploadTopSpacerMinHeight)
                
                Image("upload_cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.uploadImageHeight)
                    .padding(.horizontal, Layout.uploadImageHorizontalPadding)
                
                VStack(spacing: Layout.uploadTextBlockSpacing) {
                    Text("Загрузите свое резюме,\nчтобы получить\nперсональные рекомендации")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Мы подберем вакансии\nспециально для вас")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Layout.uploadCopyHorizontalPadding)
                
                Spacer()
                    .frame(minHeight: Layout.uploadMidSpacerMinHeight)
                
                Button {
                    model.onUploadResume()
                } label: {
                    HStack(spacing: Layout.uploadButtonInnerSpacing) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.title3)
                        Text("Загрузить резюме")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.uploadButtonHeight)
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Layout.uploadButtonCornerRadius)
                    .shadow(
                        color: .brandPrimary.opacity(0.4),
                        radius: Layout.uploadButtonShadowRadius,
                        x: .zero,
                        y: Layout.uploadButtonShadowY
                    )
                }
                .padding(.horizontal, Layout.uploadButtonHorizontalPadding)
                .padding(.bottom, Layout.uploadButtonBottomPadding)
            }
        }
    }
    
    @ViewBuilder
    private var vacanciesList: some View {
        ScrollView {
            LazyVStack(spacing: Layout.listRowSpacing) {
                ForEach(model.vacancies) { vacancy in
                    VStack(alignment: .leading, spacing: Layout.cardInnerStackSpacing) {

                        HStack(alignment: .top, spacing: Layout.cardMainRowSpacing) {
 
                            HStack(alignment: .top, spacing: Layout.cardMainRowSpacing) {
                                Group {
                                    if let urlString = vacancy.companyLogoURL, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            case .failure:
                                                logoPlaceholderView(vacancy: vacancy)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                logoPlaceholderView(vacancy: vacancy)
                                            }
                                        }
                                    } else {
                                        logoPlaceholderView(vacancy: vacancy)
                                    }
                                }
                                .frame(width: Layout.logoSize, height: Layout.logoSize)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: Layout.titleBlockSpacing) {
                                    Text(vacancy.company)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(vacancy.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                model.onVacancyTap(vacancy)
                            }
                            
                            Button {
                                model.onToggleFavorite(vacancy.id)
                            } label: {
                                Image(systemName: vacancy.isFavorite ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(vacancy.isFavorite ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(Layout.cardPadding)
      
                        VStack(alignment: .leading, spacing: Layout.cardInnerStackSpacing) {
                            Text(vacancy.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .padding(.horizontal, Layout.cardPadding)
                                .padding(.bottom, Layout.descriptionBottomPadding)
                            
                            HStack(spacing: Layout.metaRowSpacing) {
                                if let salaryText = vacancy.salaryText {
                                    HStack(spacing: Layout.chipInnerSpacing) {
                                        Image(systemName: "rublesign.circle.fill")
                                            .font(.caption)
                                        Text(salaryText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.brandPrimary)
                                    .padding(.horizontal, Layout.chipHorizontalPadding)
                                    .padding(.vertical, Layout.chipVerticalPadding)
                                    .background(Color.brandPrimary.opacity(0.1))
                                    .cornerRadius(Layout.chipCornerRadius)
                                }
                                if let experienceText = vacancy.experienceText {
                                    HStack(spacing: Layout.chipInnerSpacing) {
                                        Image(systemName: "briefcase.fill")
                                            .font(.caption)
                                        Text(experienceText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, Layout.chipHorizontalPadding)
                                    .padding(.vertical, Layout.chipVerticalPadding)
                                    .background(Color.fieldBackground)
                                    .cornerRadius(Layout.chipCornerRadius)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, Layout.cardPadding)
                            .padding(.bottom, Layout.metaBottomPadding)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.onVacancyTap(vacancy)
                        }
                    }
                    .opacity(model.isOfflineMode ? Layout.offlineCardOpacity : Layout.onlineCardOpacity)
                    .background(Color.cardBackground)
                    .cornerRadius(Layout.cardCornerRadius)
                    .shadow(color: shadowColor, radius: Layout.cardShadowRadius, x: .zero, y: Layout.cardShadowY)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                            .stroke(Color.divider, lineWidth: Layout.cardStrokeWidth)
                    )
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.listTopPadding)
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.08)
    }
    
    @ViewBuilder
    private func logoPlaceholderView(vacancy: DiscoveryState.Vacancy) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.brandPrimary.opacity(0.8), Color.brandSecondary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(String(vacancy.company.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }

}

private extension DiscoveryView {
    enum Layout {
        static let rootStackSpacing = CGFloat.zero
        static let safeAreaBottomInset: CGFloat = 60
        static let headerOuterSpacing: CGFloat = 12
        static let headerRowSpacing: CGFloat = 12
        static let searchInnerSpacing: CGFloat = 8
        static let searchHorizontalPadding: CGFloat = 12
        static let searchVerticalPadding: CGFloat = 10
        static let searchCornerRadius: CGFloat = 12
        static let searchStrokeWidth: CGFloat = 1
        static let headerTopPadding: CGFloat = 12
        static let headerBottomPadding: CGFloat = 8
        static let tabVerticalPadding: CGFloat = 14
        static let tabCornerRadius: CGFloat = 12
        static let tabStrokeWidth: CGFloat = 1
        static let tabSelectedShadowRadius: CGFloat = 8
        static let tabSelectedShadowY: CGFloat = 4
        static let loadingStackSpacing: CGFloat = 16
        static let loadingProgressScale: CGFloat = 1.5
        static let emptyStackSpacing: CGFloat = 24
        static let emptyIconSide: CGFloat = 80
        static let emptyTextSpacing: CGFloat = 8
        static let uploadOuterSpacing = CGFloat.zero
        static let uploadTopSpacerMinHeight: CGFloat = 30
        static let uploadImageHeight: CGFloat = 300
        static let uploadImageHorizontalPadding: CGFloat = 20
        static let uploadTextBlockSpacing: CGFloat = 12
        static let uploadCopyHorizontalPadding: CGFloat = 24
        static let uploadMidSpacerMinHeight: CGFloat = 40
        static let uploadButtonInnerSpacing: CGFloat = 12
        static let uploadButtonHeight: CGFloat = 56
        static let uploadButtonCornerRadius: CGFloat = 16
        static let uploadButtonShadowRadius: CGFloat = 12
        static let uploadButtonShadowY: CGFloat = 6
        static let uploadButtonHorizontalPadding: CGFloat = 24
        static let uploadButtonBottomPadding: CGFloat = 40
        static let listRowSpacing: CGFloat = 16
        static let cardInnerStackSpacing = CGFloat.zero
        static let cardMainRowSpacing: CGFloat = 12
        static let logoSize: CGFloat = 48
        static let titleBlockSpacing: CGFloat = 4
        static let cardPadding: CGFloat = 16
        static let descriptionBottomPadding: CGFloat = 12
        static let metaRowSpacing: CGFloat = 8
        static let chipInnerSpacing: CGFloat = 4
        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 6
        static let chipCornerRadius: CGFloat = 8
        static let metaBottomPadding: CGFloat = 16
        static let offlineCardOpacity: Double = 0.7
        static let onlineCardOpacity: Double = 1.0
        static let cardCornerRadius: CGFloat = 16
        static let cardShadowRadius: CGFloat = 12
        static let cardShadowY: CGFloat = 4
        static let cardStrokeWidth: CGFloat = 1
        static let listTopPadding: CGFloat = 8
        static var horizontalPadding: CGFloat { 16 }
        static var tabSpacing: CGFloat { 12 }
    }
}

#Preview("No Resume - Light") {
    DiscoveryView(model: .noResume)
        .preferredColorScheme(.light)
}

#Preview("No Resume - Dark") {
    DiscoveryView(model: .noResume)
        .preferredColorScheme(.dark)
}

#Preview("With Vacancies - Light") {
    DiscoveryView(model: .withVacancies)
        .preferredColorScheme(.light)
}

#Preview("With Vacancies - Dark") {
    DiscoveryView(model: .withVacancies)
        .preferredColorScheme(.dark)
}
