import '../entities/user.dart';
import '../requests/update_profile_request.dart';

abstract interface class ProfileRepository {
  Future<User> getProfile();
  Future<User> updateProfile(UpdateProfileRequest request);
}
