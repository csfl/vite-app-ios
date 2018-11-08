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

        self.reactor?.action.onNext(.refreshData)
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
    func bind(reactor: MyVoteInfoViewReactor) {
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
            reactor.action.onNext(.cancelVote)
         }.disposed(by: rx.disposeBag)

        //handle new vote data coming
        reactor.state
            .map { $0.voteInfo }
            .bind {
//                guard let voteInfo = $0 else {
//                    self.viewInfoView.isHidden = true
//                    self.voteInfoEmptyView.isHidden = false
//                    return
//                }
                var voteInfo = VoteInfo()
                voteInfo.nodeName = "dfasdfasfdasfdasdf"
                voteInfo.nodeStatus = .invalid
                voteInfo.balance = Balance.init(value: BigInt(121221221221221221222122122212.121))

                self.viewInfoView.isHidden = false
                self.voteInfoEmptyView.isHidden = true
                self.viewInfoView.reloadData(voteInfo, voteInfo.nodeStatus == .invalid ? .voteInvalid : .voteSuccess)
            }.disposed(by: disposeBag)

        //handle error message 
        reactor.state
            .map { $0.errorMessage }
            .filterNil()
            .bind { Toast.show($0) }
            .disposed(by: disposeBag)
    }
}
