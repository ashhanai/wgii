struct User: Equatable {
    let limit: Gwei
    let auth: UserAuth

    enum State {
        case loading
        case success(User)
    }
}

extension User.State: Equatable {
    static func == (lhs: User.State, rhs: User.State) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.success(let lVal), .success(let rVal)): return lVal == rVal
        default: return false
        }
    }
}
