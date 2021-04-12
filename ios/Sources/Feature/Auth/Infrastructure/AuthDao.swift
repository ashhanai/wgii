import FirebaseAuth

protocol AuthDao {
    func currentUser() -> UserAuth?
    func addStateDidChangeListener(_ listener: @escaping (UserAuth?) -> Void) -> Any
    func removeStateDidChangeListener(_ handler: Any)
    func signInAnonymously()
}

extension Auth: AuthDao {
    func currentUser() -> UserAuth? {
        currentUser.map(AuthConverter.toDomain)
    }

    func addStateDidChangeListener(_ listener: @escaping (UserAuth?) -> Void) -> Any {
        return addStateDidChangeListener { auth, user in
            listener(user.map(AuthConverter.toDomain))
        }
    }

    func removeStateDidChangeListener(_ handler: Any) {
        if let handler = handler as? AuthStateDidChangeListenerHandle {
            removeStateDidChangeListener(handler)
        }
    }

    func signInAnonymously() {
        signInAnonymously { _, _ in }
    }
}

enum AuthConverter {
    static func toDomain(_ user: FirebaseAuth.User) -> UserAuth {
        return UserAuth(uid: user.uid)
    }
}
