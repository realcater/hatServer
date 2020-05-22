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
    let delay: UInt32 = 0
    func boot(routes: RoutesBuilder) throws {
        let gameRoutes = routes.grouped("api", "games")
       
        let tokenAuthRoutes = gameRoutes.grouped(UserAuthenticator(), JWTGuardMiddleware())
        let adminAuthRoutes = gameRoutes.grouped(UserAuthenticator(), AdminMiddleware())
        
        adminAuthRoutes.get(use: getAll)
        tokenAuthRoutes.delete(":gameID", use: delete)
        
        tokenAuthRoutes.post(use: create)
        tokenAuthRoutes.post(":gameID","accept", use: acceptGame)
        tokenAuthRoutes.post(":gameID","reject", use: rejectGame)
        tokenAuthRoutes.get(":gameID", use: getFullData)
        tokenAuthRoutes.get(":gameID", "frequent", use: getFrequentData)
        tokenAuthRoutes.post(":gameID","update", use: updateFullData)
        tokenAuthRoutes.post(":gameID","updatefrequent", use: updateFrequentData)
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
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                guard game.$userOwner.id == userID else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                return game.delete(on: req.db).transform(to: .ok)
            }
    }
    
    func acceptGame(_ req: Request) throws -> EventLoopFuture<Game.Full>{
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                return UserGame.query(on: req.db).filter(\.$game.$id == game.id!).filter(\.$user.$id == userID).first().unwrap(or: Abort(.notFound))
                    .flatMap { userGame in
                        userGame.accepted = true
                        return userGame.update(on: req.db)
                            .map { return game.convertToFull() }
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
    
    func getFullData(_ req: Request) throws -> EventLoopFuture<Game.Full> {
        sleep(delay)
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).map { $0.convertToFull() }
    }
    func getFrequentData(_ req: Request) throws -> EventLoopFuture<Game.Frequent> {
        sleep(delay)
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        let gameID = UUID(uuidString: req.parameters.get("gameID")!)
        return UserGame.query(on: req.db).filter(\.$game.$id == gameID!).filter(\.$user.$id == userID).first().map { $0?.update(on: req.db) }
            .flatMap { _ in
                return Game.find(gameID, on: req.db)
                    .unwrap(or: Abort(.notFound)).map { $0.convertToFrequent() }
            }
    }
    
    func updateFullData(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        sleep(delay)
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        let updateData = try req.content.decode(Game.Full.self)
        let wordsData = updateData.data.wordsData
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                guard game.turn != -1 else { return req.eventLoop.makeSucceededFuture(HTTPStatus.imUsed) }
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                guard gameData.players.map({ $0.id }).contains(userID) else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                game.turn = updateData.turn
                game.guessedThisTurn = updateData.guessedThisTurn
                game.explainTime = updateData.explainTime
                game.basketChange = updateData.basketChange
                game.data = try! JSONEncoder().encode(updateData.data)
                return game.save(on: req.db)
                .flatMap {
                    let data =  try! JSONEncoder().encode(updateData)
                    let logGameUpdate = LogGameUpdate(game: data, userID: userID)
                    return logGameUpdate.save(on: req.db) }
                .flatMap {
                    let addWordToDB: [EventLoopFuture<Void>] = wordsData.map {
                        Word(word: $0.word, timeGuessed: $0.timeGuessed, guessedStatus: $0.guessedStatus, gameID: game.id!).save(on: req.db)
                    }
                    return addWordToDB.flatten(on: req.eventLoop).map { HTTPStatus.ok }
                }
            }
    }

    func updateFrequentData(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        sleep(delay)
        let frequent = try req.content.decode(Game.Frequent.self)
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { game in
                guard game.turn != -1 else { return req.eventLoop.makeSucceededFuture(HTTPStatus.imUsed) }
                game.guessedThisTurn = frequent.guessedThisTurn
                game.turn = frequent.turn
                game.explainTime = frequent.explainTime
                game.basketChange = frequent.basketChange
                return game.save(on: req.db).transform(to: .ok)
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
    func getMyGamesList(_ req: Request) throws -> EventLoopFuture<[Game.ListElement]> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$games.query(on: req.db).sort(\.$createdAt, .descending).with(\.$userOwner).group(.or) {
                $0.filter(\.$turn != -1).filter(\.$updatedAt >= Date().addingTimeInterval(-1800) )
                }.all()
            .map { $0.map { $0.convertToListElement() }}
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
