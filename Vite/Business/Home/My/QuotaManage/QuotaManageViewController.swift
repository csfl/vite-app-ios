//
//  QuotaManageViewController.swift
//  Vite
//
//  Created by Stone on 2018/10/25.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import NSObject_Rx
import BigInt

class QuotaManageViewController: BaseViewController {
    // FIXME: Optional
    let bag = HDWalletManager.instance.bag!

    var address: Address?
    var balance: Balance

    init() {
        self.balance = Balance(value: BigInt(0))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        initBinds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        kas_activateAutoScrollingForView(contentView)
    }

    // View
    lazy var scrollView = ScrollableView().then {
        $0.layer.masksToBounds = false
        if #available(iOS 11.0, *) {
            $0.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }

    lazy var contentView = UIView()

    // headerView
    lazy var headerView = SendHeaderView(address: bag.address.description)

    // money
    lazy var amountView = TitleMoneyInputView(title: R.string.localizable.quotaManagePageQuotaMoneyTitle.key.localized(), placeholder: R.string.localizable.quotaManagePageQuotaMoneyPlaceholder.key.localized(), content: "", desc: TokenCacheService.instance.viteToken.symbol)

    //snapshoot height
    lazy var snapshootHeightLab = TitleDescView(title: R.string.localizable.quotaManagePageQuotaSnapshootHeightTitle.key.localized(), desc: R.string.localizable.quotaManagePageQuotaSnapshootHeightDesc.key.localized())

    lazy var addressView = AddressTextViewView(currentAddress: self.bag.address.description)
    lazy var sendButton = UIButton(style: .blue, title: R.string.localizable.quotaManagePageSubmitBtnTitle.key.localized())
    lazy var checkQuotaListBtn = UIButton(style: .whiteWithoutShadow, title: R.string.localizable.quotaManagePageCheckQuotaListBtnTitle.key.localized())

    private func setupView() {

        navigationTitleView = createNavigationTitleView()

        checkQuotaListBtn.titleLabel?.font = Fonts.Font14_b
        headerView.setupShadow(CGSize(width: 0, height: 5))

        let shadowView = UIView().then {
            $0.backgroundColor = UIColor.white
            $0.layer.shadowColor = UIColor(netHex: 0x000000).cgColor
            $0.layer.shadowOpacity = 0.1
            $0.layer.shadowOffset = CGSize(width: 0, height: 5)
            $0.layer.shadowRadius = 9
        }

        view.addSubview(scrollView)

        scrollView.snp.makeConstraints { (m) in
            m.top.equalTo(navigationTitleView!.snp.bottom)
            m.left.right.bottom.equalTo(view)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (m) in
            m.top.bottom.equalTo(scrollView)
            m.left.right.equalTo(view)
        }

        contentView.addSubview(shadowView)
        contentView.addSubview(headerView)
        contentView.addSubview(addressView)
        contentView.addSubview(amountView)
        contentView.addSubview(snapshootHeightLab)
        contentView.addSubview(sendButton)
        contentView.addSubview(checkQuotaListBtn)

        shadowView.snp.makeConstraints { (m) in
            m.edges.equalTo(headerView)
        }

        headerView.snp.makeConstraints { (m) in
            m.top.equalTo(contentView).offset(10)
            m.left.equalTo(contentView).offset(24)
            m.right.equalTo(contentView).offset(-24)
        }

        addressView.snp.makeConstraints { (m) in
            m.left.right.equalTo(contentView)
            m.top.equalTo(headerView.snp.bottom).offset(30)
        }

        amountView.snp.makeConstraints { (m) in
            m.left.equalTo(contentView).offset(24)
            m.right.equalTo(contentView).offset(-24)
            m.top.equalTo(addressView.snp.bottom).offset(30)
        }

        snapshootHeightLab.snp.makeConstraints { (m) in
            m.left.equalTo(contentView).offset(24)
            m.right.equalTo(contentView).offset(-24)
            m.top.equalTo(amountView.snp.bottom).offset(40)
        }

        sendButton.snp.makeConstraints { (m) in
            m.left.equalTo(contentView).offset(24)
            m.right.equalTo(contentView).offset(-24)
            m.top.equalTo(snapshootHeightLab.snp.bottom).offset(37)
            m.height.equalTo(50)
        }

        checkQuotaListBtn.snp.makeConstraints { (m) in
            m.top.equalTo(sendButton.snp.bottom).offset(16)
            m.left.equalTo(contentView).offset(24)
            m.right.equalTo(contentView).offset(-24)
            m.height.equalTo(20)
            m.bottom.equalToSuperview().offset(-50)
        }

        addressView.textView.keyboardType = .default
        amountView.textField.keyboardType = .decimalPad

        let toolbar = UIToolbar()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: R.string.localizable.finish.key.localized(), style: .done, target: nil, action: nil)
        toolbar.items = [flexSpace, done]
        toolbar.sizeToFit()
        done.rx.tap.bind { [weak self] in self?.amountView.textField.resignFirstResponder() }.disposed(by: rx.disposeBag)
        amountView.textField.inputAccessoryView = toolbar

        addressView.textView.kas_setReturnAction(.next(responder: amountView.textField))
        amountView.textField.delegate = self

        sendButton.rx.tap
            .bind { [weak self] in
                guard let `self` = self else { return }
                let address = Address(string: self.addressView.textView.text ?? "")

                guard address.isValid else {
                    Toast.show(R.string.localizable.sendPageToastAddressError.key.localized())
                    return
                }

                guard let amountString = self.amountView.textField.text,
                    !amountString.isEmpty,
                    let amount = amountString.toBigInt(decimals: TokenCacheService.instance.viteToken.decimals) else {
                        Toast.show(R.string.localizable.sendPageToastAmountEmpty.key.localized())
                        return
                }

                guard amount > BigInt(0) else {
                    Toast.show(R.string.localizable.sendPageToastAmountZero.key.localized())
                    return
                }

                guard amount <= self.balance.value else {
                    Toast.show(R.string.localizable.sendPageToastAmountError.key.localized())
                    return
                }

                let vc = QuotaSubmitPopViewController(money: String.init(format: "%@ %@ ", amountString, TokenCacheService.instance.viteToken.symbol), beneficialAddress: address, amount: amount)
                vc.delegate = self
                vc.modalPresentationStyle = .overCurrentContext
                let delegate =  StyleActionSheetTranstionDelegate()
                vc.transitioningDelegate = delegate
                self.present(vc, animated: true, completion: nil)

            }
            .disposed(by: rx.disposeBag)

        checkQuotaListBtn.rx.tap
            .bind { [weak self] in
                let pledgeHistoryVC = PledgeHistoryViewController()
                pledgeHistoryVC.reactor = PledgeHistoryViewReactor()
                self?.navigationController?.pushViewController(pledgeHistoryVC, animated: true)
            }.disposed(by: rx.disposeBag)
    }

    func createNavigationTitleView() -> UIView {
        let view = UIView().then {
            $0.backgroundColor = UIColor.white
        }

        let titleLabel = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 24)
            $0.numberOfLines = 1
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor(netHex: 0x24272B)
            $0.text = R.string.localizable.quotaManagePageTitle.key.localized()
        }

        let tipButton = UIButton().then {
            $0.setImage(R.image.icon_button_infor(), for: .normal)
            $0.setImage(R.image.icon_button_infor()?.highlighted, for: .highlighted)
        }

        view.addSubview(titleLabel)
        view.addSubview(tipButton)

        titleLabel.snp.makeConstraints { (m) in
            m.top.equalTo(view).offset(6)
            m.left.equalTo(view).offset(24)
            m.bottom.equalTo(view).offset(-20)
            m.height.equalTo(29)
        }

        tipButton.snp.makeConstraints { (m) in
            m.centerY.equalTo(titleLabel)
            m.left.equalTo(titleLabel.snp.right).offset(10)
        }

        tipButton.rx.tap.bind { [weak self] in
            let url  = R.file.quotaDefinitionHtml()!
            let vc = PopViewController(url: url)
            vc.modalPresentationStyle = .overCurrentContext
            let delegate =  StyleActionSheetTranstionDelegate()
            vc.transitioningDelegate = delegate
            self?.present(vc, animated: true, completion: nil)
        }.disposed(by: rx.disposeBag)

        return view
    }
}

//bind
extension QuotaManageViewController {
    func initBinds() {
        FetchBalanceInfoService.instance.balanceInfosDriver.drive(onNext: { [weak self] balanceInfos in
            guard let `self` = self else { return }
            for balanceInfo in balanceInfos where TokenCacheService.instance.viteToken.id == balanceInfo.token.id {
                self.balance = balanceInfo.balance
                self.headerView.balanceLabel.text = balanceInfo.balance.amountFull(decimals: balanceInfo.token.decimals)
                return
            }

            // no balanceInfo, set 0.0
            self.headerView.balanceLabel.text = "0.0"
        }).disposed(by: rx.disposeBag)
        FetchQuotaService.instance.quotaDriver.drive(headerView.quotaLabel.rx.text).disposed(by: rx.disposeBag)
        FetchQuotaService.instance.maxTxCountDriver.drive(headerView.maxTxCountLabel.rx.text).disposed(by: rx.disposeBag)
    }
}

//service
extension QuotaManageViewController {
    //no run pow request service
    func pledgeAndGainQuotaWithoutGetPow(beneficialAddress: Address, amount: BigInt) {
        HUD.show()
        Provider.instance.pledgeAndGainQuotaWithoutGetPow(bag: bag, beneficialAddress: beneficialAddress, tokenId: TokenCacheService.instance.viteToken.id, amount: amount) { [weak self] (result) in
            guard let `self` = self else { return }
            HUD.hide()
            switch result {
            case .success:
                Toast.show("success")
            case .error(let error):
                if error.code == Provider.TransactionErrorCode.notEnoughBalance.rawValue {
                    Alert.show(into: self,
                               title: R.string.localizable.sendPageNotEnoughBalanceAlertTitle.key.localized(),
                               message: nil,
                               actions: [(.default(title: R.string.localizable.sendPageNotEnoughBalanceAlertButton.key.localized()), nil)])
                } else if error.code == Provider.TransactionErrorCode.notEnoughQuota.rawValue {
                    self.pledgeAndGainQuotaWithGetPow(beneficialAddress: beneficialAddress, amount: amount)
                } else {
                    Toast.show(error.message)
                }
            }
        }
    }

    //run pow request service
    func pledgeAndGainQuotaWithGetPow(beneficialAddress: Address, amount: BigInt) {
        var cancelPow = false
        let getPowFloatView = GetPowFloatView(superview: UIApplication.shared.keyWindow!) {
            cancelPow = true
        }

        getPowFloatView.show()
        Provider.instance.pledgeAndGainQuotaWithGetPow(bag: bag, beneficialAddress: beneficialAddress, tokenId: TokenCacheService.instance.viteToken.id, amount: amount, difficulty: AccountBlock.Const.difficulty) { [weak self] (result) in

            guard cancelPow == false else { return }
            guard let `self` = self else { return }
            switch result {
            case .success(let context):

                getPowFloatView.finish {
                    HUD.show()
                    Provider.instance.sendTransactionWithContext(context, completion: { [weak self] (result) in
                        HUD.hide()
                        guard let `self` = self else { return }
                        switch result {
                        case .success:
                            Toast.show("success")
                        case .error(let error):
                            if error.code == Provider.TransactionErrorCode.notEnoughBalance.rawValue {
                                Alert.show(into: self,
                                           title: R.string.localizable.sendPageNotEnoughBalanceAlertTitle.key.localized(),
                                           message: nil,
                                           actions: [(.default(title: R.string.localizable.sendPageNotEnoughBalanceAlertButton.key.localized()), nil)])
                            } else {
                                Toast.show(R.string.localizable.sendPageToastSendFailed.key.localized())
                            }
                        }
                    })
                }
            case .error:
                getPowFloatView.hide()
                Toast.show(R.string.localizable.sendPageToastSendFailed.key.localized())
            }
        }
    }
}

extension QuotaManageViewController: QuotaSubmitPopViewControllerDelegate {
    func confirmAction(beneficialAddress: Address, amount: BigInt) {
           pledgeAndGainQuotaWithoutGetPow(beneficialAddress: beneficialAddress, amount: amount)
    }
}

extension QuotaManageViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountView.textField {
            let (ret, text) = InputLimitsHelper.allowDecimalPointWithDigitalText(textField.text ?? "", shouldChangeCharactersIn: range, replacementString: string, decimals: min(8, TokenCacheService.instance.viteToken.decimals))
            textField.text = text
            return ret
        } else {
            return true
        }
    }
}
