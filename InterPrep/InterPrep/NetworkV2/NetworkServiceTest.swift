import Foundation

@MainActor
class NetworkServiceTest {
    private let service = NetworkServiceV2.shared
    
    func testLogin() async {
        print("🧪 Testing Login...")
        
        let result = await service.login(
            email: "test3@example.com",
            password: "password123"
        )
        
        switch result {
        case .success(let response):
            print("✅ Login successful!")
            print("   Access Token: \(response.accessToken.prefix(20))...")
            print("   User: \(response.user.firstName) \(response.user.lastName)")
            print("   Email: \(response.user.email)")
        case .failure(let error):
            print("❌ Login failed: \(error.localizedDescription)")
        }
    }
    
    func testSearchJobs() async {
        print("\n🧪 Testing Search Jobs...")
        
        let result = await service.searchJobs(page: 0, perPage: 5)
        
        switch result {
        case .success(let response):
            print("✅ Search successful!")
            print("   Found: \(response.found) jobs")
            print("   Page: \(response.page + 1)/\(response.pages)")
            print("   Jobs on this page: \(response.items.count)")
            
            for (index, job) in response.items.prefix(3).enumerated() {
                print("\n   Job \(index + 1):")
                print("   - Title: \(job.name)")
                print("   - Company: \(job.employerName)")
                print("   - Location: \(job.areaName)")
                if let salary = job.salaryString {
                    print("   - Salary: \(salary)")
                }
            }
        case .failure(let error):
            print("❌ Search failed: \(error.localizedDescription)")
        }
    }
    
    func testGetMe() async {
        print("\n🧪 Testing Get Me...")
        
        let result = await service.getMe()
        
        switch result {
        case .success(let response):
            print("✅ Get Me successful!")
            print("   User: \(response.user.displayName)")
            print("   Email: \(response.user.email)")
            print("   Resume uploaded: \(response.user.resumeUploaded)")
            print("   Total interviews: \(response.user.totalInterviews)")
            print("   Completed: \(response.user.completedInterviews)")
            print("   Upcoming: \(response.user.upcomingInterviews)")
        case .failure(let error):
            print("❌ Get Me failed: \(error.localizedDescription)")
        }
    }
    
    func testAskCoach() async {
        print("\n🧪 Testing Ask Coach...")
        
        let result = await service.ask(
            question: "Привет! Что чаще всего спрашивают на собеседованиях на Golang разработчика?"
        )
        
        switch result {
        case .success(let response):
            print("✅ Ask successful!")
            print("   Conversation ID: \(response.conversationID)")
            print("   Answer: \(response.answer.prefix(200))...")
        case .failure(let error):
            print("❌ Ask failed: \(error.localizedDescription)")
        }
    }
    
    func runAllTests() async {
        print("🚀 Starting Network Service Tests\n")
        print("=" + String(repeating: "=", count: 50))
        
        await testLogin()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await testGetMe()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await testSearchJobs()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await testAskCoach()
        
        print("\n" + String(repeating: "=", count: 50))
        print("✅ All tests completed!")
    }
}
