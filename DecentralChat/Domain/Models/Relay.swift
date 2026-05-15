//
//  Relay.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import Foundation

struct Relay: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let address: String
    let isEnabled: Bool
}
