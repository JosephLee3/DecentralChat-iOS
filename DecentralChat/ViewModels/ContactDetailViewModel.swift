import Combine
import DecentralChatCore
import Foundation

@MainActor
final class ContactDetailViewModel: ObservableObject {
    @Published private(set) var contact: Contact
    @Published var isDeleting: Bool
    @Published var deleteErrorMessage: String?
    @Published var editableDisplayName: String
    @Published var editErrorMessage: String?
    @Published var isSavingEdit: Bool

    private let container: AppContainer

    init(contact: Contact, container: AppContainer? = nil) {
        self.contact = contact
        self.container = container ?? AppContainer.shared
        self.isDeleting = false
        self.deleteErrorMessage = nil
        self.editableDisplayName = contact.displayName
        self.editErrorMessage = nil
        self.isSavingEdit = false
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

    var canSaveEdit: Bool {
        !isSavingEdit && !trimmedEditableDisplayName.isEmpty
    }

    func beginEditing() {
        editableDisplayName = contact.displayName
        editErrorMessage = nil
    }

    func saveDisplayNameEdit() async -> Bool {
        guard !isSavingEdit else {
            return false
        }

        let trimmedDisplayName = trimmedEditableDisplayName
        guard !trimmedDisplayName.isEmpty else {
            editErrorMessage = "Display name is required."
            return false
        }

        guard trimmedDisplayName != contact.displayName else {
            editableDisplayName = trimmedDisplayName
            editErrorMessage = nil
            return true
        }

        isSavingEdit = true
        editErrorMessage = nil
        defer {
            isSavingEdit = false
        }

        let updatedContact = Contact(
            id: contact.id,
            displayName: trimmedDisplayName,
            publicKey: contact.publicKey,
            avatarURLString: contact.avatarURLString,
            createdAt: contact.createdAt,
            updatedAt: Date()
        )

        do {
            try await container.contactStore.save(updatedContact)
            contact = updatedContact
            editableDisplayName = trimmedDisplayName
            editErrorMessage = nil
            return true
        } catch {
            editErrorMessage = error.localizedDescription
            return false
        }
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

    private var trimmedEditableDisplayName: String {
        editableDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
