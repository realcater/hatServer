import Vapor
import JWT

struct AdminMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let token = try? request.auth.require(JWTTokenPayload.self), token.userName == "admin" else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        return next.respond(to: request)
    }
}

struct AppMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let token = try? request.auth.require(JWTTokenPayload.self), token.userName == "app" else {
        return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        return next.respond(to: request)
    }
}

struct JWTGuardMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let _ = try? request.auth.require(JWTTokenPayload.self) else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}

