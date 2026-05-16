import DecentralChatCore
import SwiftUI

struct ContactListView: View {
    @StateObject var viewModel = ContactListViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    loadingRow
                }

                if viewModel.contacts.isEmpty && !viewModel.isLoading {
                    emptyStateRow
                } else {
                    ForEach(viewModel.contacts) { contact in
                        NavigationLink {
                            ChatRoomView(contact: contact)
                        } label: {
                            contactRow(contact)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .task {
                await viewModel.loadContacts()
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading contacts")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var emptyStateRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No contacts yet")
                .font(.headline)

            Text("Demo contact will appear automatically")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private func contactRow(_ contact: Contact) -> some View {
        HStack(spacing: 12) {
            avatar(for: contact)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("Now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(shortPublicKey(contact.publicKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Tap to chat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func avatar(for contact: Contact) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 44, height: 44)

            Text(firstLetter(of: contact.displayName))
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        }
    }

    private func firstLetter(of displayName: String) -> String {
        displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(1)
            .uppercased()
    }

    private func shortPublicKey(_ publicKey: String) -> String {
        "\(publicKey.prefix(8))..."
    }
}

#Preview {
    ContactListView()
}
