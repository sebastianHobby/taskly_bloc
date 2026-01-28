/// Wipes all user data (except the auth account) through normal sync flow.
abstract interface class UserDataWipeService {
  /// Deletes all user-owned data via normal sync, then waits for upload.
  Future<void> wipeAllUserData({Duration timeout});
}
