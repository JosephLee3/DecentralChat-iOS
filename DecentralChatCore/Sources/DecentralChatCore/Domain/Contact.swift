//
//  Contact.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

import Foundation

public struct Contact: Codable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let publicKey: String
    public let avatarURLString: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        displayName: String,
        publicKey: String,
        avatarURLString: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.publicKey = publicKey
        self.avatarURLString = avatarURLString
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}
