import Quick
import Nimble
@testable import Wgii

class GweiTests: QuickSpec { override func spec() {

    let pairs: [(Double, UInt)] = [
        (20.05,         20_050_000_000),
        (20.050000001,  20_050_000_001),
        (150,           150_000_000_000),
        (0,             0),
        (0.05,          50_000_000)
    ]

    describe("#Init") {
        pairs.forEach { gwei, wei in
            it("should map \(wei) wei to \(gwei) gwei init") {
                expect(Gwei(wei: wei).gwei).to(equal(gwei))
            }
        }

        pairs.forEach { gwei, wei in
            it("should map \(gwei) gwei to \(wei) wei init") {
                expect(Gwei(gwei: gwei).wei).to(equal(wei))
            }
        }
    }
}}
