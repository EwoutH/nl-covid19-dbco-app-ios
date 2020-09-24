/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TaskOverviewViewControllerDelegate: class {
    func taskOverviewViewControllerDidRequestHelp(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task)
}

class SeparatorView: UIView {
    
    init() {
        super.init(frame: .zero)
        setup()
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = Theme.colors.separator
    }
}

class TaskOverviewViewModel {
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private let taskManager: TaskManager
    private var headerView: UIView?
    private var footerView: UIView?
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        tableViewManager = .init()
        
        tableViewManager.numberOfRowsInSection = { [unowned self] _ in return self.taskManager.tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return self.taskManager.tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] _ in return self.headerView }
        tableViewManager.viewForFooterInSection = { [unowned self] _ in return self.footerView }
    }
    
    func setupTableView(_ tableView: UITableView, headerView: UIView, footerView: UIView, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.headerView = headerView
        self.footerView = footerView
    }
}

class TaskOverviewViewController: UIViewController {
    private let viewModel: TaskOverviewViewModel
    private let tableView = UITableView.createDefaultGrouped()
    
    weak var delegate: TaskOverviewViewControllerDelegate?
    
    
    required init(viewModel: TaskOverviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        title = "Mijn contacten"
        
        setupTableView()
        
        let confirmContainerView = UIView()
        confirmContainerView.preservesSuperviewLayoutMargins = true
        
        SeparatorView()
            .snap(to: .top, of: confirmContainerView, height: 1)
        
        Button(title: "Ik ben klaar")
            .embed(in: confirmContainerView.readableContentGuide, insets: .top(5) + .bottom(10))
        
        
        let stackView = UIStackView(vertical: [tableView, confirmContainerView])
        stackView.preservesSuperviewLayoutMargins = true
        stackView.embed(in: view)
    }
    
    private func setupTableView() {
        tableView.delaysContentTouches = false
        
        let headerText = "Vul de contactgegevens aan van deze contacten die je samen met de GGD in kaart hebt gebracht. Doe dit snel. <a href=\"app://readmore\">Lees meer</a>"
        
        let headerView = TextView(htmlText: headerText)
            .linkTouched { [weak self] _ in self?.openHelp() }
            .wrappedInReadableContentGuide(insets: .topBottom(10))
        
        let footerView = Button(title: "+ Contact toevoegen", style: .secondary)
            .touchUpInside(self, action: #selector(requestContact))
            .wrappedInReadableContentGuide(insets: .top(5) + .bottom(10))
        
        viewModel.setupTableView(tableView, headerView: headerView, footerView: footerView) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.taskOverviewViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    @objc private func openHelp() {
        delegate?.taskOverviewViewControllerDidRequestHelp(self)
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }

}
