//
//  TransactionProvider.swift
//  Vite
//
//  Created by Stone on 2018/9/14.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import PromiseKit
import BigInt
import APIKit
import JSONRPCKit

final class TransactionProvider {
    let server: RPCServer

    init(server: RPCServer) {
        self.server = server
    }

    func getUnconfirmedTransaction(address: Address) -> Promise<([AccountBlock], AccountBlock)> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory().create(GetUnconfirmedTransactionRequest(address: address.description), GetLatestAccountBlockRequest(address: address.description)))
            Session.send(request) { result in
                switch result {
                case .success(let accountBlocks, let latestAccountBlock):
                    seal.fulfill((accountBlocks, latestAccountBlock))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    func createTransaction(accountBlock: AccountBlock) -> Promise<Void> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory().create(CreateTransactionRequest(accountBlock: accountBlock)))
            Session.send(request) { result in
                switch result {
                case .success:
                    seal.fulfill(Void())
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}
