/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class PromptableViewController: ViewController {
    
    private class PromptView: UIView {
        var contentView = UIView()
        var promptContainerView = UIView()
        var hiddenObserver: Any?
        var promptView: UIView? {
            willSet {
                hiddenObserver = nil
                promptView?.removeFromSuperview()
            }
            
            didSet {
                guard let promptView = promptView else { return }
                
                promptView.setContentCompressionResistancePriority(.required, for: .vertical)
                promptView.setContentHuggingPriority(.required, for: .vertical)
                
                promptView.embed(in: CustomEmbeddable(view: promptContainerView,
                                                      leadingAnchor: promptContainerView.readableContentGuide.leadingAnchor,
                                                      trailingAnchor: promptContainerView.readableContentGuide.trailingAnchor,
                                                      topAnchor: promptContainerView.topAnchor,
                                                      bottomAnchor: promptContainerView.safeAreaLayoutGuide.bottomAnchor),
                                 insets: .top(12) + .bottom(16))
                
                hiddenObserver = promptView.observe(\.isHidden) { [weak self] view, _ in
                    self?.promptContainerView.isHidden = view.isHidden
                }
                
                promptContainerView.isHidden = promptView.isHidden
            }
        }
        
        init() {
            super.init(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 480)))
            
            contentView.backgroundColor = .white
            
            promptContainerView.backgroundColor = .white
            
            SeparatorView()
                .snap(to: .top, of: promptContainerView)
            
            let stackView = UIStackView(vertical: [contentView, promptContainerView])
            stackView.embed(in: self)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var contentView: UIView {
        return (view as! PromptView).contentView
    }
    
    var promptView: UIView? {
        get {
            (view as! PromptView).promptView
        }
        
        set {
            (view as! PromptView).promptView = newValue
        }
    }
    
    override func loadView() {
        view = PromptView()
    }
    
    func hidePrompt(animated: Bool = true) {
        guard animated else {
            promptView?.isHidden = true
            view.layoutIfNeeded()
            return
        }
        
        // Expands the view so the prompt container will be outside of the screen (animated)
        // Then hides the prompt container and restores the view's height
        
        guard promptView?.isHidden == false else {
            return
        }
        
        let originalFrame = view.frame
        
        var frame = view.frame
        frame.size.height += (view as! PromptView).promptContainerView.frame.height
        view.frame = frame
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.promptView?.isHidden = true
                self.promptView?.layoutIfNeeded()
                self.view.frame = originalFrame
            })
    }
    
    func showPrompt(animated: Bool = true) {
        guard animated else {
            promptView?.isHidden = false
            view.layoutIfNeeded()
            return
        }
        
        // Shows the prompt container
        // Then expands the view so the prompt container will be outside of the screen
        // Then restores view's original height (animated)
        
        guard promptView?.isHidden == true else {
            return
        }
        
        let originalFrame = view.frame
        
        promptView?.isHidden = false
        
        view.layoutIfNeeded()
        
        var frame = view.frame
        frame.size.height += (view as! PromptView).promptContainerView.frame.height
        view.frame = frame
        
        view.layoutIfNeeded()
        
        view.frame = originalFrame
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.view.layoutIfNeeded()
            })
    }
    
}
