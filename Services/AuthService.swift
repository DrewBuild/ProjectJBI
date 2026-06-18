import Foundation
import Supabase

enum AuthServiceError: LocalizedError {
    case usernameTaken
    case usernameTooSimilar
    case invalidEmail
    case emailAlreadyRegistered
    case emailNotConfirmed
    case invalidLogin
    case signupStartFailed
    case emailResendFailed
    case usernameUnavailable
    case missingSupabaseSession
    case signupFailed
    case message(String)

    var errorDescription: String? {
        switch self {
        case .usernameTaken:
            return "That username is already taken."
        case .usernameTooSimilar:
            return "That username is too similar to another one."
        case .invalidEmail:
            return "Please enter a valid email."
        case .emailAlreadyRegistered:
            return "Looks like you already have an account. Log in instead."
        case .emailNotConfirmed:
            return "Please confirm your email first."
        case .invalidLogin:
            return "Email or password is incorrect."
        case .signupStartFailed:
            return "We could not create your account. Try again."
        case .emailResendFailed:
            return "Something went wrong. Try again."
        case .usernameUnavailable:
            return "That username is no longer available."
        case .missingSupabaseSession:
            return "Something went wrong. Try again."
        case .signupFailed:
            return "Something went wrong. Try again."
        case .message(let message):
            return message
        }
    }
}

final class AuthService {
    private let client = SupabaseManager.shared.client

    func checkUsernameAvailability(username: String) async throws -> UsernameAvailabilityResponse {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Keep public.check_username_available aligned with app rules:
        // regex ^[a-z0-9._]{3,20}$, must include [a-z], no leading/trailing . or _, and no .., __, ._, or _.
        let response: [UsernameAvailabilityResponse] = try await client
            .rpc("check_username_available", params: ["input_username": normalized])
            .execute()
            .value

        return response.first ?? UsernameAvailabilityResponse(
            available: false,
            reason: "Something went wrong. Try again."
        )
    }

    func startSignup(email: String, password: String) async throws {
        try await signUpAndSendVerification(email: email, password: password)
    }

    func signUpAndSendVerification(email: String, password: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("Starting signup")
        // Custom SMTP is not configured, so Supabase sends the default confirmation-link email.
        do {
            _ = try await client.auth.signUp(email: normalizedEmail, password: password)
            print("Signup requested; confirmation email should be sent")
        } catch {
            print("startSignup failed:", error)
            if isExistingEmailError(error) {
                throw AuthServiceError.emailAlreadyRegistered
            }
            throw AuthServiceError.signupStartFailed
        }
    }

    func signIn(email: String, password: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        do {
            _ = try await client.auth.signIn(email: normalizedEmail, password: password)
        } catch {
            print("signIn failed:", error)
            let errorText = String(describing: error).lowercased()
            if errorText.contains("confirm") || errorText.contains("not verified") || errorText.contains("not confirmed") {
                throw AuthServiceError.emailNotConfirmed
            }
            throw AuthServiceError.invalidLogin
        }
    }

    func sendPasswordReset(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        do {
            try await client.auth.resetPasswordForEmail(normalizedEmail)
        } catch {
            print("sendPasswordReset failed:", error)
            throw AuthServiceError.message("Something went wrong. Try again.")
        }
    }

    func resendConfirmation(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        do {
            try await client.auth.resend(email: normalizedEmail, type: .signup)
        } catch {
            print("resendConfirmation failed:", error)
            throw AuthServiceError.emailResendFailed
        }
    }

    func completeProfileForCurrentSession(
        firstName: String,
        lastName: String,
        username: String,
        email: String
    ) async throws {
        let session = try await client.auth.session
        print("Current user id: \(session.user.id)")
        try await ensureProfileExists(
            userId: session.user.id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: email
        )
        print("Signup complete")
    }

    func hasAuthenticatedSession() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            print("No authenticated session:", error)
            return false
        }
    }

    func saveProfileAfterVerification(
        email: String,
        firstName: String,
        lastName: String,
        username: String
    ) async throws {
        let session = try await client.auth.session
        try await ensureProfileExists(
            userId: session.user.id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: email
        )
    }

    func ensureProfileExists(
        userId: UUID,
        firstName: String,
        lastName: String,
        username: String,
        email: String
    ) async throws {
        do {
            let existingProfiles: [ProfileInsert] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if !existingProfiles.isEmpty {
                print("Profile already exists")
                return
            }
        } catch {
            print("profile existence check failed:", error)
        }

        try await insertProfileAfterVerified(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: email
        )
    }

    func insertProfileAfterVerified(
        userId: UUID,
        firstName: String,
        lastName: String,
        username: String,
        email: String
    ) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            print("Inserting profile")

            let profile = ProfileInsert(
                id: userId,
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                username: normalizedUsername,
                email: normalizedEmail,
                bio: ""
            )

            try await client
                .from("profiles")
                .insert(profile)
                .execute()
            print("Profile inserted")
        } catch let error as AuthServiceError {
            print("saveProfileAfterVerification failed:", error)
            throw error
        } catch {
            print("saveProfileAfterVerification failed:", error)
            if isDuplicateProfileError(error), (try? await client.auth.session) != nil {
                if isUsernameConflictError(error) {
                    throw AuthServiceError.usernameUnavailable
                }
                return
            }
            throw AuthServiceError.signupFailed
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func hasCurrentSession() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    private func isExistingEmailError(_ error: Error) -> Bool {
        let errorText = String(describing: error).lowercased()
        return errorText.contains("already registered") ||
            errorText.contains("already exists") ||
            errorText.contains("user already") ||
            (errorText.contains("email") && (errorText.contains("already") || errorText.contains("exists") || errorText.contains("registered")))
    }

    private func isDuplicateProfileError(_ error: Error) -> Bool {
        let errorText = String(describing: error).lowercased()
        return errorText.contains("duplicate") ||
            errorText.contains("already exists") ||
            errorText.contains("23505")
    }

    private func isUsernameConflictError(_ error: Error) -> Bool {
        String(describing: error).lowercased().contains("username")
    }
}
