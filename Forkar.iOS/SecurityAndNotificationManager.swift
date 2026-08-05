import Foundation
import LocalAuthentication
import UserNotifications
internal import Combine

class SecurityAndNotificationManager: ObservableObject {
    static let shared = SecurityAndNotificationManager()
    
    @Published var isUnlocked: Bool = false
    @Published var authError: String? = nil
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Face ID / Touch ID Authentication
    func authenticateBiometrics(reason: String = "Autentícate para acceder a los chats privados de Forkar", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ||
           context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        self.authError = nil
                        completion(true)
                    } else {
                        self.isUnlocked = false
                        self.authError = evaluateError?.localizedDescription ?? "Autenticación fallida"
                        completion(false)
                    }
                }
            }
        } else {
            // Fallback si el dispositivo no tiene Face ID/Passcode habilitado en simulador
            DispatchQueue.main.async {
                self.isUnlocked = true
                completion(true)
            }
        }
    }
    
    // MARK: - Push Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permisos de notificaciones concedidos en Forkar.")
            }
        }
    }
    
    func sendLocalChatNotification(title: String, body: String, roomID: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["room_id": roomID]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let err = error {
                print("Error al enviar notificación local: \(err)")
            }
        }
    }
}
