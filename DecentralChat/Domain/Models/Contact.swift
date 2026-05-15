//
//  Contact.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import Foundation

struct Contact: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let publicKey: String
    let createdAt: Date
}
