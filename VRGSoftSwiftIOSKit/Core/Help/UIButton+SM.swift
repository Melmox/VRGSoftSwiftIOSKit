//
//  UIButton+SM.swift
//  VRGSoftSwiftIOSKit
//
//  Created by OLEKSANDR SEMENIUK on 8/21/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import UIKit

public extension SMWrapper where Base: UIButton {
    
    func setBackgroundColor(_ aColor: UIColor, for aState: UIControl.State) {
        
        base.setBackgroundImage(UIImage.sm.resizableImageWith(color: aColor), for: aState)
    }
}
