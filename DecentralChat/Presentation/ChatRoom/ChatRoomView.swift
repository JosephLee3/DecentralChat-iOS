import DecentralChatCore
import SwiftUI

struct ChatRoomView: View {
    @StateObject private var viewModel: ChatRoomViewModel

    init() {
        let contact = Contact(
            id: "demo-contact-public-key",
            displayName: "Demo Contact",
            publicKey: "demo-contact-public-key",
            createdAt: Date()
        )
        _viewModel = StateObject(wrappedValue: ChatRoomViewModel(contact: contact))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                messageRow(message)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages.map(\.id)) { _, messageIDs in
                        scrollToLatestMessage(messageIDs, proxy: proxy)
                    }
                    .task {
                        await viewModel.reloadMessages()
                        scrollToLatestMessage(viewModel.messages.map(\.id), proxy: proxy)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    TextField("Message", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)

                    Button("Send") {
                        Task {
                            await viewModel.send()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInputEmpty)
                }
            }
            .padding()
            .navigationTitle("Demo Chat")
        }
    }

    private var isInputEmpty: Bool {
        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func messageRow(_ message: ChatMessage) -> some View {
        HStack {
            if message.isOutgoing {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(message.isOutgoing ? .white : .primary)
                    .multilineTextAlignment(message.isOutgoing ? .trailing : .leading)

                Text(message.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(message.isOutgoing ? .white.opacity(0.75) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.isOutgoing ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 280, alignment: message.isOutgoing ? .trailing : .leading)

            if !message.isOutgoing {
                Spacer(minLength: 48)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scrollToLatestMessage(_ messageIDs: [String], proxy: ScrollViewProxy) {
        guard let latestMessageID = messageIDs.last else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(latestMessageID, anchor: .bottom)
        }
    }
}

#Preview {
    ChatRoomView()
}

private extension ChatMessage {
    var isOutgoing: Bool {
        direction == .outgoing || direction == .outbound
    }
}
