import Fluent
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        let basicAuthRoutes = userRoutes.grouped(User.authenticator())

        let adminAuthRoutes = userRoutes.grouped(UserAuthenticator(), AdminMiddleware())
        let appAuthRoutes = userRoutes.grouped(UserAuthenticator(), AppMiddleware())
        let tokenAuthRoutes = userRoutes.grouped(UserAuthenticator(), JWTGuardMiddleware())
        
        appAuthRoutes.post(use: create)
        adminAuthRoutes.get(use: getAll)
        basicAuthRoutes.post("login", use: login)
        adminAuthRoutes.delete(":userID", use: delete)
        tokenAuthRoutes.get("search", use: search)
    }
    
    func getAll(_ req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func create(_ req: Request) throws -> EventLoopFuture<User> {
        let userData = try req.content.decode(CreateUserData.self)
        let passwordHash = try Bcrypt.hash(userData.password)
        
        let user = User(name: userData.name, passwordHash: passwordHash)
        return user.save(on: req.db).map { user }
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
        let loginResponse = LoginResponse(name: user.name, id: user.id!, jwtToken: jwtToken)
        return loginResponse
    }
    
    func search(_ req: Request) throws -> EventLoopFuture<[User]> {
        let searchRequestData = try req.content.decode(SearchRequestData.self)
        return User.query(on: req.db).filter(\.$name, .contains(inverse: false, .prefix), searchRequestData.text).limit(searchRequestData.maxResultsQty).all()
    }
}

struct CreateUserData: Content {
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

