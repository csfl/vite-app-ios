//
//  WalletHomeBalanceInfoViewModel.swift
//  Vite
//
//  Created by Stone on 2018/9/9.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class WalletHomeBalanceInfoViewModel: WalletHomeBalanceInfoViewModelType {

    let tokenId: String
    let iconImage: UIImage
    let name: String
    let balance: String
    let unconfirmed: String
    let unconfirmedCount: Int

    init(balanceInfo: BalanceInfo) {
        self.tokenId = balanceInfo.token.id
        self.iconImage = balanceInfo.token.defaultIconImage
        self.name = balanceInfo.token.name
        self.balance = balanceInfo.balance.amountShort
        self.unconfirmed = balanceInfo.unconfirmedBalance.amountShort
        self.unconfirmedCount = balanceInfo.unconfirmedCount
    }
}