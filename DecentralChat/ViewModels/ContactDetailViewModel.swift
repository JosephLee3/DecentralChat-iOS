import Combine
import DecentralChatCore
import Foundation

@MainActor
final class ContactDetailViewModel: ObservableObject {
    let contact: Contact
    @Published var isDeleting: Bool
    @Published var deleteErrorMessage: String?

    private let container: AppContainer

    init(contact: Contact, container: AppContainer? = nil) {
        self.contact = contact
        self.container = container ?? AppContainer.shared
        self.isDeleting = false
        self.deleteErrorMessage = nil
    }

    var displayName: String {
        contact.displayName
    }

    var publicKey: String {
        contact.publicKey
    }

    var shortPublicKey: String {
        guard publicKey.count > 12 else {
            return publicKey
        }

        return "\(publicKey.prefix(6))...\(publicKey.suffix(4))"
    }

    var createdAtText: String {
        Self.dateFormatter.string(from: contact.createdAt)
    }

    var updatedAtText: String {
        Self.dateFormatter.string(from: contact.updatedAt)
    }

    var avatarLetter: String {
        guard let firstCharacter = displayName.first else {
            return ""
        }

        return String(firstCharacter).uppercased()
    }

    var canDelete: Bool {
        !isDeleting
    }

    func deleteContact() async -> Bool {
        guard !isDeleting else {
            return false
        }

        isDeleting = true
        deleteErrorMessage = nil
        defer {
            isDeleting = false
        }

        do {
            try await container.contactStore.deleteContact(id: contact.id)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            return false
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
