import Foundation

extension Int {
    func toString(symbols: Int) -> String {
        guard symbols > 0, self >= 0, self < 10.to(power: symbols) else { return "" }
        var s = String(self)
        while s.count < symbols {
            s = "0" + s
        }
        return s
    }
    
    func to(power: Int) -> Int {
        return Int(pow(Double(self), Double(power)))
    }
}
