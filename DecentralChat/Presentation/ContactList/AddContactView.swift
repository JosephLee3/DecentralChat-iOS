import SwiftUI

struct AddContactView: View {
    @StateObject private var viewModel = AddContactViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: $viewModel.displayName)
                        .textInputAutocapitalization(.words)

                    if let validationMessage = viewModel.displayNameValidationMessage {
                        validationText(validationMessage)
                    }
                }

                Section {
                    TextField("Public Key", text: $viewModel.publicKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let validationMessage = viewModel.publicKeyValidationMessage {
                        validationText(validationMessage)
                    }
                }

                if viewModel.isSaving {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Saving...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Section {
                        validationText(errorMessage)
                    }
                }
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let didSave = await viewModel.save()
                            if didSave {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
        }
    }

    private func validationText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }
}

#Preview {
    AddContactView()
}
