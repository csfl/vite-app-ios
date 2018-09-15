//
//  BackupMnemonicViewController.swift
//  Vite
//
//  Created by Water on 2018/9/4.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import SnapKit
import Vite_keystore

class BackupMnemonicViewController: BaseViewController {
    fileprivate var viewModel: BackupMnemonicVM

    init() {
        self.viewModel = BackupMnemonicVM()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self._setupView()
        self._bindViewModel()
    }

    lazy var tipTitleLab: UILabel = {
        let tipTitleLab = UILabel()
        tipTitleLab.textAlignment = .left
        tipTitleLab.numberOfLines = 0
        tipTitleLab.adjustsFontSizeToFitWidth = true
        tipTitleLab.font = Fonts.descFont
        tipTitleLab.textColor  = Colors.titleGray
        tipTitleLab.text =  R.string.localizable.mnemonicBackupPageTipTitle.key.localized()
        return tipTitleLab
    }()

    lazy var tipContentTitleLab: UILabel = {
        let tipContentTitleLab = UILabel()
        tipContentTitleLab.textAlignment = .left
        tipContentTitleLab.font =  AppStyle.descWord.font
        tipContentTitleLab.textColor  = AppStyle.descWord.textColor
        tipContentTitleLab.text =  R.string.localizable.mnemonicBackupPageTitle.key.localized()
        return tipContentTitleLab
    }()

    lazy var tipContentLab: UILabel = {
        let tipContentLab =  UILabel()
        tipContentLab.numberOfLines = 0
        tipContentLab.textColor = .black
        return tipContentLab
    }()

    lazy var afreshMnemonicBtn: UIButton = {
        let afreshMnemonicBtn = UIButton.init(style: .white)

        afreshMnemonicBtn.setTitle(R.string.localizable.mnemonicBackupPageTipAnewBtnTitle.key.localized(), for: .normal)
        afreshMnemonicBtn.addTarget(self, action: #selector(afreshMnemonicBtnAction), for: .touchUpInside)
        return afreshMnemonicBtn
    }()

    lazy var nextMnemonicBtn: UIButton = {
        let nextMnemonicBtn = UIButton.init(style: .blue)
        nextMnemonicBtn.setTitle(R.string.localizable.mnemonicBackupPageTipNextBtnTitle.key.localized(), for: .normal)
        nextMnemonicBtn.addTarget(self, action: #selector(nextMnemonicBtnAction), for: .touchUpInside)
        return nextMnemonicBtn
    }()
}

extension BackupMnemonicViewController {
    private func _bindViewModel() {
        _ = self.viewModel.mnemonicWordsStr.asObservable().bind(to: self.tipContentLab.rx.text)
    }

    private func _setupView() {
        self.view.backgroundColor = .white
        navigationTitleView = NavigationTitleView(title: R.string.localizable.mnemonicBackupPageTitle.key.localized())

        self._addViewConstraint()
    }
    private func _addViewConstraint() {
        self.view.addSubview(self.tipTitleLab)
        self.tipTitleLab.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(24+32)
            make.left.equalTo(self.view).offset(24)
            make.right.equalTo(self.view).offset(-24)
            make.height.equalTo(48)
        }

        self.view.addSubview(self.tipContentLab)
        self.tipContentLab.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(200)
            make.height.equalTo(200)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.tipTitleLab.snp.bottom).offset(10)
        }

        self.view.addSubview(self.afreshMnemonicBtn)
        self.afreshMnemonicBtn.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(24)
            make.right.equalTo(self.view).offset(-24)
            make.height.equalTo(50)
            make.bottom.equalTo(self.view.safeAreaLayoutGuideSnp.bottom).offset(-24)
        }

        self.view.addSubview(self.nextMnemonicBtn)
        self.nextMnemonicBtn.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(24)
            make.right.equalTo(self.view).offset(-24)
            make.height.equalTo(50)
            make.bottom.equalTo(self.afreshMnemonicBtn.snp.top).offset(-24)
        }
    }

    @objc func afreshMnemonicBtnAction() {
        _ = self.viewModel.fetchNewMnemonicWords()
    }

    @objc func nextMnemonicBtnAction() {
        CreateWalletService.sharedInstance.walletAccount.mnemonic = self.viewModel.mnemonicWordsStr.value
        let vc = AffirmInputMnemonicViewController.init(mnemonicWordsStr: self.viewModel.mnemonicWordsStr.value)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
