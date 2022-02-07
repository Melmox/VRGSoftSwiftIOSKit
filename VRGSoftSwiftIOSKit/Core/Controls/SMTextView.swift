//
//  SMTextView.swift
//  VRGSoftSwiftIOSKit
//
//  Created by OLEKSANDR SEMENIUK on 12/22/16.
//  Copyright © 2016 VRG Soft. All rights reserved.
//

import UIKit

open class SMTextView: UITextView, SMKeyboardAvoiderProtocol, SMValidationProtocol, SMFilterProtocol {
    
    open weak var smdelegate: UITextViewDelegate?
    
    open var delegateHolder: SMTextViewDelegateHolder?
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        
        super.init(frame: frame, textContainer: textContainer)
        
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        setup()
    }
    
    open func setup() {
        
        delegateHolder = SMTextViewDelegateHolder(textView: self)
        self.delegate = delegateHolder
        
        placeholderTextView.frame = self.bounds
        placeholderTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholderTextView.backgroundColor = UIColor.clear
        placeholderTextView.font = self.font
        placeholderTextView.textColor = UIColor.gray
        placeholderTextView.isEditable = false
        placeholderTextView.isUserInteractionEnabled = false
        placeholderTextView.isHidden = self.text.count > 0
        placeholderTextView.textContainerInset = self.textContainerInset
        self.addSubview(placeholderTextView)
    }

    
    // MARK: - PlaceHolder
    
    open var placeholderTextView: UITextView = UITextView()

    open var placeholder: String? {

        get { return placeholderTextView.text }
        set {
            placeholderTextView.text = newValue
            placeholderTextView.isHidden = self.text.count > 0
        }
    }
    
    open var attributedPlaceholder: NSAttributedString {
        
        get { return self.attributedText }
        set {
            placeholderTextView.attributedText = newValue
            placeholderTextView.isHidden = self.text.count > 0
        }
    }
    
    open var placeholderColor: UIColor? {

        get { return self.placeholderTextView.textColor }
        set {
            placeholderTextView.textColor = newValue
        }
    }

    override open var textContainerInset: UIEdgeInsets {

        get { return super.textContainerInset }
        set {
            super.textContainerInset = newValue
            placeholderTextView.textContainerInset = newValue
        }
    }

    override open var textAlignment: NSTextAlignment {
        
        get { return super.textAlignment }
        set {
            super.textAlignment = newValue
            placeholderTextView.textAlignment = newValue
        }
    }

    open var isPlaceHolderHidden: Bool {
        
        get { return placeholderTextView.isHidden }
        set {
            placeholderTextView.isHidden = newValue
        }
    }
    
    override open var text: String! {

        get { return super.text }
        set {
            super.text = newValue
            placeholderTextView.isHidden = self.text.count > 0
        }
    }
    
    override open var font: UIFont? {

        get { return super.font }
        set {
            super.font = newValue
            placeholderTextView.font = newValue
        }
    }

    
    // MARK: - SMKeyboardAvoiderProtocol
    
    public weak var keyboardAvoiding: SMKeyboardAvoidingProtocol?
    
    
    // MARK: - SMFilterProtocol
    
    public var filteredText: String? { return self.text }
    
    open var filter: SMFilter?

    
    // MARK: - SMValidationProtocol
    
    public var validatableText: String? {
        
        get {
            return self.text
        }
        set {
            self.text = newValue
        }
    }
    
    public var validator: SMValidator? {
        
        didSet {
            validator?.validatableObject = self
        }
    }
    
    public func validate() -> Bool {
        
        return validator?.validate() ?? true
    }
}

open class SMTextViewDelegateHolder: NSObject, UITextViewDelegate {
    
    weak var holdedTextView: SMTextView?
    
    required public init(textView aTextView: SMTextView) {
        
        super.init()
        
        holdedTextView = aTextView
    }
    
    
    // MARK: - UITextViewDelegate
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        return holdedTextView?.smdelegate?.textViewShouldBeginEditing?(_:textView) ?? true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        return holdedTextView?.smdelegate?.textViewShouldEndEditing?(_:textView) ?? true
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        
        holdedTextView?.keyboardAvoiding?.adjustOffset()

        holdedTextView?.smdelegate?.textViewDidBeginEditing?(_:textView)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        
        holdedTextView?.smdelegate?.textViewDidEndEditing?(_:textView)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        var result: Bool = true
        
        if let inputField: SMTextView = textView as? SMTextView {
            
            result = inputField.filter?.inputField(inputField, shouldChangeTextIn: range, replacementText: text) ?? result
        }
        
        if holdedTextView != nil && holdedTextView?.smdelegate != nil && holdedTextView?.smdelegate?.textView(_:shouldChangeTextIn:replacementText:) != nil {
            
            result = holdedTextView?.smdelegate?.textView?(_: textView, shouldChangeTextIn: range, replacementText: text) ?? result
        }
        
        if result {
            
            let newText: String = (textView.text as NSString?)?.replacingCharacters(in: range, with: text) ?? ""

            (textView as? SMTextView)?.isPlaceHolderHidden = newText.count > 0
        }

        return result
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        
        holdedTextView?.smdelegate?.textViewDidChange?(_:textView)
    }
}
