import DecentralChatCore
import XCTest
@testable import DecentralChat

@MainActor
final class AppContainerInjectionTests: XCTestCase {
    func testContentViewDefaultInitializerUsesSharedContainer() {
        let view = ContentView()

        XCTAssertTrue(view.container === AppContainer.shared)
    }

    func testContactListViewDefaultInitializerUsesSharedContainer() {
        let view = ContactListView()

        XCTAssertTrue(view.container === AppContainer.shared)
    }

    func testContactListViewCanBeInitializedWithExplicitContainer() throws {
        let explicitContainer = try makeExplicitMockContainer()
        let view = ContactListView(container: explicitContainer)

        XCTAssertTrue(view.container === explicitContainer)
    }

    func testContentViewExplicitContainerDoesNotMutateSharedContainer() throws {
        let sharedContainer = AppContainer.shared
        let explicitContainer = try makeExplicitMockContainer()
        let view = ContentView(container: explicitContainer)

        XCTAssertTrue(view.container === explicitContainer)
        XCTAssertTrue(AppContainer.shared === sharedContainer)
        XCTAssertFalse(AppContainer.shared === explicitContainer)
    }

    private func makeExplicitMockContainer() throws -> AppContainer {
        try AppContainer(
            messageStore: InMemoryMessageStore(),
            identityStore: InMemoryIdentityStore(),
            contactStore: InMemoryContactStore(),
            transport: MockTransport()
        )
    }
}
