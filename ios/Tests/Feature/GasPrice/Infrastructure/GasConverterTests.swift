import Quick
import Nimble
@testable import Wgii

class GasConverterTests: QuickSpec { override func spec() {

    describe("#toDomain") {
        it("should map timestamp to model") {
            let timestamp: UInt = 3_123
            let model = GasConverter.toDomain(dto(timestamp: timestamp))

            expect(model?.timestamp).to(equal(TimeInterval(3.123)))
        }

        it("should map rapid to model") {
            let rapid: UInt = 140_000_000_000
            let model = GasConverter.toDomain(dto(rapid: rapid))

            expect(model?.rapid).to(equal(Gwei(wei: rapid)))
        }

        it("should map fast to model") {
            let fast: UInt = 10_000_000_000
            let model = GasConverter.toDomain(dto(fast: fast))

            expect(model?.fast).to(equal(Gwei(wei: fast)))
        }

        it("should map standard to model") {
            let standard: UInt = 2_000_000_000_000
            let model = GasConverter.toDomain(dto(standard: standard))

            expect(model?.standard).to(equal(Gwei(wei: standard)))
        }

        it("should map slow to model") {
            let slow: UInt = 1_000_000_000
            let model = GasConverter.toDomain(dto(slow: slow))

            expect(model?.slow).to(equal(Gwei(wei: slow)))
        }

        it("should fail when missing timestamp") {
            let model = GasConverter.toDomain(dto(timestamp: nil))

            expect(model).to(beNil())
        }

        it("should fail when missing rapid") {
            let model = GasConverter.toDomain(dto(rapid: nil))

            expect(model).to(beNil())
        }

        it("should fail when missing fast") {
            let model = GasConverter.toDomain(dto(fast: nil))

            expect(model).to(beNil())
        }

        it("should fail when missing standard") {
            let model = GasConverter.toDomain(dto(standard: nil))

            expect(model).to(beNil())
        }

        it("should fail when missing slow") {
            let model = GasConverter.toDomain(dto(slow: nil))

            expect(model).to(beNil())
        }
    }


    func dto(
        timestamp: UInt? = 0,
        rapid: UInt? = 0,
        fast: UInt? = 0,
        standard: UInt? = 0,
        slow: UInt? = 0
    ) -> [String: Any] {
        var dto = [String: Any]()
        if let timestamp = timestamp {
            dto["timestamp"] = timestamp
        }
        if let rapid = rapid {
            dto["rapid"] = rapid
        }
        if let fast = fast {
            dto["fast"] = fast
        }
        if let standard = standard {
            dto["standard"] = standard
        }
        if let slow = slow {
            dto["slow"] = slow
        }
        return dto
    }
}}
