import Fluent
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        let basicAuthRoutes = userRoutes.grouped(User.authenticator())
        let tokenAuthRoutes = userRoutes.grouped(Token.authenticator(), User.guardMiddleware())
        let adminAuthRoutes = tokenAuthRoutes.grouped(AdminMiddleware())
        let appAuthRoutes = tokenAuthRoutes.grouped(AppMiddleware())
        
        appAuthRoutes.post(use: create)
        adminAuthRoutes.get(use: getAll)
        basicAuthRoutes.post("login", use: login)
        adminAuthRoutes.delete(":userID", use: delete)
        tokenAuthRoutes.get("mine", use: getMyGames)
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
    
    func login(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db).map { token }
    }
    
    func getMyGames(_ req: Request) throws -> EventLoopFuture<[User]> {
        //let user = try req.auth.require(User.self)
        //return User.query(on: req.db).with(\.$games).all()
        return User.query(on: req.db).all()
    }
    
}

struct CreateUserData: Content {
    let name: String
    let password: String
}
