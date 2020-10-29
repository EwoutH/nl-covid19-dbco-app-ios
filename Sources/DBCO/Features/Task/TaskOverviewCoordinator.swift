/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

/// Coordinator displaying the tasks for the index with [TaskOverviewViewController](x-source-tag://TaskOverviewViewController).
/// Uses [SelectContactCoordinator](x-source-tag://SelectContactCoordinator) and [EditContactCoordinator](x-source-tag://EditContactCoordinator) for updating tasks.
/// Uses [UploadCoordinator](x-source-tag://UploadCoordinator) to upload the tasks.
///
/// - Tag: TaskOverviewCoordinator
final class TaskOverviewCoordinator: Coordinator {
    private let window: UIWindow
    private let overviewController: TaskOverviewViewController
    private let navigationController: NavigationController
    
    init(window: UIWindow) {
        self.window = window
        
        let viewModel = TaskOverviewViewModel()
        
        overviewController = TaskOverviewViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: overviewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        super.init()
        
        overviewController.delegate = self
    }
    
    override func start() {
        let snapshotView = window.snapshotView(afterScreenUpdates: true)!
        
        window.rootViewController = navigationController
        navigationController.view.addSubview(snapshotView)
        
        UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromRight]) {
            snapshotView.removeFromSuperview()
        }
    }
    
    private func upload() {
        startChildCoordinator(UploadCoordinator(presenter: overviewController, delegate: self))
    }
    
    private func selectContact(for task: Task) {
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }
    
    private func addContact() {
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, contactTask: nil, delegate: self))
    }
    
    private func editContact(for task: Task) {
        startChildCoordinator(EditContactCoordinator(presenter: overviewController, contactTask: task, delegate: self))
    }

}

// MARK: - Coordinator delegates
extension TaskOverviewCoordinator: SelectContactCoordinatorDelegate {

    func selectContactCoordinator(_ coordinator: SelectContactCoordinator, didFinishWith task: Task) {
        removeChildCoordinator(coordinator)
        
        Services.caseManager.save(task)
    }
    
    func selectContactCoordinatorDidCancel(_ coordinator: SelectContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: EditContactCoordinatorDelegate {
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishContactTask task: Task) {
        removeChildCoordinator(coordinator)
        
        Services.caseManager.save(task)
    }
    
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: UploadCoordinatorDelegate {
    
    func uploadCoordinatorDidFinish(_ coordinator: UploadCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

// MARK: - ViewController delegates
extension TaskOverviewCoordinator: TaskOverviewViewControllerDelegate {
    
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController) {
        addContact()
    }
    
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task) {
        switch task.taskType {
        case .contact:
            if task.result != nil {
                // edit flow
                editContact(for: task)
            } else {
                // pick flow
                selectContact(for: task)
            }
        }
    }
    
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController) {
        upload()
    }
    
}
