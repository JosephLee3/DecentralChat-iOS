//
//  TransportState.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public enum TransportState: String, Codable, Equatable {
    case disconnected
    case connecting
    case connected
    case failed
}
