//
//  ViteURITest.swift
//  ViteTests
//
//  Created by Stone on 2018/9/19.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import XCTest

@testable import Vite

class ViteURITest: XCTestCase {

    func testExample() {

        let successCases = [
            ("vite:vite_fa1d81d93bcc36f234f7bccf1403924a0834609f4b2e9856ad?tti=tti_000000000000000000004cfd&amount=10.12345678&decimals=1e18", "10123456780000000000"),
            ("vite:vite_fa1d81d93bcc36f234f7bccf1403924a0834609f4b2e9856ad?tti=tti_000000000000000000004cfd&amount=10.12345678E7&decimals=1000", "101234567800"),
            ]


        for c in successCases {
            let string = c.0
            let ans = c.1

            let uri = ViteURI.parser(string: string)
            let uriString = uri?.string()
            let amountString = uri?.amountToBigInt()?.description
            XCTAssertEqual(string, uriString)
            XCTAssertEqual(amountString, ans)
        }
    }

    func testScientificNotation() {
        let successCases = [
            ("12.34E3", "12340"),
            ("+12.34E3", "12340"),
            ("-12.34E3", "-12340"),
            ("-12.34E6", "-12340000"),
        ]


        for c in successCases {
            let string = c.0
            let ans = c.1

            guard let ret = ViteURI.scientificNotationStringToBigInt(string, decimals: 0) else {
                XCTAssert(false)
                return
            }
            XCTAssertEqual(ret.description, ans)
        }

    }


}
