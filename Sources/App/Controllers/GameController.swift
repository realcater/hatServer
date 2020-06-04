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
        tokenAuthRoutes.post("join", use: joinGame)
        tokenAuthRoutes.post(":gameID","addPlayer", use: addPlayer)
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

    func create(_ req: Request) throws -> EventLoopFuture<Game.Created> {
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
                return usersAddToGame.flatten(on: req.eventLoop).map { game.convertToCreated() }
            }
    }

    func joinGame(_ req: Request) throws -> EventLoopFuture<Game.Full> {
        let data = try req.content.decode(JoinData.self)
        let code = data.code
        let additionalName = data.additionalName

        let userID = try? req.auth.require(JWTTokenPayload.self).userID
        return Game.query(on: req.db).filter(\.$code == code).first()
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                guard game.turn == -1 else {
                    return req.eventLoop.makeFailedFuture(Abort(.unprocessableEntity))
                }
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                guard !gameData.players.map({ $0.id }).contains(userID) || additionalName != nil else {
                    let index = gameData.players.firstIndex(where: { $0.id == userID})!
                    gameData.players[index].accepted = true
                    game.data = try! JSONEncoder().encode(gameData)
                    return game.save(on: req.db).map { game.convertToFull() }
                }
                return User.find(userID, on: req.db).unwrap(or: Abort(.notFound))
                    .flatMap { user in
                        let name: String = additionalName ?? user.name
                        let player = Player(id: user.id!, name: name, accepted: true, lastTimeInGame: Date())
                        gameData.players.append(player)
                        game.data = try! JSONEncoder().encode(gameData)
                        return game.save(on: req.db)
                            .flatMap {
                                let userGame = UserGame(userID: user.id!, gameID: game.id!, userOwnerID: game.$userOwner.id, accepted: player.accepted)
                                return userGame.save(on: req.db).map { game.convertToFull() }
                        }
                }
        }
    }
    
    func addPlayer(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let player = try req.content.decode(Player.self)
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                guard game.turn == -1 else {
                    return req.eventLoop.makeFailedFuture(Abort(.unprocessableEntity))
                }
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                gameData.players.append(player)
                game.data = try! JSONEncoder().encode(gameData)
                return game.save(on: req.db)
                    .flatMap {
                        let userGame = UserGame(userID: player.id, gameID: game.id!, userOwnerID: game.$userOwner.id, accepted: player.accepted)
                        return userGame.save(on: req.db).transform(to: .ok)
                    }
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
                GameCode.delete(code: game.code)
                return game.delete(on: req.db).transform(to: .ok)
            }
    }
    
    func acceptGame(_ req: Request) throws -> EventLoopFuture<Game.Full>{
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return Game.find(req.parameters.get("gameID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { game in
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                gameData.players.first( where: {$0.id == userID })?.accepted = true
                game.data = try! JSONEncoder().encode(gameData)
                return game.save(on: req.db).map { game.convertToFull() }
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
                guard game.turn != K.endTurnNumber else { return req.eventLoop.makeSucceededFuture(HTTPStatus.imUsed) }
                let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                guard gameData.players.map({ $0.id }).contains(userID) else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                game.turn = updateData.turn
                if game.turn == K.endTurnNumber {
                    GameCode.delete(code: game.code)
                    print("GameCode.codes=\(GameCode.codes)")
                }
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
                guard game.turn != K.endTurnNumber else { return req.eventLoop.makeSucceededFuture(HTTPStatus.imUsed) }
                game.guessedThisTurn = frequent.guessedThisTurn
                game.turn = frequent.turn
                game.lastWord = frequent.lastWord
                if game.turn == K.endTurnNumber {
                    GameCode.delete(code: game.code)
                    print("GameCode.codes=\(GameCode.codes)")
                }
                game.explainTime = frequent.explainTime
                game.basketChange = frequent.basketChange
                return game.save(on: req.db).transform(to: .ok)
        }
    }

    func getPlayersStatus(_ req: Request) throws -> EventLoopFuture<StatusBeforeStart> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        guard let uuidString = req.parameters.get("gameID"), let gameID = UUID(uuidString: uuidString) else { throw Abort(.notFound) }
        // update a record user/game just to renew "updatedAt" (using to check if user is online)
        return UserGame.query(on: req.db).filter(\.$game.$id == gameID).filter(\.$user.$id == userID).first().map { $0?.update(on: req.db) }
            .flatMap { _ in
                return Game.find(gameID, on: req.db)
                .unwrap(or: Abort(.notFound)).flatMap { game in
                    let turn = game.turn
                    let gameData = try! JSONDecoder().decode(GameData.self, from: game.data)
                    return UserGame.query(on: req.db).filter(\.$game.$id == gameID).all()
                        .map { usergames in
                            for player in gameData.players {
                                if let findedPlayer = usergames.first(where: {$0.$user.id == player.id}) {
                                    player.lastTimeInGame = findedPlayer.updatedAt!
                                }
                            }
                    return StatusBeforeStart(players: gameData.players, turn: turn)
                    }
                }
        }
    }
    
    func getMyGamesList(_ req: Request) throws -> EventLoopFuture<[Game.ListElement]> {
        let userID = try req.auth.require(JWTTokenPayload.self).userID
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$games.query(on: req.db).sort(\.$createdAt, .descending).with(\.$userOwner).group(.or) {
                $0.filter(\.$turn != K.endTurnNumber).filter(\.$updatedAt >= Date().addingTimeInterval(-1800) )
                }.all()
            .map { $0.map { $0.convertToListElement() }}
            }
    }
}

struct StatusBeforeStart: Content {
    var players: [Player]
    var turn: Int
}

struct WordData: Content {
    var word: String
    var timeGuessed: Int
    var guessedStatus: GuessedStatus
}

struct JoinData: Content {
    var code: String
    var additionalName: String?
}
