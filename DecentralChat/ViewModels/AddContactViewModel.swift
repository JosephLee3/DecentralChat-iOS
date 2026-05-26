import Combine
import Foundation
import DecentralChatCore

@MainActor
final class AddContactViewModel: ObservableObject {
    @Published var displayName: String
    @Published var publicKey: String
    @Published var errorMessage: String?
    @Published var isSaving: Bool

    private let container: AppContainer

    init(container: AppContainer? = nil) {
        self.container = container ?? AppContainer.shared
        self.displayName = ""
        self.publicKey = ""
        self.errorMessage = nil
        self.isSaving = false
    }

    var canSave: Bool {
        !trimmedDisplayName.isEmpty && !trimmedPublicKey.isEmpty
    }

    func save() async -> Bool {
        guard canSave else {
            errorMessage = "Display name and public key are required."
            return false
        }

        isSaving = true
        defer {
            isSaving = false
        }

        do {
            let savedDisplayName = trimmedDisplayName
            let savedPublicKey = trimmedPublicKey
            let existingContacts = try await container.contactStore.contacts()

            if existingContacts.contains(where: { $0.publicKey == savedPublicKey }) {
                errorMessage = "A contact with this public key already exists."
                return false
            }

            let now = Date()
            let contact = Contact(
                id: savedPublicKey,
                displayName: savedDisplayName,
                publicKey: savedPublicKey,
                avatarURLString: nil,
                createdAt: now,
                updatedAt: now
            )

            try await container.contactStore.save(contact)
            displayName = ""
            publicKey = ""
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPublicKey: String {
        publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
