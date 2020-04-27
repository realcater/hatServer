import Fluent
import Vapor

struct GameController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let gameRoutes = routes.grouped("api", "games")
       
        let tokenAuthRoutes = gameRoutes.grouped(UserAuthenticator(), JWTGuardMiddleware())
        let adminAuthRoutes = gameRoutes.grouped(UserAuthenticator(), AdminMiddleware())
        
        adminAuthRoutes.get(use: getAll)
        adminAuthRoutes.delete(":gameID", use: delete)
        
        tokenAuthRoutes.post(use: create)
        tokenAuthRoutes.post(":gameID","accept", use: acceptGame)
        tokenAuthRoutes.get(":gameID", use: getGame)
        tokenAuthRoutes.post(":gameID","update", use: updateGame)
        tokenAuthRoutes.get("mine", use: getMyGamesList)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[Game]> {
        let games = Game.query(on: req.db).all()
        return games
    }

    func create(_ req: Request) throws -> EventLoopFuture<Game> {
        let userID = try? req.auth.require(JWTTokenPayload.self).userID
        let gameData = try req.content.decode(GameData.self)
        let data = try JSONEncoder().encode(gameData)
        let game = Game(data: data, userOwnerID: userID!)
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
    
    func acceptGame(_ req: Request) throws -> EventLoopFuture<HTTPStatus>{
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                guard gameData.players.map({ $0.id }).contains(userID) else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                return UserGame(userID: userID, gameID: game.id!, accepted: true).save(on: req.db).transform(to: .ok)
        }
    }
    
    func getGame(_ req: Request) throws -> EventLoopFuture<GameData> {
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).map { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                return gameData }
    }
    func updateGame(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        let updateData = try req.content.decode(UpdateData.self)
        let gameData = updateData.gameData
        let wordsData = updateData.wordsData
        
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                guard gameData.players.map({ $0.id }).contains(userID) else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                game.data = try! JSONEncoder().encode(gameData)
                return game.save(on: req.db)
                .flatMap {
                    let logGameUpdate = LogGameUpdate(data: game.data, userOwnerID: game.$userOwner.id, gameID: game.id!)
                    return logGameUpdate.save(on: req.db) }
                .flatMap {
                    let addWordToDB: [EventLoopFuture<Void>] = wordsData.map {
                        Word(word: $0.word, timeGuessed: $0.timeGuessed, guessedStatus: $0.guessedStatus, gameID: game.id!).save(on: req.db)
                    }
                    return addWordToDB.flatten(on: req.eventLoop).map { HTTPStatus.ok }
                }
            }
    }
    
    func getMyGamesList(_ req: Request) throws -> EventLoopFuture<[Game]> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        //return UserGame.query(on: req.db).filter(\.$user.$id == userID!).all()
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$games.query(on: req.db).all() }
    }
}
