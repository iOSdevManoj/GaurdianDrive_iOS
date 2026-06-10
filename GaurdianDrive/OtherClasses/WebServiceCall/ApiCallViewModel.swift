//
//  ApiCallViewModel.swift
//  INTIX Administrator
//
//  Created by Ahir ketan on 08/11/24.
//

import UIKit
import Toast_Swift

let apiCallViewModel:ApiCallViewModel = ApiCallViewModel()

class ApiCallViewModel: NSObject {
    
    //MARK: - Get Api call...
    func getApiCallWithDisctionaryResponse(aUrl:String,aParams:[String:Any],dataResponse:@escaping (_ isSuccess:Bool,_ responseDict:[String:Any])->()) {
        
        apiManager.callGetApi(url:aUrl, perameter: aParams) { (response,error) in
            
            if error != nil{
                APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: nil, response: nil, error: error)
                if aUrl != WebURL.baseURL + "settings" {
                    appDelegate.window?.rootViewController?.view.makeToast(kInternetDown)
                }
                dataResponse(false,[String:Any]())
                return
            }
            else  if response != nil{
                if response?.response?.statusCode != nil
                {
                    let statusCode = response!.response!.statusCode
                if statusCode == 401
                {
                    appDelegate.hideHud()
                    // appDelegate.logoutUser() // ✅ Removed forced logout
                }
                
                // ✅ Check if response contains a new token and update it
                if let dict = response?.result.value as? [String: Any],
                   let token = dict["token"] as? String, !token.isEmpty {
                    UserDefaults.Main.set(token, forKey: .userToken)
                    AppState.sharedInstance.strMyToken = token
                    print("🔄 Session token updated from GET response")
                }
                
                if statusCode == ApiResponseStatus.Success.rawValue
                    {
                        guard let value = response?.result.value else {
                            APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: statusCode, response: nil, error: nil)
                            dataResponse(false,[String:Any]())
                            return
                        }
                        if let dict = value as? [String: Any] {
                            APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: statusCode, response: dict)
                            dataResponse(true,dict)
                        }
                        else if let boolValue = value as? Bool {
                            APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: statusCode, response: ["result": boolValue])
                            dataResponse(true,[String:Any]())
                        }else{
                            appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                            dataResponse(false,[String:Any]())
                        }
                    }
                    else{
                        guard let value = response?.result.value else {
                            APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: statusCode, response: nil, error: nil)
                            dataResponse(false,[String:Any]())
                            return
                        }
                        
                        if let arryData = value as? [[String: Any]] {
                            APILogger.log(method: "GET", url: aUrl, params: aParams, statusCode: statusCode, responseArray: arryData)
                            if arryData.count > 0
                            {
                                dataResponse(false,arryData[0])
                            }else {
                                dataResponse(false,[String: Any]())
                            }
                        }else{
                            appDelegate.window?.rootViewController?.view.makeToast("No data found.Please try with another data.")
                            dataResponse(false,[String:Any]())
                        }
                    }
                }else
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                    dataResponse(false,[String:Any]())
                }
            }else{
                var statuscode = 00
                if response?.response?.statusCode != nil
                {
                    statuscode = (response?.response!.statusCode)!
                }
                appDelegate.window?.rootViewController!.popupAlert(title: "Error \(statuscode)", message:"Response nil", actionTitles: ["okay"], actions:[{action1 in
                },nil])
                dataResponse(false,[String:Any]())
            }
        }
    }
    
    func postApiCallWithDisctionaryResponse(aUrl:String,param:[String : Any],dataResponse:@escaping (_ isSuccess:Bool,_ responseDict:[String:Any],_ statusCode:Int)->()) {
        
        apiManager.callPostApi(url: aUrl, perameter: param) { (response,error) in
            
            if error != nil{
                APILogger.log(method: "POST", url: aUrl, params: param, statusCode: nil, response: nil, error: error)
                appDelegate.window?.rootViewController?.view.makeToast(kInternetDown)
                dataResponse(false,[String:Any](), 0)
                return
            }
            else  if response != nil{
                if response?.response?.statusCode != nil
                {
                    let statusCode = response!.response!.statusCode
                if statusCode == 401
                {
                    appDelegate.hideHud()
                    dataResponse(false,[String:Any](),ApiResponseStatus.ExpireAuth.rawValue)
//                     appDelegate.logoutUser() // ✅ Removed forced logout
                }
                
                // ✅ Check if response contains a new token and update it
                if let dict = response?.result.value as? [String: Any],
                   let token = dict["token"] as? String, !token.isEmpty {
                    UserDefaults.Main.set(token, forKey: .userToken)
                    AppState.sharedInstance.strMyToken = token
                    print("🔄 Session token updated from POST response")
                }
                
                if statusCode == ApiResponseStatus.Success.rawValue
                    {
                        guard let value = response?.result.value else {
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, response: nil, error: nil)
                            dataResponse(false,[String:Any](),ApiResponseStatus.Success.rawValue)
                            return
                        }
                        if let dict = value as? [String: Any] {
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, response: dict)
                            dataResponse(true,dict,ApiResponseStatus.Success.rawValue)
                        } else if let boolValue = value as? Bool {
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, response: ["result": boolValue])
                            dataResponse(true,[String:Any](),ApiResponseStatus.Success.rawValue)
                        }else{
                            appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                            dataResponse(false,[String:Any](),ApiResponseStatus.Success.rawValue)
                        }
                    }
                    else{
                        guard let value = response?.result.value else {
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, response: nil, error: nil)
                            dataResponse(false,[String:Any](),ApiResponseStatus.Error.rawValue)
                            return
                        }
                        if let arryData = value as? [[String: Any]] {
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, responseArray: arryData)
                            if arryData.count > 0
                            {
                                dataResponse(false,arryData[0],ApiResponseStatus.Error.rawValue)
                            }else {
                                dataResponse(false,[String: Any](),ApiResponseStatus.Error.rawValue)
                            }
                        } else if let dictData = value as? [String: Any] {
                            // Server returned a dict error body — pass it back so callers can read the real message
                            APILogger.log(method: "POST", url: aUrl, params: param, statusCode: statusCode, response: dictData)
                            dataResponse(false, dictData, statusCode)
                        } else {
                            appDelegate.window?.rootViewController?.view.makeToast("No data found.Please try with another data.")
                            dataResponse(false,[String:Any](), response!.response!.statusCode)
                        }
                    }
                }else
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                    dataResponse(false,[String:Any](), 0)
                }
            }else{
                appDelegate.window?.rootViewController?.view.makeToast("Something went wrong. Please try again later!")
                dataResponse(false,[String:Any](), 0)
            }
        }
    }
    
    func putMethodApiCallWithDisctionaryResponse(aUrl:String,param:[String : Any],dataResponse:@escaping (_ isSuccess:Bool,_ responseDict:[String:Any] )->()) {
        
        apiManager.callPutMethodApi(url: aUrl, perameter: param) { (response,error) in
            if error != nil{
                APILogger.log(method: "PUT", url: aUrl, params: param, statusCode: nil, response: nil, error: error)
                appDelegate.window?.rootViewController?.view.makeToast(kInternetDown)
                dataResponse(false,[String:Any]())
                return
            }
            else  if response != nil{
                if response?.response?.statusCode != nil
                {
                    let statusCode = response!.response!.statusCode
                    if statusCode == 401 || statusCode == 403
                    {
                        appDelegate.hideHud()
                        dataResponse(false,[String:Any]())
                    }
                    else if let dictResult = response?.result.value as? [String: Any]
                    {
                        let dictResponse = getDictionaryFromDictionary(dictionary: dictResult, key: "responseData")
                        //let strMessage = getStringFromDictionary(dictionary: dictResponse, key: "message")

                        if statusCode == ApiResponseStatus.Success.rawValue
                        {
                            APILogger.log(method: "PUT", url: aUrl, params: param, statusCode: statusCode, response: dictResult)
                            dataResponse(true, dictResult)
                        }
                        else
                        {
                            APILogger.log(method: "PUT", url: aUrl, params: param, statusCode: statusCode, response: dictResult)
                            dataResponse(false, dictResult)
                        }
                    }
                    else
                    {
                        // Fallback: If body parsing fails but we have a status code
                        APILogger.log(method: "PUT", url: aUrl, params: param, statusCode: statusCode, response: nil)
                        dataResponse(statusCode == ApiResponseStatus.Success.rawValue, [String: Any]())
                    }
                }
                else
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                    dataResponse(false,[String:Any]())
                }
            }else{
                appDelegate.window?.rootViewController?.view.makeToast("Something went wrong. Please try again later!")
                dataResponse(false,[String:Any]())
            }
        }
    }
    func deleteMethodApiCallWithDisctionaryResponse(aUrl:String,param:[String : Any],dataResponse:@escaping (_ isSuccess:Bool,_ responseDict:[String:Any] )->()) {
        
        apiManager.callDeleteMethodApi(url: aUrl, perameter: param) { (response,error) in
            if error != nil{
                APILogger.log(method: "DELETE", url: aUrl, params: param, statusCode: nil, response: nil, error: error)
                appDelegate.window?.rootViewController?.view.makeToast(kInternetDown)
                dataResponse(false,[String:Any]())
                return
            }
            else  if response != nil{
                if response?.response?.statusCode != nil
                {
                    let statusCode = response!.response!.statusCode
                if statusCode == 401 || statusCode == 403
                {
                    appDelegate.hideHud()
                    dataResponse(false,[String:Any]())
                    // appDelegate.logoutUser() // ✅ Removed forced logout
                }
                
                // ✅ Check if response contains a new token and update it
                if let dict = response?.result.value as? [String: Any],
                   let token = dict["token"] as? String, !token.isEmpty {
                    UserDefaults.Main.set(token, forKey: .userToken)
                    AppState.sharedInstance.strMyToken = token
                    print("🔄 Session token updated from DELETE response")
                }
                
                if let dictResult = response!.result.value as? [String:Any]
                    {
                        let dictResponse = getDictionaryFromDictionary(dictionary: dictResult, key:"responseData")
                        let strMessage = getStringFromDictionary(dictionary: dictResponse, key: "message")

                        if statusCode == ApiResponseStatus.Success.rawValue
                        {
                            APILogger.log(method: "DELETE", url: aUrl, params: param, statusCode: statusCode, response: dictResult)
                            dataResponse(true,dictResult)
                        }else{
                            APILogger.log(method: "DELETE", url: aUrl, params: param, statusCode: statusCode, response: dictResult)
                            appDelegate.window?.rootViewController?.view.makeToast(strMessage)
                            dataResponse(false,[String:Any]())
                        }
                    }
                    else {
                        APILogger.log(method: "DELETE", url: aUrl, params: param, statusCode: statusCode, response: nil)
                        dataResponse(false, [String: Any]())
                    }
                }
                else
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Server error!. Please try again later!")
                    dataResponse(false,[String:Any]())
                }
            }else{
                appDelegate.window?.rootViewController?.view.makeToast("Something went wrong. Please try again later!")
                dataResponse(false,[String:Any]())
            }
        }
    }
    
    func postMethodWithMultiPartCall(strUrl:String,param:[String : Any], mediaKey:String, isProfileAvail:Bool,isvideo:Bool, profileImageData:Data, dataResponse:@escaping (_ isSuccess:Bool,_ responseDict:[String:Any] )->()) {
        
        apiManager.callSendMediaMethodApi(isImage: isProfileAvail, isVideo: isvideo, url: strUrl, imageThumbKey: mediaKey, parameter: param, imageData: profileImageData) { (response) in
            switch response {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: {(Progress) in
                    print("Upload Progress: \(Progress.fractionCompleted)")
                })
                upload.responseJSON {  response in
                    if response.response?.statusCode == ApiResponseStatus.Success.rawValue {
                        if let dicResult:[String:Any] = response.result.value as! [String:Any]? {
                            let status = response.response!.statusCode
                            let strMessage = getStringFromDictionary(dictionary: dicResult, key: "message")

                            if status == ApiResponseStatus.Success.rawValue
                            {
                                //print(dicResult)
                                dataResponse(true,dicResult)
                            }else{
                                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
                                dataResponse(false,[String:Any]())
                            }
                        }else
                        {
                            appDelegate.window?.rootViewController?.view.makeToast("Response nil and Status code \(response.response!.statusCode)")
                            dataResponse(false,[String:Any]())
                        }
                    }else{
                        if let dicResult:[String:Any] = response.result.value as! [String:Any]? {
                            let strMessage = getStringFromDictionary(dictionary: dicResult, key: "message")
                            appDelegate.window?.rootViewController?.view.makeToast(strMessage)
                        }else{
                            appDelegate.window?.rootViewController?.view.makeToast("Response nil and Status code \(response.response?.statusCode ?? 100)")
                        }
                        dataResponse(false,[String:Any]())
                    }
                }
            case .failure( let error ):
                appDelegate.window?.rootViewController?.view.makeToast(error.localizedDescription)
                dataResponse(false,[String:Any]())
            }
        }
    }
    // MARK: - Upload Progress (Multipart)
    // Upload progress is intentionally not routed through APILogger since it is
    // incremental percentage data, not a JSON response.
}

// MARK: - APILogger
/// Single, centralized logger for all API traffic.
/// Every request and response in the app is logged here — nowhere else.
/// Output is structured JSON so it can be parsed, filtered, or exported easily.
enum APILogger {

    /// Log a completed API call.
    /// - Parameters:
    ///   - method: HTTP method string ("GET", "POST", "PUT", "DELETE").
    ///   - url: Full request URL string.
    ///   - params: Request parameters / body (optional, omitted when empty).
    ///   - statusCode: HTTP status code returned by the server (nil on network error).
    ///   - response: Parsed response body as a dictionary (for single-object responses).
    ///   - responseArray: Parsed response body as an array (for list responses).
    ///   - error: Network or serialization error (nil on success).
    static func log(
        method: String,
        url: String,
        params: [String: Any]? = nil,
        statusCode: Int?,
        response: [String: Any]? = nil,
        responseArray: [[String: Any]]? = nil,
        error: Error? = nil
    ) {
        // ✅ success = no error AND status is 2xx; everything else is ❌ failure
        let isSuccess = error == nil && (statusCode.map { (200...299).contains($0) } ?? false)
        let prefix = isSuccess ? "✅" : "❌"

        var logObject: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "method":    method,
            "url":       url,
        ]

        if let params = params, !params.isEmpty {
            logObject["request_params"] = params
        }

        if let code = statusCode {
            logObject["http_status"] = code
        }

        if let response = response {
            logObject["response"] = response
        } else if let responseArray = responseArray {
            logObject["response"] = responseArray
        }

        if let error = error {
            logObject["error"] = error.localizedDescription
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: logObject, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("\(prefix) [API] \(method) \(url) — (log serialization failed)")
            return
        }
        print("=======================\n\(prefix) [API LOG: \(url)]\n\(jsonString)\n=======================")
    }
}

func getStatusCodeAndMessage(dicResult : [String:Any]) ->(codeStatus:String,message:String)
{
    let dictData = getDictionaryFromDictionary(dictionary: dicResult, key: "result")
    let status = "200"
    let msg = createString(value: dictData["message"] as AnyObject)
    return(status,msg)
}

func setLoginUserData(dicResult : [String:Any],isFromProfile:Bool)
{
//    let dicResponseData:[String:Any] = getDictionaryFromDictionary(dictionary: dicResult, key: "responseData")
//    let dicResultData:[String:Any] = getDictionaryFromDictionary(dictionary: dicResponseData, key: "data")
    let userModelData = UserModel.init(dict: creatDic(value: dicResult as AnyObject))
    UserModel.setArchiveData(userModelData)
    AppState.sharedInstance.user = userModelData
    let userToken = createString(value: dicResult["token"] as AnyObject)
    if !userToken.isEmpty {
        UserDefaults.Main.set(userToken, forKey: .userToken)
        AppState.sharedInstance.strMyToken = userToken
        print("🔄 Session token updated in setLoginUserData")
    }
}
