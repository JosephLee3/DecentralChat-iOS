import SwiftUI
import DecentralChatCore
import UIKit

struct ContactDetailView: View {
    @StateObject private var viewModel: ContactDetailViewModel
    @State private var didCopyPublicKey = false

    init(contact: Contact) {
        _viewModel = StateObject(wrappedValue: ContactDetailViewModel(contact: contact))
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
        }
        .navigationTitle("Contact")
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
