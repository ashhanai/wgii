import FirebaseDatabase

protocol UserDao {
    func observeUserValue(userAuth: UserAuth, listener: @escaping (User?) -> Void) -> Any
    func removeUserObserver(_ handler: Any)
    func setLimit(_ limit: Gwei, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void)
    func setDeviceToken(_ token: String, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void)
}

extension Database: UserDao {
    func observeUserValue(userAuth: UserAuth, listener: @escaping (User?) -> Void) -> Any {
        return reference().child("users").child(userAuth.uid).observe(.value) { snapshot in
            if let value = snapshot.value {
                listener(UserConverter.toDomain(value, userAuth: userAuth))
            } else {
                listener(nil)
            }
        }
    }

    func removeUserObserver(_ handler: Any) {
        if let handler = handler as? UInt {
            reference().removeObserver(withHandle: handler)
        }
    }

    func setLimit(_ limit: Gwei, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void) {
        setValue(limit.wei, key: "limit", userAuth: userAuth, callback: callback)
    }

    func setDeviceToken(_ token: String, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void) {
        setValue(token, key: "deviceToken", userAuth: userAuth, callback: callback)
    }

    private func setValue(
        _ value: Any, key: String, userAuth: UserAuth, callback: @escaping (Result<Void, Error>) -> Void
    ) {
        reference().child("users/\(userAuth.uid)/\(key)").setValue(value) { error, _ in
            if let error = error {
                callback(.failure(error))
            } else {
                callback(.success(()))
            }
        }
    }
}

enum UserConverter {
    static func toDomain(_ dto: Any, userAuth: UserAuth) -> User? {
        guard
            let dto = dto as? [String: Any],
            let limit = dto["limit"] as? UInt
        else { return nil }

        return User(limit: Gwei(wei: limit), auth: userAuth)
    }
}
