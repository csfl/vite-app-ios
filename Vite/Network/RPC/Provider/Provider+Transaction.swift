//
//  Provider+Transaction.swift
//  Vite
//
//  Created by Stone on 2018/9/20.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import Foundation
import PromiseKit
import JSONRPCKit
import APIKit
import BigInt

// MARK: Transaction
extension Provider {

    fileprivate func getUnconfirmedTransaction(address: Address) -> Promise<(accountBlocks: [AccountBlock], latestAccountBlock: AccountBlock, snapshotHash: String)> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory()
                .create(GetUnconfirmedTransactionRequest(address: address.description),
                        GetLatestAccountBlockRequest(address: address.description),
                        GetLatestSnapshotHashRequest()))
            Session.send(request) { result in
                switch result {
                case .success(let accountBlocks, let latestAccountBlock, let snapshotHash):
                    seal.fulfill((accountBlocks, latestAccountBlock, snapshotHash))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    fileprivate func getLatestAccountBlockAndSnapshotHash(address: Address) -> Promise<(latestAccountBlock: AccountBlock, snapshotHash: String)> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory()
                .create(GetLatestAccountBlockRequest(address: address.description),
                        GetLatestSnapshotHashRequest()))
            Session.send(request) { result in
                switch result {
                case .success(let latestAccountBlock, let snapshotHash):
                    seal.fulfill((latestAccountBlock, snapshotHash))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    fileprivate func getPowNonce(address: Address, preHash: String?) -> Promise<String> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory().create(GetPowNonceRequest(address: address, preHash: preHash)))
            Session.send(request) { result in
                switch result {
                case .success(let nonce):
                    seal.fulfill(nonce)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    fileprivate func createTransaction(accountBlock: AccountBlock) -> Promise<Void> {
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

extension Provider {

    enum TransactionErrorCode: Int {
        case notEnoughBalance = -35001
        case notEnoughQuota = -35002
    }

    func receiveTransactionWithGetPow(bag: HDWalletManager.Bag, completion: @escaping (NetworkResult<Void>) -> Void) {
        getUnconfirmedTransaction(address: bag.address)
            .then({ [unowned self] (accountBlocks, latestAccountBlock, latestSnapshotHash) -> Promise<(accountBlock: AccountBlock, latestAccountBlock: AccountBlock, latestSnapshotHash: String, nonce: String)?> in
                if let accountBlock = accountBlocks.first {
                    return self.getPowNonce(address: bag.address, preHash: latestAccountBlock.hash).then({ nonce in
                        return Promise { seal in seal.fulfill((accountBlock, latestAccountBlock, latestSnapshotHash, nonce)) }
                    })
                } else {
                    return Promise { $0.fulfill(nil) }
                }
            })
            .then({ [unowned self] ret -> Promise<Void> in
                if let (accountBlock, latestAccountBlock, latestSnapshotHash, nonce) = ret {
                    let receive = AccountBlock.makeReceiveAccountBlock(unconfirmed: accountBlock,
                                                                       latest: latestAccountBlock,
                                                                       bag: bag,
                                                                       snapshotHash: latestSnapshotHash,
                                                                       nonce: nonce)
                    return self.createTransaction(accountBlock: receive)
                } else {
                    return Promise { $0.fulfill(Void()) }
                }
            })
            .done({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }

    func sendTransactionWithoutGetPow(bag: HDWalletManager.Bag,
                                      toAddress: Address,
                                      tokenId: String,
                                      amount: BigInt,
                                      data: String?,
                                      completion: @escaping (NetworkResult<Void>) -> Void) {

        getLatestAccountBlockAndSnapshotHash(address: bag.address)
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash) -> Promise<Void> in
                let send = AccountBlock.makeSendAccountBlock(latest: latestAccountBlock,
                                                             bag: bag,
                                                             snapshotHash: latestSnapshotHash,
                                                             toAddress: toAddress,
                                                             tokenId: tokenId,
                                                             amount: amount,
                                                             data: data,
                                                             nonce: nil)
                return self.createTransaction(accountBlock: send)
            })
            .done ({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }

    func sendTransactionWithGetPow(bag: HDWalletManager.Bag,
                                   toAddress: Address,
                                   tokenId: String,
                                   amount: BigInt,
                                   data: String?,
                                   completion: @escaping (NetworkResult<Void>) -> Void) {

        getLatestAccountBlockAndSnapshotHash(address: bag.address)
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash) -> Promise<(latestAccountBlock: AccountBlock, latestSnapshotHash: String, nonce: String)> in
                return self.getPowNonce(address: bag.address, preHash: latestAccountBlock.hash).then({ nonce in
                    return Promise { seal in seal.fulfill((latestAccountBlock, latestSnapshotHash, nonce)) }
                })
            })
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash, nonce) -> Promise<Void> in
                let send = AccountBlock.makeSendAccountBlock(latest: latestAccountBlock,
                                                             bag: bag,
                                                             snapshotHash: latestSnapshotHash,
                                                             toAddress: toAddress,
                                                             tokenId: tokenId,
                                                             amount: amount,
                                                             data: data,
                                                             nonce: nonce)
                return self.createTransaction(accountBlock: send)
            })
            .done ({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }
}

// MARK: Pledge
extension Provider {

    fileprivate enum ContractAddress: String {
        case pledgeAndGainQuota = "vite_000000000000000000000000000000000000000309508ba646"

        var address: Address {
            return Address(string: self.rawValue)
        }
    }

    fileprivate func getPledges(address: Address, index: Int, count: Int) -> Promise<[Pledge]> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory().create(GetPledgesRequest(address: address.description, index: index, count: count)))
            Session.send(request) { result in
                switch result {
                case .success(let pledges):
                    seal.fulfill(pledges)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    fileprivate func getPledgeData(beneficialAddress: Address) -> Promise<String> {
        return Promise { seal in
            let request = ViteServiceRequest(for: server, batch: BatchFactory().create(GetPledgeDataRequest(beneficialAddress: beneficialAddress.description)))
            Session.send(request) { result in
                switch result {
                case .success(let data):
                    seal.fulfill(data)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

extension Provider {

    func getPledges(address: Address, index: Int, count: Int, completion: @escaping (NetworkResult<[Pledge]>) -> Void) {
        getPledges(address: address, index: index, count: count)
            .done ({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }

    func pledgeAndGainQuotaWithoutGetPow(bag: HDWalletManager.Bag,
                                         beneficialAddress: Address,
                                         tokenId: String,
                                         amount: BigInt,
                                         completion: @escaping (NetworkResult<Void>) -> Void) {
        getPledgeData(beneficialAddress: beneficialAddress)
            .then({ [unowned self] (data) -> Promise<(latestAccountBlock: AccountBlock, latestSnapshotHash: String, data: String)> in
                return self.getLatestAccountBlockAndSnapshotHash(address: bag.address).then({ (latestAccountBlock, latestSnapshotHash) in
                    return Promise { seal in seal.fulfill((latestAccountBlock, latestSnapshotHash, data)) }
                })
            })
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash, data) -> Promise<Void> in
                let send = AccountBlock.makeSendAccountBlock(latest: latestAccountBlock,
                                                             bag: bag,
                                                             snapshotHash: latestSnapshotHash,
                                                             toAddress: ContractAddress.pledgeAndGainQuota.address,
                                                             tokenId: tokenId,
                                                             amount: amount,
                                                             data: data,
                                                             nonce: nil)
                return self.createTransaction(accountBlock: send)
            })
            .done ({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }

    func pledgeAndGainQuotaWithGetPow(bag: HDWalletManager.Bag,
                                      beneficialAddress: Address,
                                      tokenId: String,
                                      amount: BigInt,
                                      completion: @escaping (NetworkResult<Void>) -> Void) {
        getPledgeData(beneficialAddress: beneficialAddress)
            .then({ [unowned self] (data) -> Promise<(latestAccountBlock: AccountBlock, latestSnapshotHash: String, data: String)> in
                return self.getLatestAccountBlockAndSnapshotHash(address: bag.address).then({ (latestAccountBlock, latestSnapshotHash) in
                    return Promise { seal in seal.fulfill((latestAccountBlock, latestSnapshotHash, data)) }
                })
            })
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash, data) -> Promise<(latestAccountBlock: AccountBlock, latestSnapshotHash: String, data: String, nonce: String)> in
                return self.getPowNonce(address: bag.address, preHash: latestAccountBlock.hash).then({ nonce in
                    return Promise { seal in seal.fulfill((latestAccountBlock, latestSnapshotHash, data, nonce)) }
                })
            })
            .then({ [unowned self] (latestAccountBlock, latestSnapshotHash, data, nonce) -> Promise<Void> in
                let send = AccountBlock.makeSendAccountBlock(latest: latestAccountBlock,
                                                             bag: bag,
                                                             snapshotHash: latestSnapshotHash,
                                                             toAddress: ContractAddress.pledgeAndGainQuota.address,
                                                             tokenId: tokenId,
                                                             amount: amount,
                                                             data: data,
                                                             nonce: nonce)
                return self.createTransaction(accountBlock: send)
            })
            .done ({
                completion(NetworkResult.success($0))
            })
            .catch({
                completion(NetworkResult.wrapError($0))
            })
    }
}
