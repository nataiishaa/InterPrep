import SnapshotTesting
import SwiftUI
@testable import VacancyCardFeature
import XCTest

final class VacancyCardViewSnapshotTests: SnapshotTestCase {

    private static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 12
        return Calendar.current.date(from: components)!
    }()

    private var refDate: Date { Self.referenceDate }

    func testVacancyCardView_fullData_light() {
        let vacancy = Vacancy(
            id: "1",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 200_000, max: 350_000),
            employmentType: .fullTime,
            experienceLevel: .middle,
            description: "Разработка мобильных приложений",
            requirements: ["Swift", "UIKit"],
            benefits: ["ДМС"],
            tags: ["iOS", "Swift", "Mobile"],
            postedDate: refDate.addingTimeInterval(-86400 * 2),
            applicationDeadline: refDate.addingTimeInterval(86400 * 30),
            isRemote: false
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "fullData_light")
    }

    func testVacancyCardView_fullData_dark() {
        let vacancy = Vacancy(
            id: "1",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 200_000, max: 350_000),
            employmentType: .fullTime,
            experienceLevel: .middle,
            description: "Разработка мобильных приложений",
            requirements: ["Swift", "UIKit"],
            benefits: ["ДМС"],
            tags: ["iOS", "Swift", "Mobile"],
            postedDate: refDate.addingTimeInterval(-86400 * 2),
            applicationDeadline: refDate.addingTimeInterval(86400 * 30),
            isRemote: false
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding().preferredColorScheme(.dark)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "fullData_dark")
    }

    func testVacancyCardView_remote() {
        let vacancy = Vacancy(
            id: "2",
            title: "Senior Swift Developer",
            company: "Тинькофф",
            location: "Удалённо",
            salary: SalaryRange(min: 300_000, max: 450_000),
            employmentType: .fullTime,
            experienceLevel: .senior,
            description: "Разработка банковских приложений",
            tags: ["iOS", "Swift", "FinTech"],
            postedDate: refDate.addingTimeInterval(-86400 * 5),
            isRemote: true
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "remote")
    }

    func testVacancyCardView_noSalary() {
        let vacancy = Vacancy(
            id: "3",
            title: "Junior iOS Developer",
            company: "VK",
            location: "Покровский бульвар 11",
            employmentType: .internship,
            experienceLevel: .junior,
            description: "Стажировка",
            tags: ["iOS", "Swift"],
            postedDate: refDate.addingTimeInterval(-3600)
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "noSalary")
    }

    func testVacancyCardView_noTags() {
        let vacancy = Vacancy(
            id: "4",
            title: "Developer",
            company: "Сбербанк",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 100_000, max: 150_000),
            employmentType: .partTime,
            experienceLevel: .middle,
            description: "Разработка",
            postedDate: refDate
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "noTags")
    }

    func testVacancyCardView_longTitle() {
        let vacancy = Vacancy(
            id: "5",
            title: "Senior iOS/Android Mobile Application Developer with Flutter Experience",
            company: "Сбербанк",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 400_000, max: 600_000),
            employmentType: .fullTime,
            experienceLevel: .lead,
            description: "Мобильная разработка",
            tags: ["iOS", "Android", "Flutter", "Dart", "Swift", "Kotlin"],
            postedDate: refDate.addingTimeInterval(-86400 * 10),
            applicationDeadline: refDate.addingTimeInterval(86400 * 5)
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "longTitle")
    }

    func testVacancyCardView_freelance() {
        let vacancy = Vacancy(
            id: "6",
            title: "Freelance iOS Developer",
            company: "Фриланс",
            location: "Удалённо",
            salary: SalaryRange(min: 2000, max: 5000, currency: "$", period: .hourly),
            employmentType: .freelance,
            experienceLevel: .senior,
            description: "Проектная работа",
            postedDate: refDate,
            isRemote: true
        )

        let view = VacancyCardView(vacancy: vacancy, now: refDate).frame(width: 350).padding()
        assertSnapshot(of: UIHostingController(rootView: view), as: .image, named: "freelance")
    }

    func testVacancyDetailView_fullData() {
        let vacancy = Vacancy(
            id: "detail-1",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 200_000, max: 350_000),
            employmentType: .fullTime,
            experienceLevel: .middle,
            description: "Разработка мобильных приложений на iOS. Участие в проектировании архитектуры. Код-ревью.",
            requirements: ["Swift 5+", "SwiftUI", "UIKit", "Combine/RxSwift", "3+ года опыта"],
            benefits: ["ДМС", "Офис в центре", "Гибкий график", "Обучение"],
            tags: ["iOS", "Swift", "Mobile", "SwiftUI"],
            postedDate: refDate.addingTimeInterval(-86400 * 2),
            applicationDeadline: refDate.addingTimeInterval(86400 * 30),
            isRemote: false
        )

        let view = NavigationView { VacancyDetailView(vacancy: vacancy, currentStageIndex: 1) }
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "fullData")
    }

    func testVacancyDetailView_atOffer() {
        let vacancy = Vacancy(
            id: "detail-2",
            title: "Senior Developer",
            company: "Тинькофф",
            location: "Удалённо",
            salary: SalaryRange(min: 400_000, max: 500_000),
            employmentType: .fullTime,
            experienceLevel: .senior,
            description: "Описание позиции",
            requirements: ["Swift", "Architecture"],
            benefits: ["Remote"],
            tags: ["iOS"],
            postedDate: refDate,
            isRemote: true
        )

        let view = NavigationView { VacancyDetailView(vacancy: vacancy, currentStageIndex: 4) }
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "atOfferStage")
    }

    func testVacancyDetailView_minimalData() {
        let vacancy = Vacancy(
            id: "detail-3",
            title: "Developer",
            company: "Стартап",
            location: "Покровский бульвар 11",
            employmentType: .contract,
            experienceLevel: .junior,
            description: "Краткое описание",
            postedDate: refDate
        )

        let view = NavigationView { VacancyDetailView(vacancy: vacancy, currentStageIndex: 0) }
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "minimalData")
    }
}
