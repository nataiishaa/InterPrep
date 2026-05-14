import Foundation
import NetworkService

public actor AreasCache {
    public static let shared = AreasCache()

    private let cacheKey = "areas_list"
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours

    private var inMemoryCache: [String]?
    private var fetchTask: Task<[String], Error>?

    private init() {}

    public func getAreas() async -> [String] {
        if let cached = inMemoryCache {
            return cached
        }

        if let diskCached = await loadFromDisk() {
            inMemoryCache = diskCached
            return diskCached
        }

        return await fetchAreas()
    }

    public func refreshAreas() async -> [String] {
        return await fetchAreas()
    }

    public func isValidArea(_ areaName: String) async -> Bool {
        let areas = await getAreas()
        return areas.contains { $0.lowercased() == areaName.lowercased() }
    }

    public func filterValidAreas(_ areas: [String]) async -> [String] {
        let validAreas = await getAreas()
        let lowercasedValid = Set(validAreas.map { $0.lowercased() })
        return areas.filter { lowercasedValid.contains($0.lowercased()) }
    }

    private func fetchAreas() async -> [String] {
        if let existingTask = fetchTask {
            do {
                return try await existingTask.value
            } catch {
                return []
            }
        }

        let task = Task<[String], Error> {
            let result = await NetworkServiceV2.shared.listAreas()
            switch result {
            case .success(let response):
                let areas = response.areaNames
                await saveToDisk(areas)
                return areas
            case .failure(let error):
                throw error
            }
        }

        fetchTask = task
        defer { fetchTask = nil }

        do {
            let areas = try await task.value
            inMemoryCache = areas
            return areas
        } catch {
            return inMemoryCache ?? []
        }
    }

    private func loadFromDisk() async -> [String]? {
        let isValid = await CacheManager.shared.isCacheValid(forKey: cacheKey, maxAge: maxCacheAge)
        guard isValid else { return nil }

        do {
            return try await CacheManager.shared.load(forKey: cacheKey, as: [String].self)
        } catch {
            return nil
        }
    }

    private func saveToDisk(_ areas: [String]) async {
        try? await CacheManager.shared.save(areas, forKey: cacheKey)
    }

    public func clearCache() async {
        inMemoryCache = nil
        try? await CacheManager.shared.remove(forKey: cacheKey)
    }
}
