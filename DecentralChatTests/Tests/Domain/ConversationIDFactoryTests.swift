//
//  ConversationIDFactoryTests.swift
//  DecentralChatTests
//
//  Created by Joseph Lee on 5/15/26.
//

import XCTest
@testable import DecentralChat

final class ConversationIDFactoryTests: XCTestCase {
    func testMakeConversationIDIsStableRegardlessOfPublicKeyOrder() {
        let publicKeyA = "public-key-a"
        let publicKeyB = "public-key-b"

        let firstID = ConversationIDFactory.makeConversationID(
            publicKeyA: publicKeyA,
            publicKeyB: publicKeyB
        )
        let secondID = ConversationIDFactory.makeConversationID(
            publicKeyA: publicKeyB,
            publicKeyB: publicKeyA
        )

        XCTAssertEqual(firstID, secondID)
    }
}
