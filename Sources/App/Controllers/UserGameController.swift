import Fluent
import Vapor

struct UserGameController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let gameUserRoutes = routes.grouped("api")
        let tokenAuthRoutes = gameUserRoutes.grouped(Token.authenticator(), User.guardMiddleware())
        
        gameUserRoutes.post("user", ":userID", "game", ":gameID", use: addGameToUser)
        tokenAuthRoutes.get("games","mine", use: getMyGames)
    }
    func addGameToUser(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        /*
        let user = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let game = Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return user.and(game).flatMap { (user, game) in
            user.$games.attach(game, on: req.db)
        }.transform(to: .ok)
        */
        guard let userID: User.IDValue = req.parameters.get("userID") else { throw Abort(.notFound) }
        guard let gameID: Game.IDValue = req.parameters.get("gameID") else { throw Abort(.notFound) }
        return UserGame(userID: userID, gameID: gameID, accepted: false).save(on: req.db).transform(to: .ok)
    }
    
    func getMyGames(_ req: Request) throws -> EventLoopFuture<[Game]> {
        let userID = try req.auth.require(User.self).id
        //return UserGame.query(on: req.db).filter(\.$user.$id == userID!).all()
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$games.query(on: req.db).all() }
    }
}
