import Combine
import DecentralChatCore
import Foundation
import SwiftUI

@MainActor
final class ChatRoomViewModel: ObservableObject {
    @Published var inputText: String
    @Published var messages: [ChatMessage]
    @Published var errorMessage: String?

    private let container: AppContainer
    private let contact: Contact
    private let conversationID: String

    init(
        container: AppContainer? = nil,
        contact: Contact
    ) {
        self.container = container ?? AppContainer.shared
        self.contact = contact
        self.inputText = ""
        self.messages = []
        self.errorMessage = nil
        self.conversationID = ConversationIDFactory.makeConversationID(
            publicKeyA: Self.demoPublicKey,
            publicKeyB: contact.publicKey
        )

        Task {
            try? await ensureDemoIdentity()
        }
    }

    func send() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }

        do {
            try await ensureDemoIdentity()
            try await container.messageRepository.sendText(trimmedText, to: contact)
            inputText = ""
            await reloadMessages()
        } catch {
            await reloadMessages()
            errorMessage = error.localizedDescription
        }
    }

    func retry(message: ChatMessage) async {
        errorMessage = nil

        do {
            try await container.messageRepository.retrySend(messageID: message.id)
            await reloadMessages()
        } catch {
            await reloadMessages()
            errorMessage = error.localizedDescription
        }
    }

    func reloadMessages() async {
        do {
            messages = try await container.messageStore.messages(conversationID: conversationID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func ensureDemoIdentity() async throws {
        if await container.identityStore.hasIdentity() {
            return
        }

        let identity = UserIdentity(
            id: "demo-user",
            displayName: Self.demoDisplayName,
            publicKey: Self.demoPublicKey,
            createdAt: Date()
        )

        try await container.identityStore.saveIdentity(
            identity,
            privateKeyData: Data("demo-private-key".utf8)
        )
    }

    private static let demoPublicKey = "demo-user-public-key"
    private static let demoDisplayName = "Me"
}
