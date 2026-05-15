//
//  ConversationIDFactoryTests.swift
//  DecentralChatCoreTests
//
//  Created by Joseph Lee on 5/16/26.
//

import DecentralChatCore
import XCTest

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
