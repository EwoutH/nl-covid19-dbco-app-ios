/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TaskOverviewViewControllerDelegate: class {
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task)
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestShareLogs(_ controller: TaskOverviewViewController)
}

/// - Tag: TaskOverviewViewModel
class TaskOverviewViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String)
    typealias PromptFunction = (_ animated: Bool) -> Void
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    private var hidePrompt: PromptFunction?
    private var showPrompt: PromptFunction?
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        tableViewManager.numberOfSections = { [unowned self] in return sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return sections[$0].header }
        
        Services.caseManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, tableHeaderBuilder: (() -> UIView?)?, sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        
        buildSections()
    }
    
    func setHidePrompt(_ hidePrompt: @escaping PromptFunction) {
        self.hidePrompt = hidePrompt
        
        if Services.caseManager.isSynced {
            hidePrompt(false)
        }
    }
    
    func setShowPrompt(_ showPrompt: @escaping PromptFunction) {
        self.showPrompt = showPrompt
        
        if !Services.caseManager.isSynced {
            showPrompt(false)
        }
    }
    
    private func buildSections() {
        sections = []
        sections.append((tableHeaderBuilder?(), []))
        
        let uninformedContacts = Services.caseManager.tasks.filter { !$0.isOrCanBeInformed }
        let informedContacts = Services.caseManager.tasks.filter { $0.isOrCanBeInformed }
        
        let uninformedSectionHeader = SectionHeaderContent(.taskOverviewUninformedContactsHeaderTitle, .taskOverviewUninformedContactsHeaderSubtitle)
        let informedSectionHeader = SectionHeaderContent(.taskOverviewInformedContactsHeaderTitle, .taskOverviewInformedContactsHeaderSubtitle)
        
        if !uninformedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(uninformedSectionHeader),
                             tasks: uninformedContacts))
        }
        
        if !informedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(informedSectionHeader),
                             tasks: informedContacts))
        }
    }
}

extension TaskOverviewViewModel: CaseManagerListener {
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging) {
        if caseManager.isSynced {
            hidePrompt?(true)
        } else {
            showPrompt?(true)
        }
    }
}

/// - Tag: TaskOverviewViewController
class TaskOverviewViewController: PromptableViewController {
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
        title = .taskOverviewTitle
        
        setupTableView()
        
        promptView = Button(title: .taskOverviewDoneButtonTitle)
            .touchUpInside(self, action: #selector(upload))
        
        viewModel.setHidePrompt { [unowned self] in hidePrompt(animated: $0) }
        viewModel.setShowPrompt { [unowned self] in showPrompt(animated: $0) }
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        
        let tableHeaderBuilder = { [unowned self] in
            Button(title: .taskOverviewAddContactButtonTitle, style: .secondary)
                .touchUpInside(self, action: #selector(requestContact))
                .wrappedInReadableWidth(insets: .top(16))
        }
        
        let sectionHeaderBuilder = { (title: String, subtitle: String) -> UIView in
            VStack(spacing: 4,
                   Label(bodyBold: title).multiline(),
                   Label(subhead: subtitle, textColor: Theme.colors.captionGray).multiline())
                .wrappedInReadableWidth(insets: .top(20) + .bottom(16))
        }
        
        viewModel.setupTableView(tableView, tableHeaderBuilder: tableHeaderBuilder, sectionHeaderBuilder: sectionHeaderBuilder) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.taskOverviewViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let versionLabel = Label(caption1: .mainAppVersionTitle, textColor: Theme.colors.captionGray)
        versionLabel.textAlignment = .center
        versionLabel.sizeToFit()
        versionLabel.frame = CGRect(x: 0, y: 0, width: versionLabel.frame.width, height: 60.0)
        versionLabel.isUserInteractionEnabled = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shareLogs))
        gestureRecognizer.numberOfTapsRequired = 4
        
        versionLabel.addGestureRecognizer(gestureRecognizer)
        
        tableView.tableFooterView = versionLabel
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }
    
    @objc private func upload() {
        delegate?.taskOverviewViewControllerDidRequestUpload(self)
    }
    
    @objc private func shareLogs() {
        delegate?.taskOverviewViewControllerDidRequestShareLogs(self)
    }

}
