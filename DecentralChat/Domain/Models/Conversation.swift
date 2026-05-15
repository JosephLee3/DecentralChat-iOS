//
//  Conversation.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import Foundation

struct Conversation: Codable, Equatable, Identifiable {
    let id: String
    let participantPublicKeys: [String]
    let createdAt: Date
    let updatedAt: Date
}
