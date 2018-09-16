//
//  AccountBlock.swift
//  Vite
//
//  Created by Stone on 2018/9/14.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import ObjectMapper
import BigInt
import Vite_keystore
import libEd25519Blake2b
import CryptoSwift

struct AccountBlock: Mappable {

    fileprivate(set) var meta = AccountBlockMeta()
    fileprivate(set) var accountAddress: String?
    fileprivate(set) var publicKey: String?
    fileprivate(set) var to: String?
    fileprivate(set) var from: String?
    fileprivate(set) var fromHash: String?
    fileprivate(set) var prevHash: String?
    fileprivate(set) var hash: String?
    fileprivate(set) var balance: BigInt?
    fileprivate(set) var amount: BigInt?
    fileprivate(set) var timestamp: BigInt?
    fileprivate(set) var tokenId: String?
    fileprivate(set) var lastBlockHeightInToken: BigInt?
    fileprivate(set) var data: String?
    fileprivate(set) var snapshotChainHash: String?
    fileprivate(set) var signature: String?
    fileprivate(set) var nonce: String?
    fileprivate(set) var difficulty: String?
    fileprivate(set) var confirmedTimes: BigInt?
    fileprivate(set) var fAmount: BigInt?

    init() {

    }

    init?(map: Map) {

    }

    init(address: String) {
        self.init()
        self.accountAddress = address
    }

    mutating func mapping(map: Map) {

        meta <- map["Meta"]
        accountAddress <- map["AccountAddress"]
        publicKey <- map["PublicKey"]
        to <- map["To"]
        from <- map["From"]
        fromHash <- map["FromHash"]
        prevHash <- map["PrevHash"]
        hash <- map["Hash"]
        balance <- (map["Balance"], JSONTransformer.bigint)
        amount <- (map["Amount"], JSONTransformer.bigint)
        timestamp <- map["Timestamp"]
        tokenId <- map["TokenId"]
        lastBlockHeightInToken <- (map["LastBlockHeightInToken"], JSONTransformer.bigint)
        data <- map["Data"]
        snapshotChainHash <- map["SnapshotTimestamp"]
        signature <- map["Signature"]
        nonce <- map["Nonce"]
        difficulty <- map["Difficulty"]
        confirmedTimes <- (map["ConfirmedTimes"], JSONTransformer.bigint)

    }
}

extension AccountBlock {
    func makeSendAccountBlock(latestAccountBlock: AccountBlock, key: WalletAccount.Key, snapshotChainHash: String, toAddress: String, tokenId: String, amount: BigInt) -> AccountBlock {

        var accountBlock = makeBaseAccountBlock(latestAccountBlock: latestAccountBlock, key: key, snapshotChainHash: snapshotChainHash)
        accountBlock.to = toAddress
        accountBlock.tokenId = tokenId
        accountBlock.amount = amount
        let (hash, signature) = self.signature(accountBlock: accountBlock, secretKeyHexString: key.secretKey, publicKeyHexString: key.publicKey)

        accountBlock.hash = hash
        accountBlock.signature = signature

        return accountBlock
    }

    func makeReceiveAccountBlock(latestAccountBlock: AccountBlock, key: WalletAccount.Key, snapshotChainHash: String) -> AccountBlock {

        var accountBlock = makeBaseAccountBlock(latestAccountBlock: latestAccountBlock, key: key, snapshotChainHash: snapshotChainHash)
        let (hash, signature) = self.signature(accountBlock: accountBlock, secretKeyHexString: key.secretKey, publicKeyHexString: key.publicKey)
        accountBlock.hash = hash
        accountBlock.signature = signature

        return accountBlock
    }

    private func makeBaseAccountBlock(latestAccountBlock: AccountBlock, key: WalletAccount.Key, snapshotChainHash: String) -> AccountBlock {

        var accountBlock = AccountBlock()

        if let height = latestAccountBlock.meta.height {
            accountBlock.meta.setHeight(height + 1)
        } else {
            accountBlock.meta.setHeight(1)
        }

        accountBlock.accountAddress = key.address
        accountBlock.publicKey = key.publicKey
        accountBlock.fromHash = self.hash
        accountBlock.prevHash = latestAccountBlock.hash
        accountBlock.timestamp = BigInt(Date().timeIntervalSince1970)
        accountBlock.tokenId = self.tokenId
        accountBlock.data = self.data
        accountBlock.snapshotChainHash = snapshotChainHash
        accountBlock.nonce = "0000000000"
        accountBlock.difficulty = "0000000000"

        return accountBlock
    }

    private func signature(accountBlock: AccountBlock, secretKeyHexString: String, publicKeyHexString: String) -> (hash: String, signature: String) {
        var source = Bytes()

        // Bytes->hex2Bytes
        // string->my_bytes

        if let prevHash = accountBlock.prevHash {
            source.append(contentsOf: prevHash.hex2Bytes)
        }

        if let height = accountBlock.meta.height {
            // bytes 函数名冲突
            source.append(contentsOf: height.description.my_bytes)
        }

        if let accountAddress = accountBlock.accountAddress {
            // accountAddress 掐头去尾
            source.append(contentsOf: accountAddress.addressStrip.hex2Bytes)
        }

        if let to = accountBlock.to {
            // to 掐头去尾
            source.append(contentsOf: to.addressStrip.hex2Bytes)
            if let tokenId = accountBlock.tokenId {
                // tokenId 掐头去尾
                source.append(contentsOf: tokenId.tokenIdStrip.hex2Bytes)
            }
            if let amount = accountBlock.amount {
                source.append(contentsOf: amount.description.my_bytes)
            }
        } else {
            if let fromHash = accountBlock.fromHash {
                source.append(contentsOf: fromHash.hex2Bytes)
            }
        }

        // timestamp: The Magic Number
        source.append(contentsOf: "EFBFBD".hex2Bytes)

        if let data = accountBlock.data {
            source.append(contentsOf: data.my_bytes)
        }

        if let snapshotChainHash = accountBlock.snapshotChainHash {
            source.append(contentsOf: snapshotChainHash.hex2Bytes)
        }

        if let nonce = accountBlock.nonce {
            source.append(contentsOf: nonce.hex2Bytes)
        }

        if let difficulty = accountBlock.difficulty {
            source.append(contentsOf: difficulty.hex2Bytes)
        }

        if let fAmount = accountBlock.fAmount {
            source.append(contentsOf: fAmount.description.my_bytes)
        }

        let hash = Blake2b.hash(outLength: 32, in: source) ?? Bytes()
        let hashString = hash.toHexString()
        let signature = Ed25519.sign(message: hash, secretKey: secretKeyHexString.hex2Bytes, publicKey: publicKeyHexString.hex2Bytes).toHexString()
        return (hashString, signature)
    }
}

extension String {
    public var my_bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
}
