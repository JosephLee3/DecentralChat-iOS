//
//  ConversationIDFactory.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

enum ConversationIDFactory {
    static func makeConversationID(publicKeyA: String, publicKeyB: String) -> String {
        [publicKeyA, publicKeyB]
            .sorted()
            .map { "\($0.count):\($0)" }
            .joined(separator: "|")
    }
}
