import Foundation
import Supabase

// If Supabase Swift is not installed:
// Xcode -> File -> Add Package Dependencies
// https://github.com/supabase/supabase-swift
// Use the latest stable version.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://ztcdgtmbwfsatpeipvcd.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0Y2RndG1id2ZzYXRwZWlwdmNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3MjMzMzYsImV4cCI6MjA5NzI5OTMzNn0.a3cJ536UlEq_bWjZwG2a3npzq8jCeiTgokp1I9Iv4U0"
        )
    }
}
