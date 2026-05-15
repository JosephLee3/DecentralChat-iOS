//
//  ConversationIDFactory.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public enum ConversationIDFactory {
    public static func makeConversationID(publicKeyA: String, publicKeyB: String) -> String {
        [publicKeyA, publicKeyB]
            .sorted()
            .map { "\($0.count):\($0)" }
            .joined(separator: "|")
    }
}
