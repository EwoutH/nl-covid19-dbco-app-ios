/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

final class TaskOverviewCoordinator: Coordinator {
    private let window: UIWindow
    private let overviewController: TaskOverviewViewController
    private let navigationController: NavigationController
    private let taskManager: TaskManager
    private var selectedTask: Task?
    
    init(window: UIWindow) {
        self.window = window
        taskManager = TaskManager()
        
        let viewModel = TaskOverviewViewModel(taskManager: taskManager)
        
        overviewController = TaskOverviewViewController(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: overviewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        super.init()
        
        overviewController.delegate = self
    }
    
    override func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func openHelp() {
        startChildCoordinator(HelpCoordinator(presenter: overviewController, delegate: self))
    }
    
    func selectContact(suggestedName: String?) {
        startChildCoordinator(SelectContactCoordinator(presenter: overviewController, suggestedName: suggestedName, delegate: self))
    }
    
    func editContact(contact: Contact) {
        startChildCoordinator(EditContactCoordinator(presenter: overviewController, contact: contact, delegate: self))
    }

}

// MARK: - Coordinator delegates
extension TaskOverviewCoordinator: HelpCoordinatorDelegate {
    
    func helpCoordinatorDidFinish(_ coordinator: HelpCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

extension TaskOverviewCoordinator: SelectContactCoordinatorDelegate {
    
    func selectContactCoordinatorDidFinish(_ coordinator: SelectContactCoordinator, with contact: Contact?) {
        removeChildCoordinator(coordinator)
        
        guard let contact = contact else {
            return
        }
        
        if let task = selectedTask as? ContactDetailsTask {
            taskManager.setContact(contact, for: task)
            selectedTask = nil
        } else {
            taskManager.addContact(contact)
        }
    }
    
}

extension TaskOverviewCoordinator: EditContactCoordinatorDelegate {
    
    func editContactCoordinator(_ coordinator: EditContactCoordinator, didFinishEditing contact: Contact) {
        removeChildCoordinator(coordinator)
        
        if let task = selectedTask as? ContactDetailsTask {
            taskManager.setContact(contact, for: task)
            selectedTask = nil
        }
    }
    
    func editContactCoordinatorDidCancel(_ coordinator: EditContactCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
}

// MARK: - ViewController delegates
extension TaskOverviewCoordinator: TaskOverviewViewControllerDelegate {
    
    func taskOverviewViewControllerDidRequestHelp(_ controller: TaskOverviewViewController) {
        openHelp()
    }
    
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController) {
        selectContact(suggestedName: nil)
    }
    
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task) {
        selectedTask = task
        
        switch task {
        case let contactDetailsTask as ContactDetailsTask:
            if let contact = contactDetailsTask.contact {
                // edit flow
                editContact(contact: contact)
            } else {
                // pick flow
                selectContact(suggestedName: contactDetailsTask.name)
            }
        default:
            break
        }
    }
    
}
