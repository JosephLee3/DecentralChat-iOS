//
//  AGENTS.md
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//


# AGENTS.md

## Project

This is an iOS SwiftUI app named DecentralChat.

The goal is to build a decentralized chat app foundation using:
- SwiftUI
- MVVM
- Clean Architecture
- XCTest
- MockTransport first
- Real WebSocket later
- Real cryptography later

## Architecture Rules

- Views must only render UI.
- ViewModels must not directly access networking.
- ViewModels must not directly access SwiftData.
- ViewModels must not directly perform cryptography.
- Domain models must not import SwiftUI.
- Use protocols for Transport, Storage, Identity, and Crypto.
- Use dependency injection.
- Keep every component testable.

## Required Layers

- App
- Presentation
- Domain
- Data
- Infrastructure
- Tests

## Hard Rules

- Do not implement real WebSocket unless explicitly asked.
- Do not implement real cryptography unless explicitly asked.
- MockCryptoService is not real encryption.
- Do not introduce third-party libraries unless explicitly asked.
- Do not rename public protocols without updating all tests.
- Do not make unit tests depend on real network.
- Do not make unit tests depend on real SwiftData.
- Use MockTransport and InMemory stores for tests.

## Testing Rules

Every new core feature must include XCTest tests.

Required test style:
- Unit tests for Domain, Repository, Transport, and ViewModel
- No real network in tests
- No real Keychain in unit tests
- No real SwiftData in unit tests

## Test Command

Run:

```bash
xcodebuild test \
  -scheme DecentralChat \
  -destination 'platform=iOS Simulator,name=iPhone 15'
