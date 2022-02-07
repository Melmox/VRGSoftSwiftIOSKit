//
//  SMKeyboardAvoiding.swift
//  VRGSoftSwiftIOSKit
//
//  Created by OLEKSANDR SEMENIUK on 8/10/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import UIKit

public protocol SMKeyboardAvoidingProtocol: AnyObject {
    
    var keyboardToolbar: SMKeyboardToolbar? {get set}
    var isShowsKeyboardToolbar: Bool {get set}

    func adjustOffset()
    func hideKeyBoard()
    
    func addObjectForKeyboard(_ aObjectForKeyboard: UIResponder)
    func removeObjectForKeyboard(_ aObjectForKeyboard: UIResponder)

    func addObjectsForKeyboard(_ aObjectsForKeyboard: [UIResponder])
    func removeObjectsForKeyboard(_ aObjectsForKeyboard: [UIResponder])

    func removeAllObjectsForKeyboard()
    
    func responderShouldReturn(_ aResponder: UIResponder)
}

public protocol SMKeyboardAvoiderProtocol: AnyObject {
    
    var keyboardAvoiding: SMKeyboardAvoidingProtocol? {get set}
}
