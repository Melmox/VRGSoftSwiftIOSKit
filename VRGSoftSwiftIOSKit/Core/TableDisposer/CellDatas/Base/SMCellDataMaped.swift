//
//  SMCellDataMaped.swift
//  Contractors
//
//  Created by OLEKSANDR SEMENIUK on 01/31/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import UIKit

open class SMCellDataMaped: SMCellData
{
    var key : String?
    var object : AnyObject?
    
    required init(object aObject:AnyObject?, key aKey:String?)
    {
        super.init()
        object = aObject
        key = aKey
    }
    
    
    // MARK: Mapping
    
    func mapFromObject() -> Void
    {
        assert(false, "Override this method in subclasses!")
    }

    func mapToObject() -> Void
    {
        assert(false, "Override this method in subclasses!")
    }
}
