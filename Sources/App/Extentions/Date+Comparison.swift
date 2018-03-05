import Foundation
import Vapor
import Crypto

extension Date {
    
    func greaterOrEqualThan(_ other: Date) -> Bool {
        let result = self.compare(other)
        return result == .orderedAscending || result == .orderedSame
    }
    
}
