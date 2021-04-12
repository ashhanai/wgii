import Foundation

struct GasPrice: Equatable {
    let timestamp: TimeInterval
    let rapid: Gwei
    let fast: Gwei
    let standard: Gwei
    let slow: Gwei

    enum State {
        case loading
        case success(GasPrice)
    }
}

extension GasPrice {
    static var zero = GasPrice(
        timestamp: 0,
        rapid: Gwei(wei: 0),
        fast: Gwei(wei: 0),
        standard: Gwei(wei: 0),
        slow: Gwei(wei: 0)
    )
}

extension GasPrice.State: Equatable {
    static func == (lhs: GasPrice.State, rhs: GasPrice.State) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.success(let lVal), .success(let rVal)): return lVal == rVal
        default: return false
        }
    }
}
