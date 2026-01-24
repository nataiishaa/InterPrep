import Foundation

enum TabItem: CaseIterable, Hashable {
    case calendar
    case documents
    case search
    case chat
    case profile

    var title: String {
        switch self {
        case .calendar: return "Календарь"
        case .documents: return "Документы"
        case .search: return "Поиск"
        case .chat: return "Чат"
        case .profile: return "Профиль"
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .documents: return "doc.text"
        case .search: return "magnifyingglass"
        case .chat: return "message"
        case .profile: return "person"
        }
    }

    var iconFilled: String {
        switch self {
        case .calendar: return "calendar"
        case .documents: return "doc.text.fill"
        case .search: return "magnifyingglass"
        case .chat: return "message.fill"
        case .profile: return "person.fill"
        }
    }

    var description: String {
        switch self {
        case .calendar:
            return "Планируйте собеседования и отслеживайте важные даты"
        case .documents:
            return "Управляйте резюме и документами для собеседований"
        case .search:
            return "Ищите вакансии и получайте персональные рекомендации"
        case .chat:
            return "AI-ассистент для подготовки к собеседованиям"
        case .profile:
            return "Настройки профиля и статистика вашего прогресса"
        }
    }
}
