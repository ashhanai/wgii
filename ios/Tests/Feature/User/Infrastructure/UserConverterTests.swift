import RxSwift
import RxBlocking
import RxTest
import Quick
import Nimble
@testable import Wgii

class UserConverterTests: QuickSpec { override func spec() {

    describe("#toDomain") {
        it("should map limit to model") {
            let limit: UInt = 3_123
            let model = UserConverter.toDomain(dto(limit: limit), userAuth: UserAuth(uid: "uid"))

            expect(model?.limit.wei).to(equal(3_123))
            expect(model?.auth.uid).to(equal("uid"))
        }

        it("should fail when missing limit") {
            let model = UserConverter.toDomain(dto(limit: nil), userAuth: UserAuth(uid: "uid"))

            expect(model).to(beNil())
        }
    }


    func dto(
        limit: UInt? = 0
    ) -> [String: Any] {
        var dto = [String: Any]()
        if let limit = limit {
            dto["limit"] = limit
        }
        return dto
    }
}}
