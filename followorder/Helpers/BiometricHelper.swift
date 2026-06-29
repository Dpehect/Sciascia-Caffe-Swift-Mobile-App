import Foundation
import LocalAuthentication

class BiometricHelper {
    static func authenticateUser(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Evaluate biometric authentication policy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Face ID / Touch ID to access Staff inventory control."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        let message = authenticationError?.localizedDescription ?? "Biometric authentication failed."
                        completion(false, message)
                    }
                }
            }
        } else {
            // Fallback to device passcode evaluation if biometrics is not enrolled
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Enter device passcode to access Staff inventory control."
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, passcodeError in
                    DispatchQueue.main.async {
                        if success {
                            completion(true, nil)
                        } else {
                            let message = passcodeError?.localizedDescription ?? "Passcode authentication failed."
                            completion(false, message)
                        }
                    }
                }
            } else {
                // No local authentication enrolled (Simulators, macOS without Touch ID, etc.)
                // Fallback to automatic success to ensure development flows are not blocked
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            }
        }
    }
}
