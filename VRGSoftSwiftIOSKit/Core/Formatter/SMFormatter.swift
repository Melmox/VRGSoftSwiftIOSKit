//
//  SMFormatter.swift
//  Contractors
//
//  Created by OLEKSANDR SEMENIUK on 1/19/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import Foundation

protocol SMFormatterProtocol : AnyObject
{
    var formatter: SMFormatter? { get set }
    var formattingText: String? { get set }
}

open class SMFormatter
{
    weak open var formattableObject: SMFormatterProtocol?
    
    func formattedTextFrom(originalString aOriginalString: String?) -> String?
    {
        return aOriginalString
    }
    
    func formatWithNewCharactersIn(range aRange: NSRange, replacementString aString: String) -> Bool
    {
        return true
    }
    
    func rawText() -> String?
    {
        return nil
    }
}
