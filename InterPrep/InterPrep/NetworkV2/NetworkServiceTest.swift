import Foundation

@MainActor
class NetworkServiceTest {
    private let service = NetworkServiceV2.shared
    
    func testLogin() async {
        _ = await service.login(
            email: "test3@example.com",
            password: "password123"
        )
    }
    
    func testSearchJobs() async {
        _ = await service.searchJobs(page: 0, perPage: 5)
    }
    
    func testGetMe() async {
        _ = await service.getMe()
    }
    
    func testAskCoach() async {
        _ = await service.ask(
            question: "Привет! Что чаще всего спрашивают на собеседованиях на Golang разработчика?"
        )
    }
    
    func runAllTests() async {
        await testLogin()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await testGetMe()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await testSearchJobs()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await testAskCoach()
    }
}
