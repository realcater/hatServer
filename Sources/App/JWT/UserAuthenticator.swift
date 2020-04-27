import Vapor
import JWT

struct UserAuthenticator: JWTAuthenticator {
    typealias Payload = JWTTokenPayload
    
    func authenticate(jwt: Payload, for req: Request) -> EventLoopFuture<Void> {
        req.auth.login(jwt)
        return req.eventLoop.makeSucceededFuture(())
    }
}
