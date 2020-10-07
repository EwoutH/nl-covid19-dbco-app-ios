/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol OnboardingStepViewControllerDelegate: class {
    func onboardingStepViewControllerWantsToContinue(_ controller: OnboardingStepViewController)
}

class OnboardingStepViewModel {
    let image: UIImage
    let title: String
    let message: String
    let buttonTitle: String
    
    init(image: UIImage, title: String, message: String, buttonTitle: String) {
        self.image = image
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }
}

class OnboardingStepViewController: UIViewController {
    private let viewModel: OnboardingStepViewModel
    private var imageView: UIImageView!
    
    weak var delegate: OnboardingStepViewControllerDelegate?
    
    init(viewModel: OnboardingStepViewModel) {
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
        
        let titleLabel = UILabel()
        titleLabel.font = Theme.fonts.title2
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.title
        
        let messageLabel = UILabel()
        messageLabel.font = Theme.fonts.body
        messageLabel.textColor = Theme.colors.captionGray
        messageLabel.numberOfLines = 0
        messageLabel.text = viewModel.message
        
        let textContainerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          titleLabel,
                          messageLabel),
                   Button(title: viewModel.buttonTitle, style: .primary)
                       .touchUpInside(self, action: #selector(handleContinue)))
        
        textContainerView.snap(to: .bottom,
                               of: view.readableContentGuide,
                               insets: .bottom(16))
        
        imageView = UIImageView(image: viewModel.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let imageCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        imageCenterYConstraint.priority = .defaultLow
        imageCenterYConstraint.isActive = true
        
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -32).isActive = true
        
        let imageTextSpacingConstraint = imageView.bottomAnchor.constraint(lessThanOrEqualTo: textContainerView.topAnchor, constant: -105)
        imageTextSpacingConstraint.priority = .defaultLow
        imageTextSpacingConstraint.isActive = true
        
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 16).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @objc private func handleContinue() {
        delegate?.onboardingStepViewControllerWantsToContinue(self)
    }

}
