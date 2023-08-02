//
//  SMGatewayRequest.swift
//  VRGSoftSwiftIOSKit
//
//  Created by OLEKSANDR SEMENIUK on 1/4/17.
//  Copyright © 2017 VRG Soft. All rights reserved.
//

import Foundation
import Alamofire

public typealias SMGatewayRequestResponseBlock = (DataRequest, DataResponse<Any, AFError>) -> SMResponse

public typealias SMRequestParserBlock = (SMResponse) -> Void
public typealias SMGatewayRequestSuccessParserBlock = (DataRequest, DataResponse<Any, AFError>, @escaping SMRequestParserBlock) -> Void

open class SMGatewayRequest: SMRequest {
    
    public var debugDescription: String {
        
        var array: [String] = []
        
        array.append("URL - " + (dataRequest?.request?.url?.absoluteString ?? (fullPath?.absoluteString) ?? "???"))
        array.append("TYPE - " + type.rawValue)
        array.append("HEADERS - " + (dataRequest?.request?.headers.description ?? allHeaders.description))
        array.append("PARAMS - " + allParams.description)
        
        return  array.joined(separator: "\n")
    }
    
    open unowned var gateway: SMGateway
    open var dataRequest: DataRequest?
    
    open var retryCount: Int = 0
    open var retryTime: TimeInterval = 0.5
    
    open var path: String?
    open var type: HTTPMethod
    open var parameterEncoding: ParameterEncoding?
    
    open var parameters: [String: Any] = [:]
    open var headers: [String: String] = [:]
    
    open var successBlock: SMGatewayRequestResponseBlock?
    open var successParserBlock: SMGatewayRequestSuccessParserBlock?
    open var failureBlock: SMGatewayRequestResponseBlock?
    
    var allParams: [String: Any] {
        
        var result: [String: Any] = [:]
        
        for (key, value): (String, Any) in (gateway.defaultParameters) {
            
            result.updateValue(value, forKey: key)
        }
        
        for (key, value): (String, Any) in (parameters) {
            
            result.updateValue(value, forKey: key)
        }
        
        return result
    }
    
    var allHeaders: HTTPHeaders {
        
        var result: [String: String] = [:]
        
        for (key, value): (String, String) in (gateway.defaultHeaders) {
            
            result.updateValue(value, forKey: key)
        }
        
        for (key, value): (String, String) in (headers) {
            
            result.updateValue(value, forKey: key)
        }
        
        return HTTPHeaders(result)
    }
    
    var fullPath: URL? {
        
        var result: URL? = gateway.baseUrl
        
        if let path: String = path {
            
            result = result?.appendingPathComponent(path)
        }
        
        return result
    }
    
    
    public required init(gateway aGateway: SMGateway, type aType: HTTPMethod) {
        
        gateway = aGateway
        self.type = aType
    }
    
    @discardableResult
    override open func start() -> Self {
        
        super.start()
        
        gateway.start(request: self)
        
        return self
    }
    
    override open func cancel() {
        
        dataRequest?.cancel()
    }
    
    override open func canExecute() -> Bool {
        
        return gateway.isInternetReachable()
    }
    
    override open func isCancelled() -> Bool {
        
        return dataRequest?.task?.state == URLSessionTask.State.canceling
    }
    
    override open func isExecuting() -> Bool {
        
        return dataRequest?.task?.state == URLSessionTask.State.running
    }
    
    override open func isFinished() -> Bool {
        
        return dataRequest?.task?.state == URLSessionTask.State.completed
    }
    
    open func getDataRequest() -> DataRequest? {
        
        guard let fullPath: URL = fullPath else { return nil }

        if parameterEncoding == nil {
            switch type {
            case .options, .head, .get, .delete:
                parameterEncoding = URLEncoding.default
            case .patch, .post, .put:
                parameterEncoding = JSONEncoding.default
            default: break
            }
        }
        
        if let parameterEncoding: ParameterEncoding = parameterEncoding {
            
            let dataRequest: DataRequest = AF.request(fullPath,
                                                      method: type,
                                                      parameters: allParams,
                                                      encoding: parameterEncoding,
                                                      headers: allHeaders,
                                                      interceptor: SMGatewayConfigurator.shared.interceptor)

            self.dataRequest = dataRequest

            SMGatewayConfigurator.shared.interceptor.addRetryInfo(gatewayRequest: self)

            dataRequest.responseJSON(queue: queue) { [weak self] responseObject in

                guard let self = self else {
                    return
                }

                switch responseObject.result {
                case .success:
                    
                    if self.gateway.requestConsoleOutputType != .none {
                        print("✅ SUCCESS", self.type.rawValue, self.path ?? "???", String(format: "%.2f", responseObject.metrics?.taskInterval.duration ?? 0), "s")
                    }
                    
                    SMGatewayConfigurator.shared.interceptor.deleteRetryInfo(gatewayRequest: self)

                    let callBack: SMRequestParserBlock = { (aResponse: SMResponse) in
                        if self.executeAllResponseBlocksSync {
                            self.executeSynchronouslyAllResponseBlocks(response: aResponse)
                        } else {
                            self.executeAllResponseBlocks(response: aResponse)
                        }
                    }

                    if let successParserBlock: SMGatewayRequestSuccessParserBlock = self.successParserBlock,
                       let dataRequest: DataRequest = self.dataRequest {

                        successParserBlock(dataRequest, responseObject, callBack)
                    } else {

                        if let dataRequest: DataRequest = self.dataRequest,
                           let response: SMResponse = self.successBlock?(dataRequest, responseObject) {

                            callBack(response)
                        }
                    }
                case .failure(let error):
                    print("🛑 ERROR", self.type.rawValue, self.path ?? "???", error)
                    self.executeFailureBlock(responseObject: responseObject)
                }
            }

            return dataRequest
        } else {
            return nil
        }
    }
    
    open func executeSuccessBlock(responseObject aResponseObject: DataResponse<Any, AFError>) {
        
        if let successBlock: SMGatewayRequestResponseBlock = successBlock,
           let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = successBlock(dataRequest, aResponseObject)
            
            if executeAllResponseBlocksSync {
                
                executeSynchronouslyAllResponseBlocks(response: response)
            } else {
                
                executeAllResponseBlocks(response: response)
            }
        }
    }
    
    open func executeFailureBlock(responseObject aResponseObject: DataResponse<Any, AFError>) {
        
        if let failureBlock: SMGatewayRequestResponseBlock = failureBlock,
           let dataRequest: DataRequest = dataRequest {
            
            let response: SMResponse = failureBlock(dataRequest, aResponseObject)
            
            if executeAllResponseBlocksSync {
                
                executeSynchronouslyAllResponseBlocks(response: response)
            } else {
                
                executeAllResponseBlocks(response: response)
            }
        }
    }
    
    open func setup(successBlock aSuccessBlock: @escaping SMGatewayRequestResponseBlock, failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successBlock = aSuccessBlock
        failureBlock = aFailureBlock
    }
    
    open func setup(successParserBlock aSuccessParserBlock: @escaping SMGatewayRequestSuccessParserBlock, failureBlock aFailureBlock: @escaping SMGatewayRequestResponseBlock) {
        
        successParserBlock = aSuccessParserBlock
        failureBlock = aFailureBlock
    }
    
    open func printStart(isRetry: Bool) {
        let message: String = isRetry ? "🔁 RETRY" : "➡️ START"
        switch gateway.requestConsoleOutputType {
        case .none:
            break
        case .simply:
            print(message, type.rawValue, path ?? "???")
        case .debugDescription:
            print("\(message)\n\(debugDescription)\n")
        case .cURL:
            dataRequest?.cURLDescription { curl in
                print("\(message)\n\(curl)\n")
            }
        }
    }
}
