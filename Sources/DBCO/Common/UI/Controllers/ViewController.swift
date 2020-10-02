/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol DismissActionable {
    associatedtype Item
    
    var onDismissed: ((Item) -> Void)? { get set }
}

protocol PopActionable {
    associatedtype Item
    
    var onPopped: ((Item) -> Void)? { get set }
}

class ViewController: UIViewController, DismissActionable, PopActionable {
    var onDismissed: ((ViewController) -> Void)?
    var onPopped: ((ViewController) -> Void)?
    
    func applicationDidBecomeActive() {
        
    }
    
    func startReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = true
        
    }
    
    func stopReceivingDidBecomeActiveNotifications() {
        shouldAddDidBecomeActiveObserver = false
    }
    
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var shouldAddDidBecomeActiveObserver = false
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeDidBecomeActiveObserverIfNeeded()
        
        if isBeingDismissed || navigationController?.isBeingDismissed == true || tabBarController?.isBeingDismissed == true {
            onDismissed?(self)
        } else if isMovingFromParent {
            onPopped?(self)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldAddDidBecomeActiveObserver {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.applicationDidBecomeActive()
            }
        }
    }
    
    private func removeDidBecomeActiveObserverIfNeeded() {
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }
}