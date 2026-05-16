import DecentralChatCore

final class AppContainer {
    static let shared = AppContainer()

    let messageStore: InMemoryMessageStore
    let identityStore: InMemoryIdentityStore
    let contactStore: InMemoryContactStore
    let transport: MockTransport
    let cryptoService: MockCryptoService
    let messageRepository: MessageRepository

    init(
        messageStore: InMemoryMessageStore = InMemoryMessageStore(),
        identityStore: InMemoryIdentityStore = InMemoryIdentityStore(),
        contactStore: InMemoryContactStore = InMemoryContactStore(),
        transport: MockTransport = MockTransport(),
        cryptoService: MockCryptoService = MockCryptoService()
    ) {
        self.messageStore = messageStore
        self.identityStore = identityStore
        self.contactStore = contactStore
        self.transport = transport
        self.cryptoService = cryptoService
        self.messageRepository = MessageRepository(
            messageStore: messageStore,
            identityStore: identityStore,
            cryptoService: cryptoService,
            transport: transport
        )
    }
}
