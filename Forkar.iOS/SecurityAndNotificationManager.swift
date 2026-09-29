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
    
    // MARK: - Biometry Properties (Adaptive for iOS & macOS)
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    var biometryName: String {
        #if os(macOS)
        return "Touch ID"
        #else
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Touch ID / Contraseña"
        }
        #endif
    }
    
    var biometryIcon: String {
        #if os(macOS)
        return "touchid"
        #else
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.open.fill"
        }
        #endif
    }
    
    // MARK: - Face ID / Touch ID Authentication
    func authenticateBiometrics(reason: String = "Autentícate para acceder a los chats privados de Forkar", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        #if os(macOS)
        let policy: LAPolicy = .deviceOwnerAuthentication
        #else
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        #endif
        
        if context.canEvaluatePolicy(policy, error: &error) {
            context.evaluatePolicy(policy, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        self.authError = nil
                        completion(true)
                    } else {
                        self.isUnlocked = false
                        self.authError = evaluateError?.localizedDescription ?? "Autenticación cancelada o fallida"
                        completion(false)
                    }
                }
            }
        } else {
            // Fallback si el dispositivo no tiene Face ID/Touch ID ni Passcode
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
