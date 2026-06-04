import XCTest
@testable import DecentralChatCore

final class LocalMockDataResetterTests: XCTestCase {
    func testResetDeletesOnlyTargetJSONFiles() throws {
        let directoryURL = try makeTemporaryDirectory()
        let targetFilenames = ["contacts.json", "messages.json", "identity.json"]
        let unrelatedFilenames = ["notes.txt", "other.json"]

        for filename in targetFilenames + unrelatedFilenames {
            try Data(filename.utf8).write(to: directoryURL.appendingPathComponent(filename))
        }

        try LocalMockDataResetter.reset(directoryURL: directoryURL)

        for filename in targetFilenames {
            XCTAssertFalse(FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(filename).path))
        }

        for filename in unrelatedFilenames {
            XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent(filename).path))
        }
    }

    func testResetDoesNotThrowWhenTargetFilesAreMissing() throws {
        let directoryURL = try makeTemporaryDirectory()
        try Data("notes".utf8).write(to: directoryURL.appendingPathComponent("notes.txt"))

        XCTAssertNoThrow(try LocalMockDataResetter.reset(directoryURL: directoryURL))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent("notes.txt").path))
    }

    func testResetDoesNotThrowForEmptyDirectory() throws {
        let directoryURL = try makeTemporaryDirectory()

        XCTAssertNoThrow(try LocalMockDataResetter.reset(directoryURL: directoryURL))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL
    }
}
