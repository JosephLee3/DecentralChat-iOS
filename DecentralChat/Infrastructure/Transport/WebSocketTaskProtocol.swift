import Foundation

protocol WebSocketTaskProtocol {
    func resume()
    func cancel()
    func sendString(_ text: String) async throws
    func receiveString() async throws -> String
}
