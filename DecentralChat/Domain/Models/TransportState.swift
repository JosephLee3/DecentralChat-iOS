//
//  TransportState.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

enum TransportState: String, Codable, Equatable {
    case disconnected
    case connecting
    case connected
    case failed
}
