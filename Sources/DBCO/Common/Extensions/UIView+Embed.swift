/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol Embeddable {
    var view: UIView? { get }
    
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

struct CustomEmbeddable: Embeddable {
    let view: UIView?
    let leadingAnchor: NSLayoutXAxisAnchor
    let trailingAnchor: NSLayoutXAxisAnchor
    let topAnchor: NSLayoutYAxisAnchor
    let bottomAnchor: NSLayoutYAxisAnchor
}

extension UIView {
    
    var readableWidth: Embeddable {
        return CustomEmbeddable(view: self,
                                leadingAnchor: readableContentGuide.leadingAnchor,
                                trailingAnchor: readableContentGuide.trailingAnchor,
                                topAnchor: topAnchor,
                                bottomAnchor: bottomAnchor)
    }
    
    var readableIdentation: Embeddable {
        return CustomEmbeddable(view: self,
                                leadingAnchor: readableContentGuide.leadingAnchor,
                                trailingAnchor: trailingAnchor,
                                topAnchor: topAnchor,
                                bottomAnchor: bottomAnchor)
    }
}

extension UIView: Embeddable {
    var view: UIView? {
        return self
    }
}

extension UILayoutGuide: Embeddable {
    var view: UIView? {
        return owningView
    }
    
}

extension UIView {
    
    @discardableResult
    func embed(in embeddable: Embeddable, insets: UIEdgeInsets = .zero) -> Self {
        guard let view = embeddable.view else {
            print("Warning: could not embed view(\(self)) to embeddable(\(embeddable))")
            return self
        }
        
        view.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: embeddable.leadingAnchor, constant: insets.left).isActive = true
        trailingAnchor.constraint(equalTo: embeddable.trailingAnchor, constant: -insets.right).isActive = true
        topAnchor.constraint(equalTo: embeddable.topAnchor, constant: insets.top).isActive = true
        bottomAnchor.constraint(equalTo: embeddable.bottomAnchor, constant: -insets.bottom).isActive = true
        
        return self
    }
 
}

extension UIView {
    enum Side {
        case left
        case top
        case right
        case bottom
        
        var constrainedSides: [Side] {
            switch self {
            case .left:
                return [.left, .top, .bottom]
            case .top:
                return [.left, .top, .right]
            case .right:
                return [.top, .right, .bottom]
            case .bottom:
                return [.left, .right, .bottom]
            }
        }
    }
    
    @discardableResult
    func snap(to side: Side, of embeddable: Embeddable, width: CGFloat? = nil, height: CGFloat? = nil, insets: UIEdgeInsets = .zero) -> Self {
        guard let view = embeddable.view else {
            print("Warning: could not snap view(\(self)) to embeddable(\(embeddable))")
            return self
        }
        
        view.addSubview(self)
        
        let constrainedSides = side.constrainedSides
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: embeddable.leadingAnchor, constant: insets.left).isActive = constrainedSides.contains(.left)
        trailingAnchor.constraint(equalTo: embeddable.trailingAnchor, constant: -insets.right).isActive = constrainedSides.contains(.right)
        topAnchor.constraint(equalTo: embeddable.topAnchor, constant: insets.top).isActive = constrainedSides.contains(.top)
        bottomAnchor.constraint(equalTo: embeddable.bottomAnchor, constant: -insets.bottom).isActive = constrainedSides.contains(.bottom)
        
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        return self
    }
}

extension UIView {
    
    func withInsets(_ insets: UIEdgeInsets) -> UIView {
        let containingView = UIView(frame: .zero)
        embed(in: containingView, insets: insets)
        return containingView
    }
    
    func wrappedInReadableContentGuide(insets: UIEdgeInsets = .zero) -> UIView {
        let containingView = UIView(frame: .zero)
        containingView.preservesSuperviewLayoutMargins = true
        embed(in: containingView.readableContentGuide, insets: insets)
        return containingView
    }
    
}
