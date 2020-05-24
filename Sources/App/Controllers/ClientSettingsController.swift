import Fluent
import Vapor

struct ClientSettingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let clientSettingsRoutes = routes.grouped("api", "settings")
        let appAuthRoutes = clientSettingsRoutes.grouped(UserAuthenticator(), AppMiddleware())
        appAuthRoutes.get(use: get)
    }

    func get(_ req: Request) throws -> EventLoopFuture<ClientSettings> {
        return ClientSettings.query(on: req.db).first()
            .unwrap(or: Abort(.notFound))
    }
}

