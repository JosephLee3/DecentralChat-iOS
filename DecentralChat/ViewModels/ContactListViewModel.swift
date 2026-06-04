import Combine
import DecentralChatCore
import Foundation

@MainActor
final class ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact]
    @Published var chatItems: [ChatListItemViewModel]
    @Published var errorMessage: String?
    @Published var isLoading: Bool

    private let container: AppContainer
    private let timeFormatter: DateFormatter

    init(container: AppContainer? = nil) {
        self.container = container ?? AppContainer.shared
        self.contacts = []
        self.chatItems = []
        self.errorMessage = nil
        self.isLoading = false
        self.timeFormatter = DateFormatter()
        self.timeFormatter.dateStyle = .none
        self.timeFormatter.timeStyle = .short
    }

    func loadContacts() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
#if DEBUG
            // Development-only seed data. Release builds should show the true empty state.
            try await ensureDemoContact()
#endif
            let loadedContacts = try await container.contactStore.contacts()
            contacts = loadedContacts
            chatItems = try await makeChatItems(for: loadedContacts)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ensureDemoContact() async throws {
        let demoPublicKey = "demo-contact-public-key"
        let existingContact = try await container.contactStore.find(publicKey: demoPublicKey)
        guard existingContact == nil else {
            return
        }

        let now = Date()
        let contact = Contact(
            id: demoPublicKey,
            displayName: "Demo Contact",
            publicKey: demoPublicKey,
            avatarURLString: nil,
            createdAt: now,
            updatedAt: now
        )

        try await container.contactStore.save(contact)
    }

    private func makeChatItems(for contacts: [Contact]) async throws -> [ChatListItemViewModel] {
        var items: [ChatListItemViewModel] = []

        for contact in contacts {
            let conversationID = ConversationIDFactory.makeConversationID(
                publicKeyA: Self.demoPublicKey,
                publicKeyB: contact.publicKey
            )
            let messages = try await container.messageStore.messages(conversationID: conversationID)
            let latestMessage = messages.max { lhs, rhs in
                lhs.createdAt < rhs.createdAt
            }

            items.append(makeChatItem(contact: contact, latestMessage: latestMessage))
        }

        return items
    }

    private func makeChatItem(contact: Contact, latestMessage: ChatMessage?) -> ChatListItemViewModel {
        if let latestMessage {
            return ChatListItemViewModel(
                id: contact.id,
                contact: contact,
                title: contact.displayName,
                subtitle: latestMessage.body,
                timeText: timeFormatter.string(from: latestMessage.createdAt),
                statusText: latestMessage.status.rawValue
            )
        }

        return ChatListItemViewModel(
            id: contact.id,
            contact: contact,
            title: contact.displayName,
            subtitle: "Tap to chat",
            timeText: "",
            statusText: nil
        )
    }

    private static let demoPublicKey = "demo-user-public-key"
}
