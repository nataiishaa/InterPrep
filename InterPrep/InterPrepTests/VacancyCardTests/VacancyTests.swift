@testable import VacancyCardFeature
import XCTest

final class VacancyTests: XCTestCase {

    func testSalaryRange_formatted_returnsCorrectString() {
        let salary = SalaryRange(min: 200_000, max: 350_000, currency: "₽", period: .monthly)

        XCTAssertEqual(salary.formatted, "200 000–350 000 ₽")
    }

    func testSalaryRange_formatted_handlesSmallNumbers() {
        let salary = SalaryRange(min: 1000, max: 2000, currency: "$", period: .hourly)

        XCTAssertEqual(salary.formatted, "1 000–2 000 $")
    }

    func testSalaryRange_formatted_handlesSameMinMax() {
        let salary = SalaryRange(min: 150_000, max: 150_000)

        XCTAssertEqual(salary.formatted, "150 000–150 000 ₽")
    }

    func testSalaryRange_defaultValues() {
        let salary = SalaryRange(min: 100, max: 200)

        XCTAssertEqual(salary.currency, "₽")
        XCTAssertEqual(salary.period, .monthly)
    }

    func testEmploymentType_displayName_fullTime() {
        XCTAssertEqual(EmploymentType.fullTime.displayName, "Полная занятость")
    }

    func testEmploymentType_displayName_partTime() {
        XCTAssertEqual(EmploymentType.partTime.displayName, "Частичная занятость")
    }

    func testEmploymentType_displayName_contract() {
        XCTAssertEqual(EmploymentType.contract.displayName, "Контракт")
    }

    func testEmploymentType_displayName_internship() {
        XCTAssertEqual(EmploymentType.internship.displayName, "Стажировка")
    }

    func testEmploymentType_displayName_freelance() {
        XCTAssertEqual(EmploymentType.freelance.displayName, "Фриланс")
    }

    func testEmploymentType_allCases() {
        XCTAssertEqual(EmploymentType.allCases.count, 5)
    }

    func testExperienceLevel_displayName_intern() {
        XCTAssertEqual(ExperienceLevel.intern.displayName, "Стажёр")
    }

    func testExperienceLevel_displayName_junior() {
        XCTAssertEqual(ExperienceLevel.junior.displayName, "Junior")
    }

    func testExperienceLevel_displayName_middle() {
        XCTAssertEqual(ExperienceLevel.middle.displayName, "Middle")
    }

    func testExperienceLevel_displayName_senior() {
        XCTAssertEqual(ExperienceLevel.senior.displayName, "Senior")
    }

    func testExperienceLevel_displayName_lead() {
        XCTAssertEqual(ExperienceLevel.lead.displayName, "Lead")
    }

    func testExperienceLevel_allCases() {
        XCTAssertEqual(ExperienceLevel.allCases.count, 5)
    }

    func testSalaryPeriod_displayName_hourly() {
        XCTAssertEqual(SalaryPeriod.hourly.displayName, "в час")
    }

    func testSalaryPeriod_displayName_monthly() {
        XCTAssertEqual(SalaryPeriod.monthly.displayName, "в месяц")
    }

    func testSalaryPeriod_displayName_yearly() {
        XCTAssertEqual(SalaryPeriod.yearly.displayName, "в год")
    }

    func testVacancy_initialization() {
        let vacancy = Vacancy(
            id: "vacancy-1",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 100_000, max: 200_000),
            employmentType: .fullTime,
            experienceLevel: .middle,
            description: "Разработка мобильных приложений",
            requirements: ["Swift", "UIKit"],
            benefits: ["ДМС"],
            tags: ["iOS"],
            postedDate: Date(),
            applicationDeadline: Date().addingTimeInterval(86400 * 30),
            isRemote: true,
            companyLogo: "yandex.png"
        )

        XCTAssertEqual(vacancy.id, "vacancy-1")
        XCTAssertEqual(vacancy.title, "iOS Developer")
        XCTAssertEqual(vacancy.company, "Яндекс")
        XCTAssertEqual(vacancy.location, "Покровский бульвар 11")
        XCTAssertNotNil(vacancy.salary)
        XCTAssertEqual(vacancy.employmentType, .fullTime)
        XCTAssertEqual(vacancy.experienceLevel, .middle)
        XCTAssertEqual(vacancy.description, "Разработка мобильных приложений")
        XCTAssertEqual(vacancy.requirements.count, 2)
        XCTAssertEqual(vacancy.benefits.count, 1)
        XCTAssertEqual(vacancy.tags.count, 1)
        XCTAssertNotNil(vacancy.applicationDeadline)
        XCTAssertTrue(vacancy.isRemote)
        XCTAssertEqual(vacancy.companyLogo, "yandex.png")
    }

    func testVacancy_defaultValues() {
        let vacancy = Vacancy(
            id: "vacancy-2",
            title: "Developer",
            company: "Тинькофф",
            location: "Покровский бульвар 11",
            employmentType: .fullTime,
            experienceLevel: .junior,
            description: "Desc",
            postedDate: Date()
        )

        XCTAssertNil(vacancy.salary)
        XCTAssertTrue(vacancy.requirements.isEmpty)
        XCTAssertTrue(vacancy.benefits.isEmpty)
        XCTAssertTrue(vacancy.tags.isEmpty)
        XCTAssertNil(vacancy.applicationDeadline)
        XCTAssertFalse(vacancy.isRemote)
        XCTAssertNil(vacancy.companyLogo)
    }

    func testVacancy_equatable() {
        let date = Date()
        let vacancy1 = Vacancy(
            id: "vacancy-eq",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            employmentType: .fullTime,
            experienceLevel: .junior,
            description: "Разработка",
            postedDate: date
        )
        let vacancy2 = Vacancy(
            id: "vacancy-eq",
            title: "iOS Developer",
            company: "Яндекс",
            location: "Покровский бульвар 11",
            employmentType: .fullTime,
            experienceLevel: .junior,
            description: "Разработка",
            postedDate: date
        )

        XCTAssertEqual(vacancy1, vacancy2)
    }

    func testVacancy_identifiable() {
        let vacancy = Vacancy(
            id: "vacancy-unique",
            title: "Developer",
            company: "VK",
            location: "Покровский бульвар 11",
            employmentType: .fullTime,
            experienceLevel: .junior,
            description: "Описание",
            postedDate: Date()
        )

        XCTAssertEqual(vacancy.id, "vacancy-unique")
    }

    func testVacancy_encodeDecode() throws {
        let original = Vacancy(
            id: "vacancy-encode",
            title: "QA Engineer",
            company: "Сбербанк",
            location: "Покровский бульвар 11",
            salary: SalaryRange(min: 50_000, max: 100_000),
            employmentType: .contract,
            experienceLevel: .senior,
            description: "Тестирование",
            requirements: ["Autotests", "Swift"],
            benefits: ["ДМС"],
            tags: ["QA", "iOS"],
            postedDate: Date(timeIntervalSince1970: 1700000000),
            applicationDeadline: Date(timeIntervalSince1970: 1710000000),
            isRemote: true,
            companyLogo: "sber.png"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Vacancy.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testSalaryRange_encodeDecode() throws {
        let original = SalaryRange(min: 100, max: 200, currency: "€", period: .yearly)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SalaryRange.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testEmploymentType_rawValue() {
        XCTAssertEqual(EmploymentType.fullTime.rawValue, "full_time")
        XCTAssertEqual(EmploymentType.partTime.rawValue, "part_time")
        XCTAssertEqual(EmploymentType.contract.rawValue, "contract")
        XCTAssertEqual(EmploymentType.internship.rawValue, "internship")
        XCTAssertEqual(EmploymentType.freelance.rawValue, "freelance")
    }

    func testEmploymentType_initFromRawValue() {
        XCTAssertEqual(EmploymentType(rawValue: "full_time"), .fullTime)
        XCTAssertEqual(EmploymentType(rawValue: "part_time"), .partTime)
        XCTAssertNil(EmploymentType(rawValue: "invalid"))
    }
}
