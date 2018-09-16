//
//  PayInfoView.swift
//  Vite
//
//  Created by haoshenyang on 2018/9/14.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import Then
import SnapKit

final class TransactionInfoView: UIView {

    let titleLabel = UILabel().then {
        $0.text = LocalizationStr("Address")
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = UIColor.init(netHex: 0x3E4A59)
    }

    let addressLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = UIColor.init(netHex: 0x24272B)
        $0.numberOfLines = 2
    }

    let backgroundView = UIView().then {
        $0.backgroundColor = UIColor.init(netHex: 0x007AFF, alpha: 0.06)
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 1
        $0.layer.borderColor = UIColor.init(netHex: 0x007AFF, alpha: 0.12).cgColor
    }

    let amountLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 48)
        $0.textColor = UIColor.init(netHex: 0x24272B)
    }

    let tokenLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.init(netHex: 0x24272B)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(addressLabel)
        addSubview(backgroundView)
        addSubview(amountLabel)
        addSubview(tokenLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.leading.equalTo(self)
        }

        addressLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }

        backgroundView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(addressLabel.snp.bottom).offset(10)
            make.leading.equalTo(self.snp.leading)
            make.trailing.equalTo(self.snp.trailing)
            make.bottom.equalTo(self)
        }

        amountLabel.snp.makeConstraints { (make) in
            make.center.equalTo(backgroundView)
            make.leading.greaterThanOrEqualTo(backgroundView.snp.leading).offset(10)
            make.trailing.lessThanOrEqualTo(backgroundView.snp.trailing).offset(-10)
        }

        tokenLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(amountLabel.snp.trailing)
            make.top.equalTo(amountLabel.snp.top)
            make.trailing.lessThanOrEqualTo(backgroundView.snp.trailing)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
