//
//  GuardianSocketManager.swift
//  GaurdianDrive
//
//  Created by KETAN on 19/02/26.
//

import UIKit
import Foundation

class GuardianSocketManager: NSObject {
    static let shared = GuardianSocketManager()
     
//     private let socketURL = "wss://www.api.guardian-drive.dharechainfotech.com/web-socket/location"
     
     private var webSocketTask: URLSessionWebSocketTask?
     private var session: URLSession!
//     private var token: String = ""
     private(set) var isConnected = false
     
     var onConnect: (() -> Void)?
     var onDisconnect: ((Error?) -> Void)?
     var onMessage: ((String) -> Void)?
     
     // Reconnection logic and flags
     private var reconnectTimer: Timer?
     private var isIntentionallyDisconnected = false
     
     private override init() {
         super.init()
         session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
     }
     
     func connect() {
         guard FeatureFlag.isSocketFeatureEnabled else {
             print("🛑 [Socket] Connect aborted — Socket feature is DISABLED by feature flag.")
             return
         }
         
         isIntentionallyDisconnected = false
         reconnectTimer?.invalidate()
         reconnectTimer = nil
         
         guard let url = URL(string: WebURL.socketUrl) else { return }
         
         var request = URLRequest(url: url)
         request.setValue("Bearer \(UserDefaults.Main.string(forKey:.userToken))", forHTTPHeaderField: "Authorization")
         
         // Prevent duplicate connections if already running
         if webSocketTask?.state == .running { return }
         
         webSocketTask = session.webSocketTask(with: request)
         webSocketTask?.resume()
         isConnected = true
         receive()
     }
     
     func disconnect() {
         isIntentionallyDisconnected = true
         reconnectTimer?.invalidate()
         reconnectTimer = nil
         
         isConnected = false
         webSocketTask?.cancel(with: .goingAway, reason: nil)
         webSocketTask = nil
         onDisconnect?(nil)
     }
     
     private func scheduleReconnect() {
         guard !isIntentionallyDisconnected else { return }
         
         isConnected = false
         webSocketTask = nil
         reconnectTimer?.invalidate()
         
         // Try to reconnect in 3 seconds
         DispatchQueue.main.async { [weak self] in
             self?.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                 print("🔄 [Socket] Attempting to reconnect...")
                 self?.connect()
             }
         }
     }
     
     func sendLocation(latitude: Double, longitude: Double, speed: Double, driveMode: String) {
         guard FeatureFlag.isSocketFeatureEnabled, isConnected else { return }
         
         let json: [String: Any] = [
             "latitude": latitude,
             "longitude": longitude,
             "speed": speed,
             "driveMode": driveMode
         ]
         
         guard let data = try? JSONSerialization.data(withJSONObject: json),
               let text = String(data: data, encoding: .utf8) else { return }
         
         let message = URLSessionWebSocketTask.Message.string(text)
         webSocketTask?.send(message) { error in
             if let error = error {
                 print("Send error:", error)
             }
         }
     }
     
     private func receive() {
         webSocketTask?.receive { [weak self] result in
             guard let self = self, self.isConnected else { return }
             
             switch result {
             case .failure(let error):
                 print("⚠️ [Socket] Receive failed:", error.localizedDescription)
                 self.onDisconnect?(error)
                 self.scheduleReconnect()
                 
             case .success(let message):
                 switch message {
                 case .string(let text):
                     self.onMessage?(text)
                 case .data(let data):
                     let text = String(data: data, encoding: .utf8) ?? ""
                     self.onMessage?(text)
                 @unknown default:
                     break
                 }
                 self.receive()
             }
         }
     }
 }

 extension GuardianSocketManager: URLSessionWebSocketDelegate {
     
     func urlSession(_ session: URLSession,
                     webSocketTask: URLSessionWebSocketTask,
                     didOpenWithProtocol protocol: String?) {
         onConnect?()
     }
     
     func urlSession(_ session: URLSession,
                     webSocketTask: URLSessionWebSocketTask,
                     didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                     reason: Data?) {
         print("🔌 [Socket] Connection closed with code: \(closeCode)")
         onDisconnect?(nil)
         scheduleReconnect()
     }
 }
