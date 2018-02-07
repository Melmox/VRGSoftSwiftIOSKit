//
//  SMFetcherWithBlock.swift
//  Contractors
//
//  Created by OLEKSANDR SEMENIUK on 3/23/17.
//  Copyright © 2017 Contractors.com. All rights reserved.
//

import UIKit

typealias SMDataFetchBlock = (SMFetcherMessage, @escaping SMDataFetchCallback) -> Void


open class SMFetcherWithBlock: SMDataFetcherProtocol
{
    // MARK: SMDataFetcherProtocol
    
    public var callbackQueue: DispatchQueue?
    
    let fetchBlock: SMDataFetchBlock
    
    
    init(fetchBlock aFetchBlock: @escaping SMDataFetchBlock)
    {
        self.fetchBlock = aFetchBlock
    }
    
    public func canFetchWith(message aMessage: SMFetcherMessage) -> Bool
    {
        return true
    }
    
    public func fetchDataBy(message aMessage: SMFetcherMessage, withCallback aFetchCallback: @escaping SMDataFetchCallback) -> Void
    {
        self.callbackQueue?.async
        {
            self.fetchBlock(aMessage, aFetchCallback)
        }
    }
    
    public func cancelFetching() -> Void
    {
        
    }
}
