import Foundation

public struct MessageEnvelopeWireCodec {
    public init() {}

    public func encode(_ envelope: MessageEnvelope) throws -> Data {
        try Self.makeEncoder().encode(envelope)
    }

    public func decode(_ data: Data) throws -> MessageEnvelope {
        try Self.makeDecoder().decode(MessageEnvelope.self, from: data)
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
