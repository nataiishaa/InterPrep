@testable import ProfileFeature
import SnapshotTesting
import SwiftUI
import XCTest

final class ProfileViewSnapshotTests: SnapshotTestCase {

    func testProfileView_loaded_light() {
        let user = ProfileState.User(
            id: "user-1",
            firstName: "Наталья",
            lastName: "Захарова",
            email: "natalia.zakharova@mail.ru",
            phone: "+7 999 123-45-67",
            avatarURL: nil,
            position: "iOS Developer",
            experience: "3 года",
            resumeUploaded: true,
            registeredDate: Date()
        )

        let statistics = ProfileState.Statistics(
            totalInterviews: 15,
            completedInterviews: 12,
            upcomingInterviews: 3,
            totalApplications: 25,
            responseRate: 48,
            averagePreparationTime: 45
        )

        let model = ProfileView.Model.fixture(user: user, statistics: statistics)
        let view = ProfileView(model: model)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "loaded_light")
    }

    func testProfileView_loaded_dark() {
        let user = ProfileState.User(
            id: "user-1",
            firstName: "Наталья",
            lastName: "Захарова",
            email: "natalia.zakharova@mail.ru",
            phone: nil,
            avatarURL: nil,
            position: "iOS Developer",
            experience: nil,
            resumeUploaded: true,
            registeredDate: nil
        )

        let statistics = ProfileState.Statistics(
            totalInterviews: 5,
            completedInterviews: 5,
            upcomingInterviews: 0,
            totalApplications: 10,
            responseRate: 50,
            averagePreparationTime: 30
        )

        let model = ProfileView.Model.fixture(user: user, statistics: statistics)
        let view = ProfileView(model: model).preferredColorScheme(.dark)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "loaded_dark")
    }

    func testProfileView_loading() {
        let model = ProfileView.Model.fixture()
        let view = ProfileView(model: model)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "loading")
    }

    func testProfileView_noResume() {
        let user = ProfileState.User(
            id: "user-new",
            firstName: "Наталья",
            lastName: "Захарова",
            email: "natalia.zakharova@mail.ru",
            phone: nil,
            avatarURL: nil,
            position: nil,
            experience: nil,
            resumeUploaded: false,
            registeredDate: Date()
        )

        let model = ProfileView.Model.fixture(user: user, statistics: ProfileState.Statistics(), hasResumeData: false)
        let view = ProfileView(model: model)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "noResume")
    }

    func testProfileView_withError() {
        let model = ProfileView.Model.fixture()
        let view = ProfileView(model: model)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13Pro), named: "withError")
    }

    func testProfileView_iPhoneSE() {
        let user = ProfileState.User(
            id: "user-se",
            firstName: "Наталья",
            lastName: "Захарова",
            email: "natalia.zakharova@mail.ru",
            phone: nil,
            avatarURL: nil,
            position: "Senior iOS Developer",
            experience: "5 лет",
            resumeUploaded: true,
            registeredDate: nil
        )

        let statistics = ProfileState.Statistics(
            totalInterviews: 25,
            completedInterviews: 20,
            upcomingInterviews: 5,
            totalApplications: 50,
            responseRate: 60,
            averagePreparationTime: 60
        )

        let model = ProfileView.Model.fixture(user: user, statistics: statistics)
        let view = ProfileView(model: model)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhoneSe), named: "iPhoneSE")
    }
}

extension ProfileView.Model {
    static func fixture(
        user: ProfileState.User = ProfileState.User(
            id: "user-1",
            firstName: "Наталья",
            lastName: "Захарова",
            email: "natalia.zakharova@mail.ru",
            phone: nil,
            avatarURL: nil,
            position: nil,
            experience: nil,
            resumeUploaded: false,
            registeredDate: nil
        ),
        statistics: ProfileState.Statistics = ProfileState.Statistics(),
        hasResumeData: Bool = false
    ) -> Self {
        let editModel = ProfileEditView.Model(
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            cachedProfilePhotoURL: nil,
            avatarURL: user.avatarURL,
            errorMessage: nil,
            onPhotoSelected: { _ in },
            onFirstNameChanged: { _ in },
            onLastNameChanged: { _ in },
            onSave: {},
            onCancel: {}
        )
        return Self(
            user: user,
            cachedProfilePhotoURL: nil,
            statistics: statistics,
            settings: ProfileState.AppSettings(),
            deleteAccountError: nil,
            selectedInterviewTab: .upcoming,
            upcomingInterviews: [],
            completedInterviews: [],
            isLoadingInterviews: false,
            hasResumeData: hasResumeData,
            isOfflineMode: false,
            onNotificationsToggled: { _ in },
            onThemeChanged: { _ in },
            onChangeResume: {},
            onViewResume: {},
            onLogout: {},
            onDeleteAccount: { _ in },
            onClearDeleteAccountError: {},
            onInterviewTabChanged: { _ in },
            onInterviewTapped: { _ in },
            onEditProfileTapped: nil,
            editModel: editModel
        )
    }
}
