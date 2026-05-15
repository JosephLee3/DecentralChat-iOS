//
//  UserIdentity.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

import Foundation

public struct UserIdentity: Codable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let publicKey: String
    public let createdAt: Date

    public init(id: String, displayName: String, publicKey: String, createdAt: Date) {
        self.id = id
        self.displayName = displayName
        self.publicKey = publicKey
        self.createdAt = createdAt
    }
}
