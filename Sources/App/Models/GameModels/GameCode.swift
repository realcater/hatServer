import Foundation

struct GameCode {
    static var codes: [String] = []
    
    static func new() -> String {
        var newCode: String
        repeat {
            newCode = Int.random(in: 1..<10000).toString(symbols: 4)
        } while codes.contains(newCode)
        codes.append(newCode)
        return newCode
    }
    static func delete(code: String?) {
        if let code = code, let index = codes.firstIndex(of: code) {
            codes.remove(at: index)
        }
    }
}
