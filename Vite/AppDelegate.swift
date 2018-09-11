//
//  AppDelegate.swift
//  Vite
//
//  Created by Water on 2018/8/15.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import Vite_keystore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        handleNotification()
        _ = SettingDataService.sharedInstance.getCurrentLanguage()

        window = UIWindow(frame: UIScreen.main.bounds)
        handleRootVC()
        return true
    }

    func handleNotification() {
        NotificationCenter.default.rx
            .notification(.createAccountSuccess)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.handleRootVC()
            }).disposed(by: rx.disposeBag)
    }

    func handleRootVC() {
        if  WalletDataService.shareInstance.isExistWallet() {
            let rootVC = CreateAccountHomeViewController()
            rootVC.automaticallyShowDismissButton = false
            let nav = BaseNavigationController(rootViewController: rootVC)
            window?.rootViewController = nav
        } else {
            let rootVC = HomeViewController()
            window?.rootViewController = rootVC
        }
        window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {

    }

    func applicationWillTerminate(_ application: UIApplication) {

    }
}
