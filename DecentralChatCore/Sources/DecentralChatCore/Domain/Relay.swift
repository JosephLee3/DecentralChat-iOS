//
//  Relay.swift
//  DecentralChatCore
//
//  Created by Joseph Lee on 5/16/26.
//

public struct Relay: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let address: String
    public let isEnabled: Bool

    public init(id: String, name: String, address: String, isEnabled: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.isEnabled = isEnabled
    }
}
