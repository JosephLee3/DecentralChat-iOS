import DecentralChatCore
import Foundation

enum AppPersistenceFactory {
    static func makeStores() -> (
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

    static func applicationSupportDirectoryURL() -> URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DecentralChat", isDirectory: true)
    }
}
