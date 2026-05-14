import ArchitectureCore
@testable import ChatFeature
import DiscoveryModule
import XCTest

private actor SpyChatService: ChatServicing {
    var fetchMessagesResult: Result<[ChatMessage], Error> = .success([])
    var fetchConsultantResult: Result<Consultant, Error> = .success(
        Consultant(name: "Анна", title: "Консультант", isOnline: true)
    )
    var connectResult: Result<Void, Error> = .success(())
    var sendMessageResult: Result<ChatMessage?, Error> = .success(nil)
    var handleButtonActionResult: Result<ChatMessage, Error>?
    var prepareForVacancyResult: Result<String, Error> = .success("Рекомендации")
    var reviewResumeResult: Result<(score: Double, recommendations: String), Error> = .success((7.5, "Хорошо"))
    var clearChatHistoryResult: Result<(ok: Bool, deletedConversations: Int), Error> = .success((true, 1))

    var sendMessageCallCount = 0
    var lastSentMessage: ChatMessage?

    func fetchMessages() async throws -> [ChatMessage] {
        switch fetchMessagesResult {
        case .success(let messages): return messages
        case .failure(let error): throw error
        }
    }

    func fetchConsultant() async throws -> Consultant {
        switch fetchConsultantResult {
        case .success(let consultant): return consultant
        case .failure(let error): throw error
        }
    }

    func connect() async throws {
        if case .failure(let error) = connectResult { throw error }
    }

    func disconnect() async {}

    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage? {
        sendMessageCallCount += 1
        lastSentMessage = message
        switch sendMessageResult {
        case .success(let message): return message
        case .failure(let error): throw error
        }
    }

    func handleButtonAction(_ action: ButtonAction) async throws -> ChatMessage {
        if let result = handleButtonActionResult {
            switch result {
            case .success(let message): return message
            case .failure(let error): throw error
            }
        }
        return ChatMessage(text: "Ответ", sender: .consultant)
    }

    func clearHistory() async {}

    func prepareForVacancy(vacancyId: String) async throws -> String {
        switch prepareForVacancyResult {
        case .success(let text): return text
        case .failure(let error): throw error
        }
    }

    func reviewResume() async throws -> (score: Double, recommendations: String) {
        switch reviewResumeResult {
        case .success(let payload): return payload
        case .failure(let error): throw error
        }
    }

    func clearChatHistory(conversationId: String?) async throws -> (ok: Bool, deletedConversations: Int) {
        switch clearChatHistoryResult {
        case .success(let payload): return payload
        case .failure(let error): throw error
        }
    }

    func getCoachChatHistory(pageSize: Int, pageOffset: Int) async throws -> [ChatMessage] { [] }

    func addChatMessage(conversationId: String?, content: String, isUser: Bool) async throws -> String {
        "test-id"
    }

    func setFetchMessagesResult(_ result: Result<[ChatMessage], Error>) { fetchMessagesResult = result }
    func setSendMessageResult(_ result: Result<ChatMessage?, Error>) { sendMessageResult = result }
    func setHandleButtonActionResult(_ result: Result<ChatMessage, Error>) { handleButtonActionResult = result }
    func setClearChatHistoryResult(_ result: Result<(ok: Bool, deletedConversations: Int), Error>) { clearChatHistoryResult = result }
    func setPrepareForVacancyResult(_ result: Result<String, Error>) { prepareForVacancyResult = result }
    func setReviewResumeResult(_ result: Result<(score: Double, recommendations: String), Error>) { reviewResumeResult = result }
}

private actor SpyFavoritesProvider: FavoritesProviding {
    var fetchFavoritesResult: Result<[DiscoveryState.Vacancy], Error> = .success([])

    func fetchFavorites() async throws -> [DiscoveryState.Vacancy] {
        switch fetchFavoritesResult {
        case .success(let vacancies): return vacancies
        case .failure(let error): throw error
        }
    }

    func setFetchFavoritesResult(_ result: Result<[DiscoveryState.Vacancy], Error>) { fetchFavoritesResult = result }
}

private enum TestError: LocalizedError {
    case network
    var errorDescription: String? { "Network error" }
}

@MainActor
final class ChatStoreTests: XCTestCase {
    private var chatService: SpyChatService!
    private var favoritesProvider: SpyFavoritesProvider!
    private var store: ChatStore!

    override func setUp() {
        super.setUp()
        chatService = SpyChatService()
        favoritesProvider = SpyFavoritesProvider()
        store = ChatStore(
            state: ChatState(),
            effectHandler: ChatEffectHandler(chatService: chatService, favoritesProvider: favoritesProvider)
        )
    }

    override func tearDown() {
        store = nil
        chatService = nil
        favoritesProvider = nil
        super.tearDown()
    }

    private func waitForEffects() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        await Task.yield()
    }

    func test_onAppear_success_loadsMessages() async {
        let testMessages = [
            ChatMessage(text: "Привет!", sender: .consultant)
        ]
        await chatService.setFetchMessagesResult(.success(testMessages))

        store.send(.onAppear)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertEqual(store.state.messages.count, 1)
        XCTAssertEqual(store.state.messages.first?.text, "Привет!")
    }

    func test_onAppear_failure_showsError() async {
        await chatService.setFetchMessagesResult(.failure(TestError.network))

        store.send(.onAppear)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertNotNil(store.state.error)
    }

    func test_inputTextChanged_updatesText() {
        store.send(.inputTextChanged("Привет!"))

        XCTAssertEqual(store.state.inputText, "Привет!")
    }

    func test_emptyText_sendMessage_doesNothing() {
        store.send(.inputTextChanged("   "))
        store.send(.sendMessage)

        XCTAssertTrue(store.state.messages.isEmpty)
        XCTAssertEqual(store.state.inputText, "   ")
    }

    func test_filledText_sendMessage_success_addsMessageAndReply() async {
        let reply = ChatMessage(text: "Ответ консультанта", sender: .consultant)
        await chatService.setSendMessageResult(.success(reply))

        store.send(.inputTextChanged("Привет!"))
        store.send(.sendMessage)

        XCTAssertEqual(store.state.messages.count, 1)
        XCTAssertEqual(store.state.messages.first?.text, "Привет!")
        XCTAssertEqual(store.state.messages.first?.sender, .user)
        XCTAssertEqual(store.state.inputText, "")
        XCTAssertTrue(store.state.isSending)

        await waitForEffects()

        XCTAssertFalse(store.state.isSending)
        XCTAssertEqual(store.state.messages.count, 2)
        XCTAssertEqual(store.state.messages.last?.text, "Ответ консультанта")
    }

    func test_sendMessage_failure_showsError() async {
        await chatService.setSendMessageResult(.failure(TestError.network))

        store.send(.inputTextChanged("Привет!"))
        store.send(.sendMessage)

        await waitForEffects()

        XCTAssertFalse(store.state.isSending)
        XCTAssertNotNil(store.state.error)
    }

    func test_buttonTapped_success_addsConsultantResponse() async {
        let response = ChatMessage(text: "Отлично, продолжим!", sender: .consultant)
        await chatService.setHandleButtonActionResult(.success(response))

        let button = MessageButton(text: "Да", action: .confirmYes)
        store.send(.buttonTapped(button))

        XCTAssertTrue(store.state.isSending)

        await waitForEffects()

        XCTAssertFalse(store.state.isSending)
        XCTAssertTrue(store.state.messages.contains(where: { $0.text == "Отлично, продолжим!" }))
    }

    func test_dismissError_clearsError() async {
        await chatService.setFetchMessagesResult(.failure(TestError.network))
        store.send(.onAppear)
        await waitForEffects()

        XCTAssertNotNil(store.state.error)

        store.send(.dismissError)

        XCTAssertNil(store.state.error)
    }

    func test_clearHistory_success_reloadsMessages() async {
        await chatService.setClearChatHistoryResult(.success((true, 1)))
        await chatService.setFetchMessagesResult(.success([]))

        store.send(.clearHistory)

        XCTAssertTrue(store.state.isLoading)

        await waitForEffects()

        XCTAssertFalse(store.state.isLoading)
        XCTAssertTrue(store.state.messages.isEmpty)
    }

    func test_loadFavorites_success_loadsVacancies() async {
        let vacancies = [
            DiscoveryState.Vacancy(id: "1", title: "iOS Dev", company: "Яндекс", description: "", isFavorite: true)
        ]
        await favoritesProvider.setFetchFavoritesResult(.success(vacancies))

        store.send(.showFavoritesPicker)

        await waitForEffects()

        XCTAssertEqual(store.state.favoriteVacancies.count, 1)
        XCTAssertFalse(store.state.isLoadingFavorites)
    }

    func test_systemHintTapped_setsInputText() {
        store.send(.systemHintTapped("Расскажи про свой опыт"))

        XCTAssertEqual(store.state.inputText, "Расскажи про свой опыт")
    }
}
