//
//  MessageEnvelopeType.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public enum MessageEnvelopeType: String, Codable, Equatable {
    case chatMessage
    case acknowledgement
    case typing
    case receipt
}
