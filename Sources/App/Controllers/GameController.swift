/*
Non-admin requests (used in APP)
 
POST
/api/games
/api/games/gamesID/accept
/api/games/gamesID/update

GET
/api/games
/api/mine

 */

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
        tokenAuthRoutes.post(":gameID","reject", use: rejectGame)
        tokenAuthRoutes.get(":gameID", use: getGameData)
        tokenAuthRoutes.post(":gameID","update", use: updateGame)
        tokenAuthRoutes.get("mine", use: getMyGamesList)
        tokenAuthRoutes.get(":gameID", "players", use: getPlayersStatus)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[Game]> {
        let games = Game.query(on: req.db).all()
        return games
    }

    func create(_ req: Request) throws -> EventLoopFuture<Game.UUIDOnly> {
        let userID = try? req.auth.require(JWTTokenPayload.self).userID
        let gameData = try req.content.decode(GameData.self)
        let data = try JSONEncoder().encode(gameData)
        let game = Game(data: data, userOwnerID: userID!)
        return game.save(on: req.db)
            .flatMap {
                let usersAddToGame: [EventLoopFuture<Void>] = gameData.players.map {
                    let accepted = ($0.id == userID!)
                    return UserGame(userID: $0.id, gameID: game.id!, userOwnerID: userID!, accepted: accepted).save(on: req.db)
                }
                return usersAddToGame.flatten(on: req.eventLoop).map { game.convertToUUIDOnly() }
            }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func acceptGame(_ req: Request) throws -> EventLoopFuture<GameData>{
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                return UserGame.query(on: req.db).filter(\.$game.$id == game.id!).filter(\.$user.$id == userID).first().unwrap(or: Abort(.notFound))
                    .flatMap { userGame in
                        userGame.accepted = true
                        return userGame.update(on: req.db)
                            .map { return gameData }
                }
            }
    }
    func rejectGame(_ req: Request) throws -> EventLoopFuture<HTTPStatus>{
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        let gameID = UUID(uuidString: req.parameters.get("gameID")!)
        return UserGame.query(on: req.db).filter(\.$game.$id == gameID!).filter(\.$user.$id == userID).first().unwrap(or: Abort(.notFound))
            .flatMap { userGame in
                userGame.accepted = false
                return userGame.update(on: req.db).transform(to: .ok)
            }
    }
    
    func getGameData(_ req: Request) throws -> EventLoopFuture<GameData> {
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).map { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                return gameData }
    }
    
    
    
    func updateGame(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        let gameData = try req.content.decode(GameData.self)
        let wordsData = gameData.wordsData
        
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
    
    func getPlayersStatus(_ req: Request) throws -> EventLoopFuture<[PlayerStatus]> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        guard let uuidString = req.parameters.get("gameID"), let gameID = UUID(uuidString: uuidString) else { throw Abort(.notFound) }
        // update a record user/game just to renew "updatedAt" (using to check if user is online)
        return UserGame.query(on: req.db).filter(\.$game.$id == gameID).filter(\.$user.$id == userID).first().map { $0?.update(on: req.db) }
            .flatMap { _ in
                //other players' status return
                UserGame.query(on: req.db).filter(\.$game.$id == gameID).all()
                .map {
                    $0.map { PlayerStatus(playerID: $0.$user.id, accepted: $0.accepted, lastTimeInGame: $0.updatedAt!) }
                }
        }
    }
    
    func getMyGamesList(_ req: Request) throws -> EventLoopFuture<[Game.Public]> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$games.query(on: req.db).sort(\.$createdAt, .descending).with(\.$userOwner).all()
            .map { $0.map {
                Game.Public(gameID: $0.id!, userOwnerName: $0.userOwner.name, createdAt: $0.createdAt!)
                }
            }
        }
    }
}

struct PlayerStatus: Content {
    var playerID: UUID
    var accepted: Bool
    var lastTimeInGame: Date
}

struct WordData: Codable, Content {
    var word: String
    var timeGuessed: Int
    var guessedStatus: GuessedStatus
}



