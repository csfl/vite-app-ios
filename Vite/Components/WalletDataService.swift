//
//  WalletDataService.swift
//  Vite
//
//  Created by Water on 2018/9/11.
//  Copyright © 2018年 vite labs. All rights reserved.
//
import Vite_keystore

public class WalletDataService: NSObject {
    static let shareInstance = WalletDataService()

    private let walletStorage: WalletStorage
    //current login account
    public var defaultWalletAccount: WalletAccount?

    public override init() {
        walletStorage = WalletStorage()
        defaultWalletAccount = walletStorage.walletAccounts.first
    }

    public func isExistWallet() -> Bool {
        return walletStorage.walletAccounts.isEmpty
    }

    public func addWallet(account: WalletAccount) {
        walletStorage.add(account: account)
    }

    public func loginWallet(account: WalletAccount) {
        account.isLogin = true
        walletStorage.login(replace: account)
        self.defaultWalletAccount = walletStorage.walletAccounts.first!
        walletStorage.storeAllWallets()
    }

    //if  exist wallet , true has wallets, false no wallets
    public func logoutCurrentWallet() {
        self.defaultWalletAccount?.isLogin = false
        walletStorage.storeAllWallets()
    }

   //true has wallets and , false no wallets
    public func existWalletAndLogout() -> Bool {
        if !walletStorage.walletAccounts.isEmpty && !(walletStorage.walletAccounts.first?.isLogin)! {
            return true
        } else {
            return false
        }
    }
}
