import Fluent
import FluentSQL
import Vapor


struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        let basicAuthRoutes = userRoutes.grouped(User.authenticator())

        let adminAuthRoutes = userRoutes.grouped(UserAuthenticator(), AdminMiddleware())
        let appAuthRoutes = userRoutes.grouped(UserAuthenticator(), AppMiddleware())
        let tokenAuthRoutes = userRoutes.grouped(UserAuthenticator(), JWTGuardMiddleware())
        
        basicAuthRoutes.post("login", use: login)
        
        appAuthRoutes.post(use: create)
        appAuthRoutes.get(":userID", use: get)

        tokenAuthRoutes.post("changeName", use: changeName)
        tokenAuthRoutes.post("search", use: searchByName)
        
        adminAuthRoutes.get(use: getAll)
        adminAuthRoutes.delete(":userID", use: delete)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func create(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userData = try req.content.decode(CreateUserData.self)
        let passwordHash = try Bcrypt.hash(userData.password)
        let user = User(id: userData.id, name: userData.name, passwordHash: passwordHash)
        return User.query(on: req.db).filter(\.$upperName == userData.name.uppercased()).count()
            .flatMap { count in
                guard count == 0 else {
                    return req.eventLoop.future(error: Abort(.conflict))
                }
                return user.save(on: req.db).transform(to: .ok)
            }
    }
    
    func changeName(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try? req.auth.require(JWTTokenPayload.self).userID
        let data = try req.content.decode(UpdateUserData.self)
        
        return User.find(userID, on: req.db).unwrap(or: Abort(.notFound))
            .flatMap { user in
                return User.query(on: req.db).filter(\.$upperName == data.newName.uppercased()).count()
                .flatMap { count in
                    guard count == 0 else {
                        return req.eventLoop.future(error: Abort(.conflict))
                    }
                    user.name = data.newName
                    user.upperName = data.newName.uppercased()
                    return user.save(on: req.db).transform(to: .ok)
                }
            }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func login(_ req: Request) throws -> LoginResponse {
        let user = try req.auth.require(User.self)
        let jwtToken = try req.jwt.sign(JWTTokenPayload(userID: user.id!, userName: user.name))
        let loginResponse = LoginResponse(name: user.name, id: user.id!, jwtToken: jwtToken, expirationDate: user.exp.value)
        return loginResponse
    }

    func searchByName(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        let searchRequestData = try req.content.decode(SearchRequestData.self)
        return User.query(on: req.db).filter(\.$upperName, .contains(inverse: false, .prefix), searchRequestData.text.uppercased()).filter(\.$name != "admin").filter(\.$name != "app").limit(searchRequestData.maxResultsQty).all().map { users in users.map { $0.convertToPublic() } }
    }
    func get(_ req: Request) throws -> EventLoopFuture<User.Public> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { $0.convertToPublic() }
    }

}

struct CreateUserData: Content {
    let id: UUID
    let name: String
    let password: String
}

struct UpdateUserData: Content {
    let newName: String
}

struct LoginResponse: Content {
    let name: String
    let id: UUID
    let jwtToken: String
    let expirationDate: Date
}

struct SearchRequestData: Content {
    let text: String
    let maxResultsQty: Int
}

struct UserTime: Content {
    let id: UUID
    let lastTimeOnline: Date
}

