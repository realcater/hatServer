import Fluent
import Vapor
import JWT

func routes(_ app: Application) throws {
    app.get { req in return "It works!" }

    try app.register(collection: UserController())
    try app.register(collection: GameController())
}
