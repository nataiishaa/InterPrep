//
//  DiscoveryView.swift
//  InterPrep
//
//  Discovery screen - passive view
//

import SwiftUI
import DesignSystem
// TODO: После генерации Tuist раскомментировать:
// import VacancyCardModule

public struct DiscoveryView: View {
    let model: Model
    @Environment(\.colorScheme) var colorScheme
    
    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            header
            
            if model.hasResume {
                if model.isLoading {
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
            Color.clear.frame(height: 60) // Отступ для навигационной панели
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var header: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.fieldBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.divider.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 12)
            
            // Filter tabs
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
        .padding(.bottom, 8)
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
                .padding(.vertical, 14)
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
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.divider.opacity(0.5), lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? .brandPrimary.opacity(0.3) : .clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.brandPrimary)
            Text("Загрузка вакансий...")
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
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
            // Gradient background
            LinearGradient(
                colors: [
                    Color.backgroundPrimary,
                    Color.brandPrimary.opacity(colorScheme == .dark ? 0.15 : 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 30)
                
                // Illustration
                Image("upload_cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .padding(.horizontal, 20)
                   // .padding(.bottom, 10)
                
                // Text
                VStack(spacing: 12) {
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
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(minHeight: 40)
                
                // Upload button
                Button {
                    model.onUploadResume()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.title3)
                        Text("Загрузить резюме")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    @ViewBuilder
    private var vacanciesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(model.vacancies) { vacancy in
                    // TODO: После генерации Tuist заменить на:
                    // VacancyCardView(vacancy: convertToVacancy(vacancy)) {
                    //     model.onVacancyTap(vacancy)
                    // }
                    
                    // Красивая карточка вакансии: тап по карточке открывает вакансию, кнопка закладки — только избранное
                    VStack(alignment: .leading, spacing: 0) {
                        // Header с компанией и избранным
                        HStack(alignment: .top, spacing: 12) {
                            // Область тапа «открыть вакансию» (логотип + название)
                            HStack(alignment: .top, spacing: 12) {
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
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
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
                            
                            // Кнопка избранного — отдельная зона тапа, не открывает вакансию
                            Button {
                                model.onToggleFavorite(vacancy.id)
                            } label: {
                                Image(systemName: vacancy.isFavorite ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(vacancy.isFavorite ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        
                        // Описание и футер — тап открывает вакансию
                        VStack(alignment: .leading, spacing: 0) {
                            Text(vacancy.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            
                            HStack(spacing: 8) {
                                if let salaryText = vacancy.salaryText {
                                    HStack(spacing: 4) {
                                        Image(systemName: "rublesign.circle.fill")
                                            .font(.caption)
                                        Text(salaryText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.brandPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.brandPrimary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                if let experienceText = vacancy.experienceText {
                                    HStack(spacing: 4) {
                                        Image(systemName: "briefcase.fill")
                                            .font(.caption)
                                        Text(experienceText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.fieldBackground)
                                    .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.onVacancyTap(vacancy)
                        }
                    }
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.divider, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 8)
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
    
    // TODO: После генерации Tuist - конвертер из DiscoveryState.Vacancy в Vacancy
    // private func convertToVacancy(_ vacancy: DiscoveryState.Vacancy) -> Vacancy {
    //     Vacancy(
    //         id: vacancy.id,
    //         title: vacancy.title,
    //         company: vacancy.company,
    //         location: "Москва", // TODO: Добавить в модель
    //         salary: nil, // TODO: Добавить в модель
    //         employmentType: .fullTime,
    //         experienceLevel: .middle,
    //         description: vacancy.description,
    //         postedDate: Date()
    //     )
    // }
}

// MARK: - Model

extension DiscoveryView {
    public struct Model {
        public let selectedFilter: DiscoveryState.FilterType
        public let hasResume: Bool
        public let isLoading: Bool
        public let vacancies: [DiscoveryState.Vacancy]
        public let searchQuery: String
        public let onFilterChanged: (DiscoveryState.FilterType) -> Void
        public let onUploadResume: () -> Void
        public let onVacancyTap: (DiscoveryState.Vacancy) -> Void
        public let onToggleFavorite: (String) -> Void
        public let onSearchQueryChanged: (String) -> Void
        public let onSearchSubmitted: () -> Void
        
        public init(
            selectedFilter: DiscoveryState.FilterType,
            hasResume: Bool,
            isLoading: Bool,
            vacancies: [DiscoveryState.Vacancy],
            searchQuery: String,
            onFilterChanged: @escaping (DiscoveryState.FilterType) -> Void,
            onUploadResume: @escaping () -> Void,
            onVacancyTap: @escaping (DiscoveryState.Vacancy) -> Void,
            onToggleFavorite: @escaping (String) -> Void,
            onSearchQueryChanged: @escaping (String) -> Void,
            onSearchSubmitted: @escaping () -> Void
        ) {
            self.selectedFilter = selectedFilter
            self.hasResume = hasResume
            self.isLoading = isLoading
            self.vacancies = vacancies
            self.searchQuery = searchQuery
            self.onFilterChanged = onFilterChanged
            self.onUploadResume = onUploadResume
            self.onVacancyTap = onVacancyTap
            self.onToggleFavorite = onToggleFavorite
            self.onSearchQueryChanged = onSearchQueryChanged
            self.onSearchSubmitted = onSearchSubmitted
        }
    }
}

// MARK: - Layout

private extension DiscoveryView {
    enum Layout {
        static var horizontalPadding: CGFloat { 16 }
        static var topPadding: CGFloat { 16 }
        static var headerSpacing: CGFloat { 16 }
        static var headerBottomPadding: CGFloat { 8 }
        static var tabSpacing: CGFloat { 12 }
        static var buttonHeight: CGFloat { 50 }
        static var bottomPadding: CGFloat { 32 }
    }
}

// MARK: - Fixtures

#if DEBUG
extension DiscoveryView.Model {
    public static func fixture(
        selectedFilter: DiscoveryState.FilterType = .all,
        hasResume: Bool = false,
        isLoading: Bool = false,
        vacancies: [DiscoveryState.Vacancy] = [],
        searchQuery: String = "",
        onFilterChanged: @escaping (DiscoveryState.FilterType) -> Void = { _ in },
        onUploadResume: @escaping () -> Void = {},
        onVacancyTap: @escaping (DiscoveryState.Vacancy) -> Void = { _ in },
        onToggleFavorite: @escaping (String) -> Void = { _ in },
        onSearchQueryChanged: @escaping (String) -> Void = { _ in },
        onSearchSubmitted: @escaping () -> Void = {}
    ) -> Self {
        .init(
            selectedFilter: selectedFilter,
            hasResume: hasResume,
            isLoading: isLoading,
            vacancies: vacancies,
            searchQuery: searchQuery,
            onFilterChanged: onFilterChanged,
            onUploadResume: onUploadResume,
            onVacancyTap: onVacancyTap,
            onToggleFavorite: onToggleFavorite,
            onSearchQueryChanged: onSearchQueryChanged,
            onSearchSubmitted: onSearchSubmitted
        )
    }
    
    public static var noResume: Self {
        .fixture(hasResume: false)
    }
    
    public static var loading: Self {
        .fixture(hasResume: true, isLoading: true)
    }
    
    public static var empty: Self {
        .fixture(hasResume: true, isLoading: false, vacancies: [])
    }
    
    public static var withVacancies: Self {
        .fixture(
            hasResume: true,
            vacancies: [
                .init(id: "1", title: "iOS Developer", company: "Yandex", description: "...", isFavorite: false, url: "https://hh.ru/vacancy/123456"),
                .init(id: "2", title: "Swift Developer", company: "Авито", description: "...", isFavorite: true, url: "https://hh.ru/vacancy/789012")
            ]
        )
    }
}
#endif

// MARK: - Previews

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
