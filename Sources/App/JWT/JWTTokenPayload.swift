import JWT
import Vapor

struct JWTTokenPayload: JWTPayload, Authenticatable, Equatable {
    var userID: UUID
    var exp: ExpirationClaim = .init(value: Date().addingTimeInterval(JWTConfig.expirationTime))

    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
