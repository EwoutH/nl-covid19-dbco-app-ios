/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class TextField: UITextField {
    
    override var placeholder: String? {
        didSet {
            label.text = placeholder
        }
    }
    
    init(label: String) {
        super.init(frame: .zero)
        setup()
        
        placeholder = label
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundView.backgroundColor = Theme.colors.tertiary
        backgroundView.layer.cornerRadius = 8
        backgroundView.isUserInteractionEnabled = false
        
        addSubview(label)
        addSubview(backgroundView)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func borderRect(forBounds bounds: CGRect) -> CGRect {
        return backgroundView.frame.inset(by: .leftRight(12))
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .bottom(self.bounds.height - backgroundView.frame.height))
    }
    
    override var intrinsicContentSize: CGSize {
        let labelHeight = label.intrinsicContentSize.height
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        return CGSize(width: 375, height: labelHeight + Constants.spacing + backgroundHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelSize = label.intrinsicContentSize
        let backgroundHeight = baseFieldHeight + Constants.backgroundBaseHeight
        
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: labelSize.height)
        backgroundView.frame = CGRect(x: 0, y: bounds.height - backgroundHeight, width: bounds.width, height: backgroundHeight)
    }
    
    // MARK: - Private
    
    private struct Constants {
        static let spacing: CGFloat = 8
        static let backgroundBaseHeight: CGFloat = 26
    }
    
    private var baseFieldHeight: CGFloat {
        return ceil(font!.lineHeight + 1)
    }
    
    private var label = UILabel()
    private var backgroundView = UIView()
    
}
