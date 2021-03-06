//
//  AmedasDataTests.swift
//  AmedasMapTests
//
//  Created by tasshy on 2021/03/06.
//

import XCTest
@testable import AmedasMap

class AmedasDataTests: XCTestCase {
    func testParseAmedasTable() throws {
        let testData = """
        {
        "11001":{"temp":[-7.1,0],
            "snow1h":[0,null],"snow6h":[0,null],"snow12h":[0,null],"snow24h":[0,null],"sun1h":[0.4,0],
            "windDirection":[8,0],"wind":[2.2,0]},
        "11016":{"temp":[-6.1,0],"humidity":[48,0],
            "snow":[79,0],"snow1h":[0,0],"snow6h":[0,4],"snow12h":[0,4],"snow24h":[17,4],"sun1h":[0.3,0],
            "precipitation10m":[0.0,0],"precipitation1h":[0.0,0],"precipitation3h":[0.0,0],"precipitation24h":[0.0,0],
            "windDirection":[15,0],"wind":[2.0,0]},
        "12451":{"temp":[-5.1,0],"snow1h":[0,null],"snow6h":[0,null],"snow12h":[0,null],"snow24h":[0,null],"sun1h":[0.6,0],
            "precipitation10m":[0.0,0],"precipitation1h":[3.2,0],"precipitation3h":[0.0,0],"precipitation24h":[2.5,0],
            "windDirection":[null,5],"wind":[null,5]}
        }
        """.data(using: .utf8)!
        
        let list = AmedasDataLoader().parseAmedasData(data: testData)!
            .sorted { $0.pointID < $1.pointID } .map { $0 }  // Array の順番は不定なので、pointID で sort してからテストする。
        XCTAssertEqual(list.count, 3)

        XCTAssertEqual(list[0].pointID, "11001")
        XCTAssertEqual(list[0].temperature, -7.1)
        XCTAssertEqual(list[0].precipitation1h, nil)
        XCTAssertEqual(list[0].windDirection, 8)
        XCTAssertEqual(list[0].windSpeed, 2.2)
        XCTAssertEqual(list[0].sun1h, 0.4)
        XCTAssertEqual(list[0].humidity, nil)

        XCTAssertEqual(list[1].pointID, "11016")
        XCTAssertEqual(list[1].temperature, -6.1)
        XCTAssertEqual(list[1].precipitation1h, 0.0)
        XCTAssertEqual(list[1].windDirection, 15)
        XCTAssertEqual(list[1].windSpeed, 2.0)
        XCTAssertEqual(list[1].sun1h, 0.3)
        XCTAssertEqual(list[1].humidity, 48)
        
        XCTAssertEqual(list[2].pointID, "12451")
        XCTAssertEqual(list[2].temperature, -5.1)
        XCTAssertEqual(list[2].precipitation1h, 3.2)
        XCTAssertEqual(list[2].windDirection, nil)
        XCTAssertEqual(list[2].windSpeed, nil)
        XCTAssertEqual(list[2].sun1h, 0.6)
        XCTAssertEqual(list[2].humidity, nil)
    }
}
