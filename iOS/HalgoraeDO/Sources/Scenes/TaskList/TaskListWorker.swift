//
//  TaskListWorker.swift
//  HalgoraeDO
//
//  Created by woong on 2020/11/23.
//

import Foundation

class TaskListWorker {
    
    let networkManager: NetworkDispatcher
    
    init(sessionManager: SessionManagerProtocol) {
        networkManager = NetworkManager(sessionManager: sessionManager)
    }
    
    func request<T: Decodable>(endPoint: ProjectEndPoint, completion: @escaping ((T?) -> Void)) {
        networkManager.fetchData(endPoint) { (result: ResponseProject<T>?, error: NetworkError?) in
            guard error == nil else {
                #if DEBUG
                print(error ?? "error is null")
                #endif
                completion(nil)
                return
            }
            completion(result?.project)
        }
    }
    
    func requestPostAndGet<T: Decodable>(post postEndPoint: EndPointType, get getEndPoint: EndPointType, completion: @escaping (T?) -> Void) {
        networkManager.fetchData(postEndPoint) { [weak self] (response: ResponseMessage?, error) in
            guard error == nil else {
                #if DEBUG
                print("response msg: \(String(describing: response))")
                print(error ?? "error is null")
                #endif
                completion(nil)
                return
            }
            self?.networkManager.fetchData(getEndPoint) { (result: T?, error) in
                completion(result)
            }
        }
    }
    
    //TODO : requestPostAndGet(위) 지우고 하단의 함수와 합쳐 다른 requestPostAndGet함수로 개선 예정
    func requestPostAndGetTask<T: Decodable>(post postEndPoint: EndPointType, endPoint: ProjectEndPoint, completion: @escaping (T?) -> Void) {
        networkManager.fetchData(postEndPoint) { [weak self] (response: ResponseMessage?, error) in
    
            guard error == nil else {
                #if DEBUG
                print("response msg: \(String(describing: response))")
                print(error ?? "error is null")
                #endif
                completion(nil)
                return
            }
            self?.networkManager.fetchData(endPoint) { (result: ResponseProject<T>?, error: NetworkError?) in
                guard error == nil else {
                    #if DEBUG
                    print(error ?? "error is null")
                    #endif
                    completion(nil)
                    return
                }
                completion(result?.project)
            }
        }
    }
    
    func requestPostAndGetTemp<T: Decodable>(post postEndPoint: EndPointType, endPoint: ProjectEndPoint, completion: @escaping (T?) -> Void) {
        networkManager.fetchData(postEndPoint) { [weak self] (response: ResponseMessage?, error) in
            guard error == nil else {
                #if DEBUG
                print("response msg: \(String(describing: response))")
                print(error ?? "error is null")
                #endif
                completion(nil)
                return
            }
            self?.networkManager.fetchData(endPoint) { (result: ResponseProject<T>?, error: NetworkError?) in
                guard error == nil else {
                    #if DEBUG
                    print(error ?? "error is null")
                    #endif
                    completion(nil)
                    return
                }
                completion(result?.project)
            }
        }
    }
    
    // func fetchTasks(End)
    
    func changeFinish(task: Task, postion: Int, parentPosition: Int?) {
        
    }
}
