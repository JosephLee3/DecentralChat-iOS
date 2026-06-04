import Foundation

public enum LocalMockDataResetter {
    private static let targetFilenames = [
        "contacts.json",
        "messages.json",
        "identity.json"
    ]

    public static func reset(directoryURL: URL) throws {
        for filename in targetFilenames {
            let fileURL = directoryURL.appendingPathComponent(filename)

            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                continue
            }
        }
    }
}
