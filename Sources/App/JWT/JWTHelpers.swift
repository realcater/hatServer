import JWT
import Foundation
import Vapor

enum JWTConfig {
    static let expirationTime: TimeInterval = 60*60*24 // In seconds
}

func jwtSign(_ app: Application) throws {
    
    //let jwksFilePath = app.directory.workingDirectory + "keypair.jwks"
    guard
        //let jwks = FileManager.default.contents(atPath: jwksFilePath),
        //let jwksString = String(data: jwks, encoding: .utf8)
        let jwksString = Environment.get("KEYPAIR")
        else {
            fatalError("Failed to load JWKS Keypair")// file at: \(jwksFilePath)")
    }
    try app.jwt.signers.use(jwksJSON: jwksString)
    
    //app.jwt.signers.use(.es512(key: try .generate()))
}
