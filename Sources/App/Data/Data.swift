import Foundation
import Vapor

struct UpdateData: Codable, Content {
    var gameData: GameData
    var wordsData: [WordData]
}

struct GameData: Codable, Content {
    var players: [Player]
    var leftWords: [String]
    var guessedWords: [String]
    var missedWords: [String]
    var basketWords: [String]
    var basketStatus: [GuessedStatus]
    var time: Int
    var currentWord: String
    var tellerNumber: Int
    var listenerNumber: Int
    var dist: Int
    var started: Bool
    var prevTellerNumber: Int
    var prevListenerNumber: Int
}

struct WordData: Codable, Content {
    var word: String
    var timeGuessed: Double
    var guessedStatus: GuessedStatus
}

enum GuessedStatus: Int, Codable  {
    case guessed
    case left
    case missed
}

final class Player: Codable {
    init(id: UUID, name: String, tellGuessed: Int, listenGuessed: Int) {
        self.id = id
        self.name = name
        self.tellGuessed = tellGuessed
        self.listenGuessed = listenGuessed
    }
    var id: UUID
    var name: String
    var tellGuessed: Int
    var listenGuessed: Int
}

