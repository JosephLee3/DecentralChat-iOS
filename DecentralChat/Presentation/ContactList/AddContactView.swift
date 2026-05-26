import SwiftUI

struct AddContactView: View {
    @StateObject private var viewModel = AddContactViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Display Name", text: $viewModel.displayName)
                    .textInputAutocapitalization(.words)

                TextField("Public Key", text: $viewModel.publicKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
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
}

#Preview {
    AddContactView()
}
