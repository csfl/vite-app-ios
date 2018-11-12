//
//  MyVoteInfoViewController.swift
//  Vite
//
//  Created by Water on 2018/11/5.
//  Copyright © 2018年 vite labs. All rights reserved.
//
import BigInt
import RxSwift
import ReactorKit
import RxDataSources

class MyVoteInfoViewController: BaseViewController, View {
    // FIXME: Optional
    let bag = HDWalletManager.instance.bag!
    var disposeBag = DisposeBag()
    var timerBag: DisposeBag! = DisposeBag()
    var balance: Balance?
    var oldVoteInfo: VoteInfo?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.reactor = MyVoteInfoViewReactor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self._setupView()
        self._bindView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reactor?.action.onNext(.refreshData(HDWalletManager.instance.bag?.address.description ?? ""))
        self._pollingInfoData()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timerBag = nil
    }

    private func _pollingInfoData () {
        self.timerBag  = DisposeBag()
        Observable<Int>.interval(3, scheduler: MainScheduler.instance).bind { [weak self] _ in
            self?.reactor?.action.onNext(.refreshData(HDWalletManager.instance.bag?.address.description ?? ""))
        }.disposed(by: self.timerBag)
    }

    private func _bindView() {
        //home page vite balance
        FetchBalanceInfoService.instance.balanceInfosDriver.drive(onNext: { [weak self] balanceInfos in
            guard let `self` = self else { return }
            for balanceInfo in balanceInfos where TokenCacheService.instance.viteToken.id == balanceInfo.token.id {
                self.balance = balanceInfo.balance
                return
            }
            if self.viewInfoView.voteStatus == .voting {
                // no balanceInfo, set 0.0
                self.viewInfoView.nodePollsLab.text = "0.0"
            }
        }).disposed(by: rx.disposeBag)

        self.viewInfoView.nodeStatusLab.tipButton.rx.tap.bind { [weak self] in
            let url  = URL(string: String(format: "%@?localize=%@", Constants.voteLoserURL, LocalizationService.sharedInstance.currentLanguage.rawValue))!
            let vc = PopViewController(url: url)
            vc.modalPresentationStyle = .overCurrentContext
            let delegate =  StyleActionSheetTranstionDelegate()
            vc.transitioningDelegate = delegate
            self?.present(vc, animated: true, completion: nil)
        }.disposed(by: rx.disposeBag)

        //handle cancel vote
        self.viewInfoView.operationBtn.rx.tap.bind {_ in
            self.cancelVote()
        }.disposed(by: rx.disposeBag)
    }

    private func _setupView() {
        self._addViewConstraint()
    }

    private func _addViewConstraint() {
        view.backgroundColor = .clear

        view.addSubview(self.viewInfoView)
        self.viewInfoView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }

        view.addSubview(self.voteInfoEmptyView)
        self.voteInfoEmptyView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        self.viewInfoView.isHidden = true
        self.voteInfoEmptyView.isHidden = false
    }

    private func cancelVote() {
        let confirmVC = ConfirmTransactionViewController.comfirmVote(title: R.string.localizable.votePageVoteInfoCancelVoteTitle.key.localized(),
                                                                     nodeName: self.viewInfoView.voteInfo?.nodeName ?? "") { [unowned self] (result) in
                                                                        switch result {
                                                                        case .success:
                                                                        self.reactor?.action.onNext(.cancelVote)
                                                                        case .cancelled:
                                                                            plog(level: .info, log: "Confirm vote cancel cancelled", tag: .vote)
                                                                        case .biometryAuthFailed:
                                                                            Alert.show(into: self,
                                                                                       title: R.string.localizable.sendPageConfirmBiometryAuthFailedTitle.key.localized(),
                                                                                       message: nil,
                                                                                       actions: [(.default(title: R.string.localizable.sendPageConfirmBiometryAuthFailedBack.key.localized()), nil)])
                                                                        case .passwordAuthFailed:
                                                                            Alert.show(into: self,
                                                                                       title: R.string.localizable.confirmTransactionPageToastPasswordError.key.localized(),
                                                                                       message: nil,
                                                                                       actions: [(.default(title: R.string.localizable.sendPageConfirmPasswordAuthFailedRetry.key.localized()), { [unowned self] _ in
                                                                                        self.cancelVote()
                                                                                       }), (.cancel, nil)])

                                                                        }
        }
        self.present(confirmVC, animated: false, completion: nil)
    }

    lazy var viewInfoView: VoteInfoView = {
        let viewInfoView = VoteInfoView()
        return viewInfoView
    }()

    lazy var voteInfoEmptyView: VoteInfoEmptyView = {
        let voteInfoEmptyView = VoteInfoEmptyView()
        return voteInfoEmptyView
    }()
}

extension MyVoteInfoViewController {
    private func refreshVoteInfoView(_ voteInfo: VoteInfo, _ voteStatus: VoteStatus) {
        self.viewInfoView.isHidden = false
        self.voteInfoEmptyView.isHidden = true
        self.viewInfoView.reloadData(voteInfo, voteInfo.nodeStatus == .invalid ? .voteInvalid :voteStatus)

        self.notificationList(voteInfo, voteStatus)
    }

    private func notificationList(_ voteInfo: VoteInfo, _ voteStatus: VoteStatus) {
        NotificationCenter.default.post(name: .userVoteInfoChange, object: ["voteInfo": voteInfo, "voteStatus": voteStatus])
    }

    func bind(reactor: MyVoteInfoViewReactor) {

        //vote success
        _ = NotificationCenter.default.rx.notification(.userDidVote).takeUntil(self.rx.deallocated).observeOn(MainScheduler.instance).subscribe({[weak self] (notification)   in
            let nodeName = notification.element?.object
            self?.reactor?.action.onNext(.voting(nodeName as! String, self?.balance))
        })

        //handle new vote data coming
        reactor.state
            .map { ($0.voteInfo, $0.voteStatus, $0.error) }
            .bind {[weak self] in
                guard let voteStatus = $1 else {
                    return
                }
                guard let error = $2 else {
                    //handle cancel vote
                    if voteStatus == .cancelVoting {
                        self?.refreshVoteInfoView(self?.oldVoteInfo ?? VoteInfo(), voteStatus)
                        return
                    }

                    guard let voteInfo = $0 else {
                        //voteInfo == nil && old voteStatus = voting
                        if self?.viewInfoView.voteStatus != .voting {
                            self?.viewInfoView.isHidden = true
                            self?.voteInfoEmptyView.isHidden = false
                        }
                        return
                    }
                    //server node can't affirm
                    if self?.oldVoteInfo?.nodeName == voteInfo.nodeName &&
                        (self?.viewInfoView.voteStatus == .voting || self?.viewInfoView.voteStatus == .cancelVoting) {
                        self?.notificationList(voteInfo , voteStatus)
                        return
                    }
                    //voteInfo != nil && new voteStatus = voting, old  voteInfo
                    if voteStatus != .voting && voteStatus != .cancelVoting {
                        self?.oldVoteInfo = voteInfo
                    }

                    self?.refreshVoteInfoView(voteInfo, voteStatus)
                    return
                }
                self?.handler(error: error)

            }.disposed(by: disposeBag)
    }

    func handler(error: Error) {
        if error.code == Provider.TransactionErrorCode.notEnoughBalance.rawValue {
            Alert.show(into: self,
                       title: R.string.localizable.sendPageNotEnoughBalanceAlertTitle.key.localized(),
                       message: nil,
                       actions: [(.default(title: R.string.localizable.sendPageNotEnoughBalanceAlertButton.key.localized()), nil)])
        } else if error.code == Provider.TransactionErrorCode.notEnoughQuota.rawValue {
            Alert.show(into: self, title: R.string.localizable.quotaAlertTitle.key.localized(), message: R.string.localizable.voteListAlertQuota.key.localized(), actions: [
                (.default(title: R.string.localizable.quotaAlertQuotaButtonTitle.key.localized()), { [weak self] _ in
                    let vc = QuotaManageViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }),
                (.default(title: R.string.localizable.quotaAlertPowButtonTitle.key.localized()), { [weak self] _ in
                    self?.view.displayLoading()
                    self?.reactor?.cancelVoteAndSendWithGetPow(completion: { (_) in
                            self?.view.hideLoading()
                    })
                }),
                (.cancel, nil),
                ], config: { alert in
                    alert.preferredAction = alert.actions[0]
            })
        } else {
            Toast.show(R.string.localizable.voteListSendFailed.key.localized())
        }
    }
}
