import Vapor

struct AdminMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = try? request.auth.require(User.self), user.name == "admin" else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        return next.respond(to: request)
    }
}

struct AppMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = try? request.auth.require(User.self), user.name == "app" else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        return next.respond(to: request)
    }
}
