import DecentralChatCore
import Foundation

final class AppContainer {
    static let shared = AppContainer()

    let messageStore: MessageStore
    let identityStore: IdentityStore
    let contactStore: ContactStore
    let transport: MockTransport
    let cryptoService: MockCryptoService
    let messageRepository: MessageRepository

    init(
        messageStore: MessageStore? = nil,
        identityStore: IdentityStore? = nil,
        contactStore: ContactStore? = nil,
        transport: MockTransport = MockTransport(),
        cryptoService: MockCryptoService = MockCryptoService()
    ) {
        let persistentStores = Self.makePersistentStores()

        self.messageStore = messageStore ?? persistentStores.messageStore
        self.identityStore = identityStore ?? persistentStores.identityStore
        self.contactStore = contactStore ?? persistentStores.contactStore
        self.transport = transport
        self.cryptoService = cryptoService
        self.messageRepository = MessageRepository(
            messageStore: self.messageStore,
            identityStore: self.identityStore,
            cryptoService: cryptoService,
            transport: transport
        )
    }

    func resetLocalMockData() throws {
        // Development/mock-stage helper only. This is not production account deletion,
        // and the JSON identity file is not secure key storage or secure key deletion.
        // AppContainer.shared keeps live store instances, so use this for development/testing
        // flows that are followed by app restart or container recreation.
        let directoryURL = Self.applicationSupportDirectoryURL()
        let fileURLs = [
            directoryURL.appendingPathComponent("contacts.json"),
            directoryURL.appendingPathComponent("messages.json"),
            directoryURL.appendingPathComponent("identity.json")
        ]

        for fileURL in fileURLs {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                continue
            }
        }
    }

    private static func makePersistentStores() -> (
        contactStore: ContactStore,
        messageStore: MessageStore,
        identityStore: IdentityStore
    ) {
        let directoryURL = applicationSupportDirectoryURL()

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            return (
                contactStore: JSONContactStore(fileURL: directoryURL.appendingPathComponent("contacts.json")),
                messageStore: JSONMessageStore(fileURL: directoryURL.appendingPathComponent("messages.json")),
                identityStore: JSONIdentityStore(fileURL: directoryURL.appendingPathComponent("identity.json"))
            )
        } catch {
            // Keep the app usable if the persistence directory cannot be prepared.
            return (
                contactStore: InMemoryContactStore(),
                messageStore: InMemoryMessageStore(),
                identityStore: InMemoryIdentityStore()
            )
        }
    }

    private static func applicationSupportDirectoryURL() -> URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DecentralChat", isDirectory: true)
    }
}
