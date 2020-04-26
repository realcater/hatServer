import JWT
import Foundation
import Vapor

extension String {
    var bytes: [UInt8] { .init(self.utf8) }
}

extension JWKIdentifier {
    static let `public` = JWKIdentifier(string: "public")
    static let `private` = JWKIdentifier(string: "private")
}

enum JWTConfig {
    static let expirationTime: TimeInterval = 50 // In seconds
}

func jwtSign(_ app: Application) throws {
    /*
    let privateKey = try String(contentsOfFile: app.directory.workingDirectory + "jwtRS256.key")
    let privateSigner = try JWTSigner.rs256(key: .private(pem: privateKey.bytes))
    let publicKey = try String(contentsOfFile: app.directory.workingDirectory + "jwtRS256.key.pub")
    let publicSigner = try JWTSigner.rs256(key: .public(pem: publicKey.bytes))

    app.jwt.signers.use(privateSigner, kid: .private)
    app.jwt.signers.use(publicSigner, kid: .public, isDefault: true)
    */
    app.jwt.signers.use(.es512(key: try .generate()))
}
