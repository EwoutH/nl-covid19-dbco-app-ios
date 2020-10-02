/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

extension CNContact {
    var fullName: String {
        return CNContactFormatter.string(from: self, style: .fullName) ?? ""
    }
}

class SelectContactViewModel {
    
    private let contactStore = CNContactStore()
    private let contacts: [CNContact]
    private let suggestedContacts: [CNContact]
    private var searchResults: [CNContact]
    
    private let contactTableViewManager: TableViewManager<ContactTableViewCell>
    private let searchTableViewManager: TableViewManager<ContactTableViewCell>
    
    init(suggestedName: String? = nil) {
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactTypeKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName
        
        do {
            var contacts = [CNContact]()
            try contactStore.enumerateContacts(with: request) { contact, stop in
                if contact.contactType == .person {
                    contacts.append(contact)
                }
            }
            self.contacts = contacts
        } catch {
            contacts = []
        }
        
        if let suggestedNameParts = suggestedName?.lowercased().split(separator: " ") {
            var maxMatchedParts = 0
            
            func calculateMatchedParts(for contact: CNContact) -> Int {
                var matchedParts: Int = 0
                var contactNameParts = contact.fullName.lowercased().split(separator: " ")
                
                for part in suggestedNameParts {
                    if let matchedIndex = contactNameParts.firstIndex(where: { $0.starts(with: part) }) {
                        contactNameParts.remove(at: matchedIndex)
                        matchedParts += 1
                    }
                }
                
                maxMatchedParts = max(matchedParts, maxMatchedParts)
                
                return matchedParts
            }
            
            let sortedSuggestions = contacts
                .map { (contact: $0, matchedParts: calculateMatchedParts(for: $0)) }
                .filter { $0.matchedParts > 1 }
                .sorted { $0.matchedParts > $1.matchedParts }
                .prefix { $0.matchedParts == maxMatchedParts }
            
            suggestedContacts = sortedSuggestions.map { $0.contact }
        } else {
            suggestedContacts = []
        }
        
        searchResults = []
        
        contactTableViewManager = .init()
        searchTableViewManager = .init()
        
        var sections = [(title: String, contacts: [CNContact])]()
        
        if !suggestedContacts.isEmpty {
            sections.append((.selectContactSuggestions, suggestedContacts))
        }
        
        sections.append((.selectContactOtherContacts, contacts))
        
        contactTableViewManager.numberOfSections = { sections.count }
        contactTableViewManager.numberOfRowsInSection = { sections[$0].contacts.count }
        contactTableViewManager.itemForCellAtIndexPath = { sections[$0.section].contacts[$0.row] }
        contactTableViewManager.titleForHeaderInSection = { sections.count > 1 ? sections[$0].title : nil }
        
        searchTableViewManager.numberOfRowsInSection = { [unowned self] _ in searchResults.count }
        searchTableViewManager.itemForCellAtIndexPath = { [unowned self] in searchResults[$0.row] }
        
    }
    
    private var numberOfSections: Int {
        return suggestedContacts.isEmpty ? 1 : 2
    }
    
    var searchText: String? {
        didSet {
            if let searchText = searchText, !searchText.isEmpty {
                searchResults = contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
            } else {
                searchResults = []
            }
            
            searchTableViewManager.reloadData()
        }
    }
    
    func setupContactsTableView(_ tableView: UITableView, sectionHeaderViewBuilder: @escaping (String) -> UIView, selectedContactHandler: @escaping (CNContact, IndexPath) -> Void) {
        contactTableViewManager.manage(tableView)
        contactTableViewManager.didSelectItem = selectedContactHandler
        contactTableViewManager.viewForHeaderInSection = { [unowned self] section in
            guard let title = contactTableViewManager.titleForHeaderInSection?(section) else {
                return nil
            }
            
            return sectionHeaderViewBuilder(title)
        }
    }
    
    func setupSearchTableView(_ tableView: UITableView, selectedContactHandler: @escaping (CNContact, IndexPath) -> Void) {
        searchTableViewManager.manage(tableView)
        searchTableViewManager.didSelectItem = selectedContactHandler
    }
    
    
}

protocol SelectContactViewControllerDelegate: class {
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact)
    func selectContactViewControllerDidRequestManualInput(_ controller: SelectContactViewController)
    func selectContactViewControllerDidCancel(_ controller: SelectContactViewController)
}

class SelectContactViewController: PromptableViewController {
    private let viewModel: SelectContactViewModel
    private let searchResultsController: SearchResultsViewController
    private let tableView: UITableView = .createDefaultGrouped()
    private let searchController: UISearchController
    
    weak var delegate: SelectContactViewControllerDelegate?
    
    init(viewModel: SelectContactViewModel) {
        self.viewModel = viewModel
        self.searchResultsController = SearchResultsViewController(viewModel: viewModel)
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        self.searchResultsController.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = .selectContactTitle
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        setupTableView()
        setupSearchController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.indexPathForSelectedRow.map { tableView.deselectRow(at: $0, animated: true) }
    }
    
    private func setupTableView() {
        promptView = Button(title: .selectContactAddManually, style: .secondary)
            .touchUpInside(self, action: #selector(requestManualInput))

        viewModel.setupContactsTableView(
            tableView,
            sectionHeaderViewBuilder: {
                let label = UILabel()
                label.text = $0.uppercased()
                label.font = Theme.fonts.caption1
                label.textColor = Theme.colors.primary
                return label.wrappedInReadableContentGuide(insets: .top(10) + .bottom(5))
            },
            selectedContactHandler: { [weak self] contact, _ in
                guard let self = self else { return }
                self.delegate?.selectContactViewController(self, didSelect: contact)
            })
        
        tableView.embed(in: contentView)
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = .selectContactSearch
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    @objc private func requestManualInput() {
        delegate?.selectContactViewControllerDidRequestManualInput(self)
    }
    
    @objc private func cancel() {
        delegate?.selectContactViewControllerDidCancel(self)
    }
    
}

extension SelectContactViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text
    }

}

extension SelectContactViewController: SearchResultsViewControllerDelegate {
    
    fileprivate func searchResultsViewController(_ controller: SearchResultsViewController, didSelect contact: CNContact) {
        delegate?.selectContactViewController(self, didSelect: contact)
    }
    
}

// MARK: - Search Results
private protocol SearchResultsViewControllerDelegate: class {
    
    func searchResultsViewController(_ controller: SearchResultsViewController, didSelect contact: CNContact)
    
}

private class SearchResultsViewController: UIViewController {
    private let viewModel: SelectContactViewModel
    private let tableView: UITableView = .createDefaultGrouped()
    private let searchController = UISearchController(searchResultsController: nil)
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    init(viewModel: SelectContactViewModel) {
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
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.indexPathForSelectedRow.map { tableView.deselectRow(at: $0, animated: true) }
    }
    
    private func setupTableView() {
        tableView.embed(in: view)
        viewModel.setupSearchTableView(tableView) { [weak self] contact, _ in
            guard let self = self else { return }
            self.delegate?.searchResultsViewController(self, didSelect: contact)
        }
    }
    
}