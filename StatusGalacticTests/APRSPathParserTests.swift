import XCTest
@testable import StatusGalactic

final class APRSPathParserTests: XCTestCase {

    func testStripsGenericAliases() {
        let path = "WIDE1-1,WIDE2-1,RELAY,TRACE5-5,APRSIS"
        XCTAssertEqual(APRSPathParser.realCallsigns(in: path), [])
    }

    func testStripsIgateFlags() {
        let path = "qAR,qAO,qAC,qAS,qAo"
        XCTAssertEqual(APRSPathParser.realCallsigns(in: path), [])
    }

    func testStripsTrailingStars() {
        let path = "W9ABC*,K1XYZ-2*,WB2DEF"
        XCTAssertEqual(
            APRSPathParser.realCallsigns(in: path),
            ["W9ABC", "K1XYZ-2", "WB2DEF"]
        )
    }

    func testHandlesMixedRealPath() {
        let path = "WIDE1-1,W9ABC*,WIDE2-1,K1XYZ-2*,qAR,WB2DEF"
        XCTAssertEqual(
            APRSPathParser.realCallsigns(in: path),
            ["W9ABC", "K1XYZ-2", "WB2DEF"]
        )
    }

    func testRejectsShortAndPunctuation() {
        XCTAssertFalse(APRSPathParser.isHamCallsign(""))
        XCTAssertFalse(APRSPathParser.isHamCallsign("AB"))
        XCTAssertFalse(APRSPathParser.isHamCallsign("WIDE1"))
        XCTAssertFalse(APRSPathParser.isHamCallsign("HELLO"))
        XCTAssertTrue(APRSPathParser.isHamCallsign("W9ABC"))
        XCTAssertTrue(APRSPathParser.isHamCallsign("K1ABC-9"))
    }
}

final class APRSSymbolIconTests: XCTestCase {

    func testCommonSymbolsResolve() {
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/k"), "truck.box.fill")
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/>"), "car.fill")
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/-"), "house.fill")
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/Y"), "sailboat.fill")
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/_"), "cloud.sun.fill")
    }

    func testFallbackForUnknown() {
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: nil),
                       APRSSymbolIcon.defaultGlyph)
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: ""),
                       APRSSymbolIcon.defaultGlyph)
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/" ),
                       APRSSymbolIcon.defaultGlyph)
        XCTAssertEqual(APRSSymbolIcon.sfSymbol(for: "/¡"),
                       APRSSymbolIcon.defaultGlyph)
    }

    func testLabelForKnownSymbols() {
        XCTAssertEqual(APRSSymbolIcon.label(for: "/k"), "Truck")
        XCTAssertEqual(APRSSymbolIcon.label(for: "/-"), "House")
        XCTAssertNil(APRSSymbolIcon.label(for: nil))
    }
}
