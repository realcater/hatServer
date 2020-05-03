/*
Non-admin requests (used in APP)
 
POST
/api/users
/api/users/login

GET
/api/users/search
/api/users/userID
 
*/

import Fluent
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
        appAuthRoutes.get(":userID", use: searchByID)
        
        tokenAuthRoutes.get("search", use: searchByName)
        
        adminAuthRoutes.get(use: getAll)
        adminAuthRoutes.delete(":userID", use: delete)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func create(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userData = try req.content.decode(CreateUserData.self)
        let passwordHash = try Bcrypt.hash(userData.password)
        
        let user = User(id: userData.id, name: userData.name, passwordHash: passwordHash)
        return user.save(on: req.db).map { user.convertToPublic() }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func login(_ req: Request) throws -> LoginResponse {
        sleep(1)
        let user = try req.auth.require(User.self)
        let jwtToken = try req.jwt.sign(JWTTokenPayload(userID: user.id!, userName: user.name))
        let loginResponse = LoginResponse(name: user.name, id: user.id!, jwtToken: jwtToken)
        return loginResponse
    }
    
    func searchByName(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        let searchRequestData = try req.content.decode(SearchRequestData.self)
        return User.query(on: req.db).filter(\.$name, .contains(inverse: false, .prefix), searchRequestData.text).limit(searchRequestData.maxResultsQty).all().map { users in users.map {$0.convertToPublic()} }
    }
    func searchByID(_ req: Request) throws -> EventLoopFuture<User.Public> {
        sleep(1)
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

struct LoginResponse: Content {
    let name: String
    let id: UUID
    let jwtToken: String
}

struct SearchRequestData: Content {
    let text: String
    let maxResultsQty: Int
}

