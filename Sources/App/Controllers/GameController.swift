import Fluent
import Vapor

struct GameController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let gameRoutes = routes.grouped("api", "games")
        let tokenAuthRoutes = gameRoutes.grouped(Token.authenticator(), User.guardMiddleware())
        let adminAuthRoutes = tokenAuthRoutes.grouped(AdminMiddleware())
        
        adminAuthRoutes.get(use: getAll)
        adminAuthRoutes.delete(":gameID", use: delete)
        
        tokenAuthRoutes.post(use: create)
        tokenAuthRoutes.post(":gameID","accept", use: acceptGame)
        tokenAuthRoutes.get(":gameID","update", use: getUpdate)
        tokenAuthRoutes.post(":gameID","update", use: setUpdate)
        tokenAuthRoutes.get("mine", use: getMyGames)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[Game]> {
        let games = Game.query(on: req.db).all()
        return games
    }

    func create(_ req: Request) throws -> EventLoopFuture<Game> {
        let user = try req.auth.require(User.self)
        let gameData = try req.content.decode(GameData.self)
        let data = try JSONEncoder().encode(gameData)
        let game = Game(data: data, userOwnerID: user.id!)
        return game.save(on: req.db)
            .flatMap {
            let usersAddToGame: [EventLoopFuture<Void>] = gameData.players.map {
                    UserGame(userID: $0.id, gameID: game.id!, accepted: false).save(on: req.db)
            }
            return usersAddToGame.flatten(on: req.eventLoop).map { game }
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func acceptGame(_ req: Request) throws -> EventLoopFuture<GameData> {
        //let user = try req.auth.require(User.self)
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).map { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                return gameData }
    }
    
    func getUpdate(_ req: Request) throws -> EventLoopFuture<GameData> {
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).map { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                return gameData }
    }
    func setUpdate(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        //let user = try req.auth.require(User.self)
        let gameData = try req.content.decode(GameData.self)
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { game in
                game.data = try! JSONEncoder().encode(gameData)
                return game.save(on: req.db).transform(to: HTTPStatus.ok)
        }
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
