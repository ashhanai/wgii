import FirebaseDatabase

protocol GasPriceDao {
    func observeGasPriceValue(_ listener: @escaping (GasPrice?) -> Void) -> Any
    func removeGasPriceObserver(_ handler: Any)
}

extension Database: GasPriceDao {
    func observeGasPriceValue(_ listener: @escaping (GasPrice?) -> Void) -> Any {
        return reference().child("currentPrice").observe(.value) { snapshot in
            if let value = snapshot.value {
                listener(GasConverter.toDomain(value))
            } else {
                listener(nil)
            }
        }
    }

    func removeGasPriceObserver(_ handler: Any) {
        if let handler = handler as? UInt {
            reference().removeObserver(withHandle: handler)
        }
    }
}

enum GasConverter {
    static func toDomain(_ dto: Any) -> GasPrice? {
        guard
            let dto = dto as? [String: Any],
            let timestamp = dto["timestamp"] as? UInt,
            let rapid = dto["rapid"] as? UInt,
            let fast = dto["fast"] as? UInt,
            let standard = dto["standard"] as? UInt,
            let slow = dto["slow"] as? UInt
        else { return nil }

        return GasPrice(
            timestamp: TimeInterval(timestamp) / 1_000,
            rapid: Gwei(wei: rapid),
            fast: Gwei(wei: fast),
            standard: Gwei(wei: standard),
            slow: Gwei(wei: slow)
        )
    }
}
