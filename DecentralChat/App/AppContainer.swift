import DecentralChatCore
import Foundation

final class AppContainer {
    static let shared = try! AppContainer()

    let messageStore: MessageStore
    let identityStore: IdentityStore
    let contactStore: ContactStore
    let transport: ChatTransport
#if DEBUG
    let debugMockTransport: MockTransport
#endif
    let cryptoService: MockCryptoService
    let messageRepository: MessageRepository

    init(
        messageStore: MessageStore? = nil,
        identityStore: IdentityStore? = nil,
        contactStore: ContactStore? = nil,
        transport: ChatTransport? = nil,
        transportConfiguration: TransportConfiguration = .mock,
        cryptoService: MockCryptoService = MockCryptoService()
    ) throws {
        let persistentStores = AppPersistenceFactory.makeStores()
        let transportResult: AppTransportFactory.Result?
        let resolvedTransport: ChatTransport

        if let transport {
            transportResult = nil
            resolvedTransport = transport
        } else {
            let result = try AppTransportFactory.makeTransport(configuration: transportConfiguration)
            transportResult = result
            resolvedTransport = result.transport
        }

        self.messageStore = messageStore ?? persistentStores.messageStore
        self.identityStore = identityStore ?? persistentStores.identityStore
        self.contactStore = contactStore ?? persistentStores.contactStore
        self.transport = resolvedTransport
#if DEBUG
        self.debugMockTransport = resolvedTransport as? MockTransport ?? transportResult?.debugMockTransport ?? MockTransport()
#endif
        self.cryptoService = cryptoService
        self.messageRepository = MessageRepository(
            messageStore: self.messageStore,
            identityStore: self.identityStore,
            cryptoService: cryptoService,
            transport: self.transport
        )
    }

    func resetLocalMockData() throws {
        // Development/mock-stage helper only. This is not production account deletion,
        // and the JSON identity file is not secure key storage or secure key deletion.
        // AppContainer.shared keeps live store instances, so use this for development/testing
        // flows that are followed by app restart or container recreation.
        try LocalMockDataResetter.reset(directoryURL: AppPersistenceFactory.applicationSupportDirectoryURL())
    }
}
