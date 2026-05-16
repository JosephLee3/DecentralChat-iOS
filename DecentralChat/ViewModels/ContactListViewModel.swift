import Combine
import DecentralChatCore
import Foundation

@MainActor
final class ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact]
    @Published var errorMessage: String?
    @Published var isLoading: Bool

    private let container: AppContainer

    init(container: AppContainer? = nil) {
        self.container = container ?? AppContainer.shared
        self.contacts = []
        self.errorMessage = nil
        self.isLoading = false
    }

    func loadContacts() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            try await ensureDemoContact()
            contacts = try await container.contactStore.contacts()
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
}
