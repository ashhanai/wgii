struct Gwei: Equatable {
    let wei: UInt
    let gwei: Double

    init(wei: UInt) {
        self.wei = wei
        self.gwei = Double(wei) / 1_000_000_000
    }

    init(gwei: Double) {
        self.wei = UInt(gwei * 1_000_000_000)
        self.gwei = gwei
    }
}
