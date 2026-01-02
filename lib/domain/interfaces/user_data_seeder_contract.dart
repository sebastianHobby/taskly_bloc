/// Contract for user data seeding service.
///
/// Ensures system labels and screens are created with proper user context.
/// Implementations must be idempotent - safe to call multiple times.
abstract class UserDataSeederContract {
  /// Seeds all required user data.
  ///
  /// This method is idempotent and safe to call multiple times.
  /// It will only create missing data.
  ///
  /// Must be called after user authentication. PowerSync/Supabase
  /// automatically set user_id on created records based on the session.
  ///
  /// [userId] is required for screen seeding (used for deterministic UUID
  /// generation).
  Future<void> seedAll(String userId);
}
