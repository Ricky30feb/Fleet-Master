import Foundation
import Supabase

/// Custom error type for Supabase operations
enum SupabaseError: Error, LocalizedError {
    case noSession
    case userNotFound
    case invalidCredentials
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session found"
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Manager class for all Supabase operations
final class SupabaseManager {
    /// Shared instance (singleton)
    static let shared = SupabaseManager()
    
    /// Supabase client instance
    let supabase: SupabaseClient
    
    /// Private initializer for singleton
    private init() {
        // Initialize Supabase client
        supabase = SupabaseClient(
            supabaseURL: URL(string: "https://wqgyynzvuvsxqnvnibim.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZ3l5bnp2dXZzeHFudm5pYmltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0NDk1NDIsImV4cCI6MjA1ODAyNTU0Mn0.riECKe0wkDYW5th2L1glPq6IOfQ76NIrK67A-2hrDZM",
            options: SupabaseClientOptions(
                auth: .init(
                    flowType: .pkce,
                    autoRefreshToken: true
                )
            )
        )
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Session object if signin is successful
    /// - Throws: Authentication errors
    func signIn(email: String, password: String) async throws -> Session {
        do {
            return try await supabase.auth.signIn(email: email, password: password)
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Session object if signup is successful
    /// - Throws: Authentication errors
//    func signUp(email: String, password: String) async throws -> Session {
//        do {
//            return try await supabase.auth.signUp(email: email, password: password)
//        } catch {
//            throw mapAuthError(error)
//        }
//    }
    
    /// Sign out the current user
    /// - Throws: Authentication errors
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Send One-Time Password (OTP) for email authentication
    /// - Parameter email: User's email address
    /// - Throws: Authentication errors
    func sendOTP(email: String) async throws {
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Verify One-Time Password (OTP) for email authentication
    /// - Parameters:
    ///   - email: User's email address
    ///   - token: OTP token received via email
    /// - Returns: AuthResponse object if verification is successful
    /// - Throws: Authentication errors
    func verifyOTP(email: String, token: String) async throws -> AuthResponse {
        do {
            return try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Get the current session
    /// - Returns: Session object if available, nil otherwise
    /// - Throws: Authentication errors
    func getSession() async throws -> Session? {
        do {
            return try await supabase.auth.session
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Get the current user
    /// - Returns: User object if available, nil otherwise
    /// - Throws: Authentication errors
    func getCurrentUser() async throws -> User? {
        do {
            let session = try await supabase.auth.session
            return session.user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Reset password for the provided email
    /// - Parameter email: User's email address
    /// - Throws: Authentication errors
    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Update password for the current user
    /// - Parameters:
    ///   - password: New password
    ///   - completion: Optional completion handler called after successful password update
    /// - Throws: Authentication errors
    func updatePassword(password: String, completion: (() -> Void)? = nil) async throws {
        do {
            let attributes = UserAttributes(password: password)
            try await supabase.auth.update(user: attributes)
            completion?()
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Update password and navigate to dashboard
    /// - Parameters:
    ///   - password: New password
    ///   - navigateToDashboard: Closure that handles navigation to dashboard
    /// - Throws: Authentication errors
    func updatePasswordAndNavigate(password: String, navigateToDashboard: @escaping () -> Void) async throws {
        do {
            let attributes = UserAttributes(password: password)
            try await supabase.auth.update(user: attributes)
            // Password update successful, trigger navigation
            navigateToDashboard()
        } catch {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Map Supabase SDK errors to custom SupabaseError type
    /// - Parameter error: Original error from Supabase SDK
    /// - Returns: Mapped SupabaseError
    private func mapAuthError(_ error: Error) -> Error {
        // Check if error is an AuthError
            // Use string-based error handling as a fallback
            let errorString = String(describing: error)
            
            if errorString.contains("Invalid credentials") {
                return SupabaseError.invalidCredentials
            } else if errorString.contains("User not found") || errorString.contains("404") {
                return SupabaseError.userNotFound
            } else if errorString.contains("Missing session") || errorString.contains("No session") {
                return SupabaseError.noSession
            }
            
            return error
        }
        
        // Return the original error if not an AuthError
        //return SupabaseError.networkError(error)
    }
