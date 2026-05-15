//
//  Conversation.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

import Foundation

public struct Conversation: Codable, Equatable, Identifiable {
    public let id: String
    public let participantPublicKeys: [String]
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, participantPublicKeys: [String], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.participantPublicKeys = participantPublicKeys
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
