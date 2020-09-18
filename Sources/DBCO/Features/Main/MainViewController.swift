/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol MainViewControllerDelegate: class {
    func mainViewControllerWantsHelp(_ controller: MainViewController)
    func mainViewControllerRequestContact(_ controller: MainViewController)
}

class MainViewController: UIViewController {
    
    weak var delegate: MainViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let helpButton = UIButton(type: .system)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.setTitle(.helpTitle, for: .normal)
        helpButton.addTarget(self, action: #selector(openHelp), for: .touchUpInside)
        
        let contactButton = UIButton(type: .system)
        contactButton.translatesAutoresizingMaskIntoConstraints = false
        contactButton.setTitle("Choose Contact", for: .normal)
        contactButton.addTarget(self, action: #selector(requestContact), for: .touchUpInside)
        
        let versionLabel = UILabel(frame: .zero)
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.text = .mainAppVersionTitle
        versionLabel.textColor = .lightGray
        versionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        let stackView = UIStackView(arrangedSubviews: [contactButton, helpButton, versionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
    
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
    }
    
    @objc private func openHelp(_ sender: Any) {
        delegate?.mainViewControllerWantsHelp(self)
    }
    
    @objc private func requestContact(_ sender: Any) {
        delegate?.mainViewControllerRequestContact(self)
    }

}
