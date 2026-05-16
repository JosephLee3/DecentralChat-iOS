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

## Architecture V2

The project uses a local Swift Package named `DecentralChatCore` as the core
logic module.

`DecentralChatCore` owns:
- Domain Models
- Protocols
- Repositories
- InMemory Stores
- Mocks
- Core Tests

The iOS app owns:
- SwiftUI Views
- ViewModels
- AppContainer
- Keychain
- SwiftData
- WebSocket

`DecentralChatCore` must not import:
- SwiftUI
- UIKit
- SwiftData
- CryptoKit
- Network
- WebSocket

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

Core tasks must use:

```bash
cd DecentralChatCore
swift test
```

## Verification Policy

This MacBook Air is slow when running iOS Simulator.

Default rules:
- Do not run `xcodebuild test` by default.
- Do not launch iOS Simulator by default.
- Do not run UI tests by default.
- For normal coding tasks, only run build verification.
- For `DecentralChatCore` tasks, run `cd DecentralChatCore && swift test`.
- Do not use broad `pkill` commands.
- If a process must be killed, kill only the exact stuck `xcodebuild` PID.

Preferred build verification command:

```bash
xcodebuild -project DecentralChat.xcodeproj \
  -scheme DecentralChat \
  -destination 'generic/platform=iOS' \
  build
```

If generic iOS build fails only because of signing or provisioning, use:

```bash
xcodebuild -project DecentralChat.xcodeproj \
  -scheme DecentralChat \
  -destination 'generic/platform=iOS Simulator' \
  build-for-testing
```

Final reports must include:
- Files modified
- Build command used
- Build result
- Whether Simulator was launched
- Known limitations
