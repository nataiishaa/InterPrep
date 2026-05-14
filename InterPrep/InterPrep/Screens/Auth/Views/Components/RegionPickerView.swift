import CacheService
import DesignSystem
import SwiftUI

public struct RegionPickerView: View {
    @Binding var selectedRegions: Set<String>
    let style: Style

    @State private var isPresented = false
    @State private var availableRegions: [String] = []
    @State private var isLoading = false
    @State private var searchText = ""

    public enum Style {
        case light
        case dark
    }

    public init(selectedRegions: Binding<Set<String>>, style: Style = .dark) {
        self._selectedRegions = selectedRegions
        self.style = style
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            label
            selectedChips
            selectButton
        }
        .sheet(isPresented: $isPresented) {
            regionPickerSheet
        }
        .task {
            if availableRegions.isEmpty {
                await loadRegions()
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        Text("Регионы")
            .font(.caption)
            .foregroundColor(style == .dark ? .white.opacity(0.7) : .secondary)
    }

    @ViewBuilder
    private var selectedChips: some View {
        if !selectedRegions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedRegions.sorted(), id: \.self) { region in
                        chipView(region: region, isSelected: true, showRemove: true)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectButton: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.body)
                Text(selectedRegions.isEmpty ? "Выбрать регионы" : "Изменить (\(selectedRegions.count))")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(style == .dark ? .white.opacity(0.8) : .primary)
            .padding()
            .background(style == .dark ? Color.white.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func chipView(region: String, isSelected: Bool, showRemove: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(region)
                .font(.subheadline)

            if showRemove {
                Button {
                    selectedRegions.remove(region)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            style == .dark
                ? Color.white.opacity(isSelected ? 0.35 : 0.1)
                : (isSelected ? Color.brandPrimary.opacity(0.2) : Color(.systemGray6))
        )
        .foregroundColor(style == .dark ? .white : (isSelected ? .brandPrimary : .primary))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected
                        ? (style == .dark ? Color.white.opacity(0.5) : Color.brandPrimary.opacity(0.5))
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private var regionPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if isLoading {
                    loadingView
                } else {
                    regionsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Выберите регионы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Поиск региона", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding()
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Загрузка регионов...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var regionsList: some View {
        let filtered = filteredRegions

        if filtered.isEmpty && !searchText.isEmpty {
            emptySearchView
        } else {
            List {
                if !selectedRegions.isEmpty {
                    selectedSection
                }

                allRegionsSection(regions: filtered)
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Ничего не найдено")
                .font(.headline)
            Text("Попробуйте изменить запрос")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectedSection: some View {
        Section {
            ForEach(selectedRegions.sorted(), id: \.self) { region in
                regionRow(region: region, isSelected: true)
            }
        } header: {
            Text("Выбрано (\(selectedRegions.count))")
        }
    }

    @ViewBuilder
    private func allRegionsSection(regions: [String]) -> some View {
        Section {
            ForEach(regions, id: \.self) { region in
                regionRow(region: region, isSelected: selectedRegions.contains(region))
            }
        } header: {
            Text("Все регионы")
        }
    }

    @ViewBuilder
    private func regionRow(region: String, isSelected: Bool) -> some View {
        Button {
            toggleRegion(region)
        } label: {
            HStack {
                Text(region)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandPrimary)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var filteredRegions: [String] {
        let unselected = availableRegions.filter { !selectedRegions.contains($0) }

        if searchText.isEmpty {
            return unselected
        }

        let lowercasedSearch = searchText.lowercased()
        return unselected.filter { $0.lowercased().contains(lowercasedSearch) }
    }

    private func toggleRegion(_ region: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedRegions.contains(region) {
                selectedRegions.remove(region)
            } else {
                selectedRegions.insert(region)
            }
        }
    }

    private func loadRegions() async {
        isLoading = true
        availableRegions = await AreasCache.shared.getAreas()
        isLoading = false
    }
}

#Preview("Dark Style") {
    ZStack {
        LinearGradient.brandBackground
            .ignoresSafeArea()

        RegionPickerView(
            selectedRegions: .constant(["Москва", "Санкт-Петербург"]),
            style: .dark
        )
        .padding()
    }
}

#Preview("Light Style") {
    RegionPickerView(
        selectedRegions: .constant(["Москва"]),
        style: .light
    )
    .padding()
}
