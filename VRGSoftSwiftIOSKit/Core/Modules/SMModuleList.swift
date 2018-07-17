//
//  SMModuleList.swift
//  SwiftKit
//
//  Created by OLEKSANDR SEMENIUK on 2/2/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import UIKit

public typealias SMModuleListFetcherFailedCallback = (SMModuleList, SMResponse) -> Void
public typealias SMModuleListFetcherCantFetch = (SMModuleList, SMFetcherMessage) -> Void


public protocol SMModuleListDelegate: class
{
    func fetcherMessageFor(moduleList aModule: SMModuleList) -> SMFetcherMessage
    func willReload(moduleList aModule: SMModuleList)
    func moduleList(_ aModule: SMModuleList, processFetchedModelsInResponse aResponse: SMResponse) -> [AnyObject]
    func moduleList(_ aModule: SMModuleList, didReloadDataWithModels aModels: [AnyObject])
}

open class SMModuleList
{
    open var moduleQueue: DispatchQueue = DispatchQueue(label: "SMModuleList.Queue")
    open var lastUpdateDate: Date?
    open var models: [AnyObject] = []
    
    open var listAdapter: SMListAdapter
    
    open var isReloading: Bool = false
    {
        didSet
        {
            
        }
    }
    
    open var pullToRefreshAdapter: SMPullToRefreshAdapter?
    {
        didSet
        {
            pullToRefreshAdapter?.refreshCallback = { [weak self] (aPullToRefreshAdapter: SMPullToRefreshAdapter) in
                
                if let strongSelf = self
                {
                    if !strongSelf.isUseActivityAdapterWithPullToRefreshAdapter
                    {
                        strongSelf.isHideActivityAdapterForOneFetch = true
                    }
                    
                    strongSelf.reloadData()
                }
            }
        }
    }
    open var activityAdapter: SMActivityAdapter?
    open var isUseActivityAdapterWithPullToRefreshAdapter: Bool = false
    open var isHideActivityAdapterForOneFetch: Bool = false
    open var fetcherMessageClass: SMFetcherMessage.Type {get {return SMFetcherMessage.self}}
    open var fetcherFailedCallback: SMModuleListFetcherFailedCallback?
    open var fetcherCantFetchCallback: SMModuleListFetcherCantFetch?
    
    
    open weak var delegate: SMModuleListDelegate?
    
    open var dataFetcher: SMDataFetcherProtocol?
    {
        didSet
        {
            dataFetcher?.callbackQueue = moduleQueue
        }
    }
    
    required public init(listAdapter aListAdapter: SMListAdapter)
    {
        listAdapter = aListAdapter
    }
    
    open func reloadData()
    {
        if isReloading
        {
            return
        }
        
        isReloading = true
        models.removeAll()
        
        delegate?.willReload(moduleList: self)
        
        fetchDataWith(message: createFetcherMessage())
    }
    
    open func configureWith(scrollView aScrollView: UIScrollView)
    {
        pullToRefreshAdapter?.configureWith(scrollView: aScrollView)
//        activityAdapter?.configureWith(view: aScrollView)
    }

    open func processFetchedModelsIn(response aResponse: SMResponse) -> [AnyObject]
    {
        let result: [AnyObject] = delegate?.moduleList(self, processFetchedModelsInResponse: aResponse) ?? []
        return result
    }
    
    open func fetchDataWith(message aMessage: SMFetcherMessage)
    {
        if dataFetcher?.canFetchWith(message: aMessage) ?? false
        {
            dataFetcher?.cancelFetching()
            willFetchDataWith(message: aMessage)

            dataFetcher?.fetchDataBy(message: aMessage, withCallback: { [weak self] (aResponse: SMResponse) in
                DispatchQueue.main.sync {
                    
                    if aResponse.isSuccess
                    {
                        // TODO:
                        /*Preparation of sections changes their number and at that moment a function cellForItemAt: or cellForRowAt: can be called.
                          Reload disposer to update the data for the table/collection */
                        self?.prepareSections()
                        self?.listAdapter.reloadData()
                    }
                    
                    self?.didFetchDataWith(message: aMessage, response: aResponse)
                    
                    if aResponse.isSuccess, let aModels: [AnyObject] = (self?.processFetchedModelsIn(response: aResponse))
                    {
                        var numberOfPrepareSections: Int = 0
                        
                        if aModels.count != 0
                        {
                            var i: Int = 0
                            
                            while i < aModels.count
                            {
                                let obj: AnyObject = aModels[i]
                                
                                var ms: [AnyObject]
                                
                                if let obj = obj as? [AnyObject]
                                {
                                    ms = obj
                                } else
                                {
                                    var mutMs: [AnyObject] = []
                                    for j in (i..<aModels.count)
                                    {
                                        i = j
                                        
                                        if !(aModels[j] is [AnyObject])
                                        {
                                            mutMs.append(aModels[j])
                                        } else
                                        {
                                            i -= 1
                                            break
                                        }
                                    }
                                    
                                    ms = mutMs
                                }
                                self?.updateSectionWith(models: ms, sectionIndex: numberOfPrepareSections)
                                numberOfPrepareSections += 1
                                
                                i += 1
                            }
                        } else
                        {
                            self?.updateSectionWith(models: aModels, sectionIndex: numberOfPrepareSections)
                            numberOfPrepareSections += 1
                        }
                        
                        self?.listAdapter.reloadData()
                        
                        if let strongSelf = self
                        {
                            self?.delegate?.moduleList(strongSelf, didReloadDataWithModels: aModels)
                        }
                    } else
                    {
                        if !aResponse.isCancelled
                        {
                            if let strongSelf = self
                            {
                                self?.fetcherFailedCallback?(strongSelf, aResponse)
                            }
                        }
                    }
                }
            })
        } else
        {
            isReloading = false
            pullToRefreshAdapter?.endPullToRefresh()

            fetcherCantFetchCallback?(self, aMessage)
        }
    }
    
    open func createFetcherMessage() -> SMFetcherMessage
    {
        guard let message: SMFetcherMessage = delegate?.fetcherMessageFor(moduleList: self) else
        {
            return fetcherMessageClass.init()
        }

        return message
    }
    
    open func updateSectionWith(models aModels: [AnyObject], sectionIndex aSectionIndex: Int)
    {
        listAdapter.updateSectionWith(models: aModels, sectionIndex: aSectionIndex, needLoadMore: nil)
        models += aModels
    }
    
    open func prepareSections()
    {
        listAdapter.prepareSections()
    }

    open func willFetchDataWith(message aMessage: SMFetcherMessage)
    {
        if !isHideActivityAdapterForOneFetch
        {
            isHideActivityAdapterForOneFetch = false
            DispatchQueue.main.async {
                self.activityAdapter?.show()
            }
        }
    }
    
    open func didFetchDataWith(message aMessage: SMFetcherMessage, response aResponse: SMResponse)
    {
        isReloading = false
        activityAdapter?.hide()
        pullToRefreshAdapter?.endPullToRefresh()
    }
}
