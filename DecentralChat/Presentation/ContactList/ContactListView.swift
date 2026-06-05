import DecentralChatCore
import SwiftUI

struct ContactListView: View {
    let container: AppContainer
    @StateObject private var viewModel: ContactListViewModel
    @State private var isShowingAddContact = false

    init(container: AppContainer = .shared) {
        self.container = container
        _viewModel = StateObject(wrappedValue: ContactListViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    loadingRow
                }

                if viewModel.chatItems.isEmpty && !viewModel.isLoading {
                    emptyStateRow
                } else {
                    ForEach(viewModel.chatItems) { item in
                        NavigationLink {
                            ChatRoomView(
                                contact: item.contact,
                                onDeleted: {
                                    Task {
                                        await viewModel.loadContacts()
                                    }
                                },
                                onUpdated: { _ in
                                    Task {
                                        await viewModel.loadContacts()
                                    }
                                }
                            )
                        } label: {
                            contactRow(item)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .toolbar {
#if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        DebugToolsView()
                    } label: {
                        Text("Debug")
                    }
                }
#endif

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddContact = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddContact, onDismiss: {
                Task {
                    await viewModel.loadContacts()
                }
            }) {
                AddContactView()
            }
            .onAppear {
                Task {
                    await viewModel.loadContacts()
                }
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
            Text("No contacts")
                .font(.headline)

            Text("Tap + to add a contact")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private func contactRow(_ item: ChatListItemViewModel) -> some View {
        HStack(spacing: 12) {
            avatar(title: item.title)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if !item.timeText.isEmpty {
                        Text(item.timeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if let statusText = item.statusText {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func avatar(title: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 44, height: 44)

            Text(firstLetter(of: title))
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
}

#Preview {
    ContactListView()
}
