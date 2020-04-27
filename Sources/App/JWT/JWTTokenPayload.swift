import JWT
import Vapor

struct JWTTokenPayload: JWTPayload, Authenticatable, Equatable, Content {
    var userID: UUID
    var userName: String
    var exp: ExpirationClaim = .init(value: Date().addingTimeInterval(JWTConfig.expirationTime))

    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
