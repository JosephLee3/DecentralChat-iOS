//
//  MessageStatus.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public enum MessageStatus: String, Codable, Equatable {
    case pending
    case sending
    case sent
    case delivered
    case failed
}
