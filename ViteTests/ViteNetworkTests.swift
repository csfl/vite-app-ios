//
//  ViteNetworkTests.swift
//  ViteTests
//
//  Created by Stone on 2018/9/7.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import XCTest
import PromiseKit
import BigInt
import ObjectMapper
import Alamofire
import Moya
import SwiftyJSON
@testable import Vite

class ViteNetworkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func async(_ block: ( @escaping () -> () ) -> ()) {

        let expect = expectation(description: "method")
        block {
            expect.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        print("🍺🍺🍺🍺🍺🍺")

    }

    func testSnapshotChainProvider() {

        async { (completion) in
            Provider.instance.getSnapshotChainHeight(completion: { result in
                switch result {
                case .success(let height):
                    print("🏆snapschot china height: \(height)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }

    }

    func testAccountProvider_GetTransactionsRequest() {
        async { (completion) in
            Provider.instance.getTransactions(address: Address(string: "vite_7945df07bbf55f5afc76360a263b0870795ce5d1ecea36b786"), hash: nil, count: 5, completion: { result in
                switch result {
                case .success(let transactions):
                    print("🏆\(transactions)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }

    }

    func testAccountProvider_GetBalanceInfosRequest() {
        async { (completion) in
            Provider.instance.getBalanceInfos(address: Address(string: "vite_7945df07bbf55f5afc76360a263b0870795ce5d1ecea36b786"), completion: { result in
                switch result {
                case .success(let balanceInfos):
                    print("🏆\(balanceInfos)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }

    func testAddress() {
        let correct = "vite_4827fbc6827797ac4d9e814affb34b4c5fa85d39bf96d105e7"
        let error = "vite_4827fbc6827797ac4d9e814affb34b4c5fa85d39bf96d105e6"
        XCTAssert(Address.isValid(string: correct))
        XCTAssert(!Address.isValid(string: error))
    }

    func testGetTokenInfo() {
        async { (completion) in
            Provider.instance.getTokenForId("tti_000000000000000000004cfd", completion: { result in
                switch result {
                case .success(let token):
                    if let token = token {
                        print("🏆\(token)")
                    } else {
                        print("🏆 token not found")
                    }
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }
}

extension ViteNetworkTests {
    func testGetAppUpdate() {
        async { (completion) in
            ServerProvider.instance.getAppUpdate(completion: { (result) in
                switch result {
                case .success(let info):
                    print("🏆\(info)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }

    func testGetAppSettingsConfig() {
        async { (completion) in
            ServerProvider.instance.getAppSettingsConfig(completion: { (result) in
                switch result {
                case .success(let config):
                    print("🏆\(String(describing: config))")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }

    func testGetDefaultTokens() {
        async { (completion) in
            ServerProvider.instance.getAppDefaultTokens(completion: { (result) in
                switch result {
                case .success(let string):
                    print("🏆\(string)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }
}

extension ViteNetworkTests {
    func testGetPledgest() {
        async { (completion) in
            Provider.instance.getPledges(address: Address(string: "vite_847e1672c9a775ca0f3c3a2d3bf389ca466e5501cbecdb7107"), index: 0, count: 50, completion: { (result) in
                switch result {
                case .success(let pledges):
                    print("🏆\(pledges)")
                case .failure(let error):
                    print("🤯🤯🤯🤯🤯🤯\(error)")
                }
                completion()
            })
        }
    }
}
