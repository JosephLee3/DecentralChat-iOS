import DecentralChatCore
import Foundation

struct ChatListItemViewModel: Identifiable, Equatable {
    let id: String
    let contact: Contact
    let title: String
    let subtitle: String
    let timeText: String
    let statusText: String?
}
