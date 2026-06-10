//
//  APIManager.swift
//


import UIKit
import UIKit
import SystemConfiguration

//MARK: - APIManager
let apiManager:APIManager = APIManager()

class APIManager: NSObject {
    
    //TODO: - get Api
    func callGetApi(url:String, perameter:[String:Any], dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){

//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//               
//        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))" ,"x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//
//       request(url, method: .get, parameters:perameter, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(UserDefaults.Main.string(forKey:.userToken))",
                    "Cache-Control": "no-cache",
                    "Pragma": "no-cache"
                ]
               request(url, method: .get, parameters:perameter, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
            }
        }
    }
    
    //TODO: - get Api
    func callGetApiWithoutToken(url:String, perameter:[String:Any], dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){

//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//
//        let header = ["Content-Type":"application/json"]
//
//        request(url, method: .get, parameters:perameter, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
//        
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = [
                    "Content-Type": "application/json",
                    "Cache-Control": "no-cache",
                    "Pragma": "no-cache"
                ]
 
                request(url, method: .get, parameters:perameter, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
                
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return

            }
        }
    }
    
    //TODO: - get Api
    func callGetNormalApi(url:String, perameter:[String:Any], dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){

//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//        var headers = HTTPHeaders()
//        headers = [:]
////        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]
//
////        Alamofire.request(url, method: .get, parameters:perameter, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
////            dataResponse(response,nil)
//           request(url, method: .get ,parameters: perameter,headers: headers)
//                .responseJSON { (response) in
//                    dataResponse(response,nil)
//        }
        
        
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                var headers = HTTPHeaders()
                headers = [
                    "Cache-Control": "no-cache",
                    "Pragma": "no-cache"
                ]
                request(url, method: .get ,parameters: perameter,headers: headers)
                    .responseJSON { (response) in
                        dataResponse(response,nil)
                    }
                
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
                
            }
        }
    }
    
    //TODO: - get with json encoding Api
    func callGetApiwithJson(url:String, perameter:[String:Any], dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){

//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//
//        var memberJson : String = ""
//        
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: perameter, options: .prettyPrinted)
//            let theJSONText = String(data: jsonData, encoding: .ascii)
//            memberJson = theJSONText!
//        } catch {
//            print(error.localizedDescription)
//        }
//
//        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//
//       request(url, method: .get, parameters:[:], encoding:memberJson, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                var memberJson : String = ""
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: perameter, options: .prettyPrinted)
                    let theJSONText = String(data: jsonData, encoding: .ascii)
                    memberJson = theJSONText!
                } catch {
                    print(error.localizedDescription)
                }

                let header = [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(UserDefaults.Main.string(forKey:.userToken))",
                    "Cache-Control": "no-cache",
                    "Pragma": "no-cache"
                ]

               request(url, method: .get, parameters:[:], encoding:memberJson, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
                
            }
        }
    }

    //TODO: - Post Api
    func callPostApi(url:String, perameter:[String:Any] , dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){
//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//        
//        request(url, method: .post, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]
                request(url, method: .post, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
                
            }
        }
    }
    
    //TODO: - Post Api
    func callPutMethodApi(url:String, perameter:[String:Any] , dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){
//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//        
//      request(url, method: .put, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]
              request(url, method: .put, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
                
            }
        }
    }
    
    //TODO: - Post Api
    func callDeleteMethodApi(url:String, perameter:[String:Any] , dataResponse:@escaping (DataResponse<Any>?, _ error:Error?)->()){
//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            dataResponse(nil,error)
//            return
//        }
//        let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//        
//        request(url, method: .delete, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
//            dataResponse(response,nil)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"application/json","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]
                request(url, method: .delete, parameters: perameter, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
                    dataResponse(response,nil)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                dataResponse(nil,error)
                return
                
            }
        }
        
    }

    //TODO: - Send Image Api
    func callSendMediaMethodApi(isImage : Bool,isVideo:Bool,url:String, imageThumbKey: String, parameter:[String:Any],imageData:Data,encodingResult:@escaping (SessionManager.MultipartFormDataEncodingResult)->()) {
//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            encodingResult(SessionManager.MultipartFormDataEncodingResult.failure(error))
//            return
//        }
////        var comrpessProfileData = Data()
////
////        if isImage
////        {
////            var compressProfileImage = UIImage()
////            compressProfileImage = imageMedia.resizedTo1MB()!
////            comrpessProfileData = compressProfileImage.jpegData(compressionQuality: 8.0)!
////        }
//        
//        let header = ["Content-Type":"multipart/form-data","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//
//        let manager = SessionManager.default
//        manager.session.configuration.timeoutIntervalForRequest = 9999
//        manager.session.configuration.timeoutIntervalForResource = 9999
//        
//        manager.upload(multipartFormData: { multipartFormData in
//            if isImage {
//                multipartFormData.append(imageData, withName: imageThumbKey, fileName: "image_\(NSDate().getTimeStemp()).jpeg", mimeType: "image/jpeg")
//            }
//            if isVideo {
//                var timeStamp = "\(NSDate().getTimeStemp())"
//                timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
//                multipartFormData.append(imageData, withName: imageThumbKey, fileName: "video_\(timeStamp).mp4", mimeType:"video/mp4")
//            }
//            
//            if !parameter.isEmpty{
//                for (key, value) in parameter {
//                    multipartFormData.append((String(describing: value) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
//                }
//            }
//        }, to: url, method: .post,headers: header) { response in
//            encodingResult(response)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"multipart/form-data","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]

                let manager = SessionManager.default
                manager.session.configuration.timeoutIntervalForRequest = 9999
                manager.session.configuration.timeoutIntervalForResource = 9999
                
                manager.upload(multipartFormData: { multipartFormData in
                    if isImage {
                        multipartFormData.append(imageData, withName: imageThumbKey, fileName: "image_\(NSDate().getTimeStemp()).jpeg", mimeType: "image/jpeg")
                    }
                    if isVideo {
                        var timeStamp = "\(NSDate().getTimeStemp())"
                        timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
                        multipartFormData.append(imageData, withName: imageThumbKey, fileName: "video_\(timeStamp).mp4", mimeType:"video/mp4")
                    }
                    
                    if !parameter.isEmpty{
                        for (key, value) in parameter {
                            multipartFormData.append((String(describing: value) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                        }
                    }
                }, to: url, method: .post,headers: header) { response in
                    encodingResult(response)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                encodingResult(SessionManager.MultipartFormDataEncodingResult.failure(error))
                return
            }
        }
    }
    //TODO: - Send Image Api
    func callSendMultipleImagesMedia(isImages : Bool,url:String, parameter:[String:Any], images:[Data],encodingResult:@escaping (SessionManager.MultipartFormDataEncodingResult)->()) {
//        if !isConnectedToNetwork() {
//            let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
//            encodingResult(SessionManager.MultipartFormDataEncodingResult.failure(error))
//            return
//        }
//
//        let header = ["Content-Type":"multipart/form-data","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))","x-api-key":AppState.sharedInstance.strApiKey ?? ""]
//
//        let manager = SessionManager.default
//        manager.session.configuration.timeoutIntervalForRequest = 999
//        manager.session.configuration.timeoutIntervalForResource = 999
//        
//        manager.upload(multipartFormData: { multipartFormData in
//            if isImages {
//                for (i,imgData) in images.enumerated()
//                {
//                    var timeStamp = "\(NSDate().getTimeStemp())"
//                    timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
//                    multipartFormData.append(imgData, withName: "pre_start_answer[\(i)]img_file", fileName: "image_\(timeStamp).jpeg", mimeType: "image/jpeg")
//                }
//            }
//            if !parameter.isEmpty{
//                for (key, value) in parameter {
//                    multipartFormData.append((String(describing: value) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
//                }
//            }
//        }, to: url, method: .post,headers: header) { response in
//            print(response)
//            encodingResult(response)
//        }
        
        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"multipart/form-data","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]

                let manager = SessionManager.default
                manager.session.configuration.timeoutIntervalForRequest = 999
                manager.session.configuration.timeoutIntervalForResource = 999
                
                manager.upload(multipartFormData: { multipartFormData in
                    if isImages {
                        for (i,imgData) in images.enumerated()
                        {
                            var timeStamp = "\(NSDate().getTimeStemp())"
                            timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
                            multipartFormData.append(imgData, withName: "pre_start_answer[\(i)]img_file", fileName: "image_\(timeStamp).jpeg", mimeType: "image/jpeg")
                        }
                    }
                    if !parameter.isEmpty{
                        for (key, value) in parameter {
                            multipartFormData.append((String(describing: value) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                        }
                    }
                }, to: url, method: .post,headers: header) { response in
                    encodingResult(response)
                }
                
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                encodingResult(SessionManager.MultipartFormDataEncodingResult.failure(error))
                return
            }
        }
    }
    
    //TODO: - Send Video/Image Api
    func callSendMultipleMedia(isImages : Bool,Videos : Bool,url:String, imageKey: String,videoKey: String, parameter:[String:Any], images:[Data],imagesThumbs:[Data],videos:[Data],videoUrl:[URL],encodingResult:@escaping (SessionManager.MultipartFormDataEncodingResult)->()) {

        isConnectedToNetwork1 { isConnected in
            if isConnected {
                let header = ["Content-Type":"multipart/form-data","Authorization":"Bearer \(UserDefaults.Main.string(forKey:.userToken))"]

                let manager = SessionManager.default
                manager.session.configuration.timeoutIntervalForRequest = 999
                manager.session.configuration.timeoutIntervalForResource = 999
        //        let sessionConfig = URLSessionConfiguration.default
        //        sessionConfig.timeoutIntervalForRequest = 30.0
        //        sessionConfig.timeoutIntervalForResource = 60.0
        //        let session = URLSession(configuration: sessionConfig)
                manager.upload(multipartFormData: { multipartFormData in
                    if isImages {
                        for imgData in images
                        {
                            var timeStamp = "\(NSDate().getTimeStemp())"
                            timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
                            multipartFormData.append(imgData, withName: imageKey, fileName: "image_\(timeStamp).jpeg", mimeType: "image/jpeg")
                        }
                    }
                    if videos.count > 0 {
                        for (index,videoData) in videos.enumerated()
                        {
                           // print("Uploading video with file")
                            var timeStamp = "\(NSDate().getTimeStemp())"
                            timeStamp = timeStamp.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
                            multipartFormData.append(videoData, withName: videoKey, fileName: "video_\(timeStamp)_\(index).mp4", mimeType:"video/mp4")
        //                    multipartFormData.append(videosUrl, withName: videoKey, fileName: "video_\(timeStamp)_\(index).mp4", mimeType: "video/mp4")
                            multipartFormData.append(imagesThumbs[index], withName:"cover", fileName: "video_\(timeStamp)_\(index).jpg", mimeType: "image/jpg")
                        }
                    }
                    if !parameter.isEmpty{
                        for (key, value) in parameter {
                            multipartFormData.append((String(describing: value) as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                        }
                    }
                }, to: url, method: .post,headers: header) { response in
                    encodingResult(response)
                }
            } else {
                let error = NSError(domain: "", code: 505, userInfo: [NSLocalizedDescriptionKey : "connection_lost"])
                encodingResult(SessionManager.MultipartFormDataEncodingResult.failure(error))
                return
            }
        }
        
    }
    func stopAllSessions() {
        let sessionManager = SessionManager.default
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }
}

//func getTimeStamp(date : Date) -> Double {
//    return date.timeIntervalSince1970
//}

//MARK: - Check internet connection event
func isConnectedToNetwork() -> Bool {
    
    
    var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
}


// MARK: - Check internet connection with real validation
func isConnectedToNetwork1(completion: @escaping (Bool) -> Void) {
    // 1️⃣ Basic reachability check
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            SCNetworkReachabilityCreateWithAddress(nil, $0)
        }
    }) else {
        completion(false)
        return
    }
    
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        completion(false)
        return
    }
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let hasNetwork = (isReachable && !needsConnection)
    
    guard hasNetwork else {
        completion(false)
        return
    }
    
    // 2️⃣ Validate actual internet by pinging Google lightweight endpoint
    var urlRequest = URLRequest(url: URL(string: "https://www.google.com/generate_204")!)
    urlRequest.timeoutInterval = 5  // Set timeout here
    
    request(urlRequest)
        .validate(statusCode: 200..<300)
        .response { response in
            if response.error == nil {
                completion(true)  // ✅ Internet available
            } else {
                completion(false) // ❌ Network connected but no internet
            }
        }
}

func getJsonStringFromDictionary(aParameters : [String : Any]) -> String?
{
    var  paramJsonString = ""
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: aParameters, options: .prettyPrinted)
        let theJSONText = String(data: jsonData, encoding: .utf8)
        paramJsonString = theJSONText!
    } catch {
        print(error.localizedDescription)
    }
    return paramJsonString
}

extension String: ParameterEncoding {
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.timeoutInterval = 999
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
}
