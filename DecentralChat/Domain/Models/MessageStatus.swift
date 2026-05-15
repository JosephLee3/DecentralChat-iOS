//
//  MessageStatus.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

enum MessageStatus: String, Codable, Equatable {
    case pending
    case sent
    case delivered
    case failed
}
