//
//  AmedasPointTests.swift
//  AmedasMapTests
//
//  Created by tasshy on 2021/02/28.
//

import XCTest
@testable import AmedasMap

class AmedasPointTests: XCTestCase {
    func testParseAmedasTable() throws {
        let testData = """
        {
        "11001":{"type":"C","elems":"11111000","lat":[45,31.2],"lon":[141,56.1],"alt":26,"kjName":"宗谷岬","knName":"ソウヤミサキ","enName":"Cape Soya"},
        "11016":{"type":"A","elems":"11111111","lat":[45,24.9],"lon":[141,40.7],"alt":3,"kjName":"稚内","knName":"ワッカナイ","enName":"Wakkanai"}
        }
        """.data(using: .utf8)!
        
        let list = AmedasTableLoader().parseAmedasTable(data: testData)!
        XCTAssertEqual(list.count, 2)

        XCTAssertEqual(list[0].pointID, "11001")
        XCTAssertEqual(list[0].pointNameJa, "宗谷岬")
        XCTAssertEqual(list[0].latitude, 45 + 31.2 / 60)
        XCTAssertEqual(list[0].longitude, 141 + 56.1 / 60)
        
        XCTAssertEqual(list[1].pointID, "11016")
        XCTAssertEqual(list[1].pointNameJa, "稚内")
        XCTAssertEqual(list[1].latitude, 45 + 24.9 / 60)
        XCTAssertEqual(list[1].longitude, 141 + 40.7 / 60)
    }
}
