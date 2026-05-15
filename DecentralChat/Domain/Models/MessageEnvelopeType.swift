//
//  MessageEnvelopeType.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

enum MessageEnvelopeType: String, Codable, Equatable {
    case chatMessage
    case acknowledgement
    case typing
    case receipt
}
