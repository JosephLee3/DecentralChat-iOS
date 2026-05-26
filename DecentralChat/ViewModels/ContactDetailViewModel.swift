import Combine
import DecentralChatCore
import Foundation

@MainActor
final class ContactDetailViewModel: ObservableObject {
    let contact: Contact

    init(contact: Contact) {
        self.contact = contact
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
