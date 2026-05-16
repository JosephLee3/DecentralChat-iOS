//
//  MessageDirection.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public enum MessageDirection: String, Codable, Equatable {
    case incoming
    case inbound
    case outgoing
    case outbound
}
