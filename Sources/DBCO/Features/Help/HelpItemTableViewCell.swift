/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class HelpItemTableViewCell: UITableViewCell {
    
    static let reuseIdentifier: String = String(describing: HelpItemTableViewCell.self)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(for item: HelpItem) {
        textLabel?.text = item.title
    }

    private func build() {
        separatorView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        addSubview(separatorView)
    }

    private func setupConstraints() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        textLabel?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        textLabel?.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        textLabel?.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        textLabel?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }

    // MARK: - Private

    private let separatorView = UIView()
}