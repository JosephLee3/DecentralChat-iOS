import SwiftUI
import DecentralChatCore
import UIKit

struct ContactDetailView: View {
    @StateObject private var viewModel: ContactDetailViewModel
    @State private var didCopyPublicKey = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditDisplayName = false
    @Environment(\.dismiss) private var dismiss

    private let onDeleted: (() -> Void)?
    private let onUpdated: ((Contact) -> Void)?

    init(
        contact: Contact,
        onDeleted: (() -> Void)? = nil,
        onUpdated: ((Contact) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ContactDetailViewModel(contact: contact))
        self.onDeleted = onDeleted
        self.onUpdated = onUpdated
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    avatar

                    VStack(spacing: 4) {
                        Text(viewModel.displayName)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(viewModel.shortPublicKey)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospaced()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            Section("Details") {
                detailRow(title: "Public Key", value: viewModel.publicKey, isMonospaced: true)

                Button(didCopyPublicKey ? "Copied" : "Copy Public Key") {
                    UIPasteboard.general.string = viewModel.publicKey
                    didCopyPublicKey = true
                }

                detailRow(title: "Created At", value: viewModel.createdAtText)
                detailRow(title: "Updated At", value: viewModel.updatedAtText)
            }

            Section {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text(viewModel.isDeleting ? "Deleting..." : "Delete Contact")
                }
                .disabled(!viewModel.canDelete)

                if let deleteErrorMessage = viewModel.deleteErrorMessage {
                    Text(deleteErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Contact")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    viewModel.beginEditing()
                    isShowingEditDisplayName = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditDisplayName) {
            editDisplayNameSheet
        }
        .alert("Delete Contact?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteContact()
                    if didDelete {
                        dismiss()
                        onDeleted?()
                    }
                }
            }
        } message: {
            Text("This removes the contact from this device. Messages are not deleted.")
        }
    }

    private var editDisplayNameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: $viewModel.editableDisplayName)
                        .textInputAutocapitalization(.words)
                        .disabled(viewModel.isSavingEdit)
                }

                if let editErrorMessage = viewModel.editErrorMessage {
                    Section {
                        Text(editErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingEditDisplayName = false
                    }
                    .disabled(viewModel.isSavingEdit)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSavingEdit ? "Saving..." : "Save") {
                        Task {
                            let didSave = await viewModel.saveDisplayNameEdit()
                            if didSave {
                                onUpdated?(viewModel.contact)
                                isShowingEditDisplayName = false
                            }
                        }
                    }
                    .disabled(!viewModel.canSaveEdit || viewModel.isSavingEdit)
                }
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 96, height: 96)

            Text(viewModel.avatarLetter)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
    }

    private func detailRow(
        title: String,
        value: String,
        isMonospaced: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .fontDesign(isMonospaced ? .monospaced : .default)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            contact: Contact(
                id: "alice-public-key",
                displayName: "Alice",
                publicKey: "alice-public-key",
                avatarURLString: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
