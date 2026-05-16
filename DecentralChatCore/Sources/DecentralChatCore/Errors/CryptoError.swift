public enum CryptoError: Error, Equatable {
    case invalidEnvelope
    case unsupportedEnvelopeVersion
    case decryptFailed
    case invalidSignature
}
