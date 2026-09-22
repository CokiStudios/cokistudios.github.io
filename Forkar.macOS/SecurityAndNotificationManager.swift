import Foundation
import LocalAuthentication
import UserNotifications
internal import Combine

// ══════════════════════════════════════════════════════════════════
// 🔐 SECURITY & NOTIFICATIONS MANAGER — FORKAR PC (macOS)
// Soporte para Touch ID / Contraseña de Mac y Notificaciones de CSMS
// ══════════════════════════════════════════════════════════════════

class SecurityAndNotificationManager: ObservableObject {
    static let shared = SecurityAndNotificationManager()
    
    @Published var isUnlocked: Bool = false
    @Published var authError: String? = nil
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Touch ID / Contraseña de Mac
    func authenticateBiometrics(reason: String = "Autentícate para acceder a Forkar PC y chats de CSMS", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ||
           context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evaluateError in
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
            // Fallback si la máquina no tiene Touch ID configurado
            DispatchQueue.main.async {
                self.isUnlocked = true
                completion(true)
            }
        }
    }
    
    // MARK: - Notificaciones Nativas de macOS
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permisos de notificaciones concedidos en Forkar for PC.")
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
                print("Error al enviar notificación local en macOS: \(err)")
            }
        }
    }
}
