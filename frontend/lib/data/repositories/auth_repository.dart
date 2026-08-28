import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final token = response['token'];
    final user = UserModel.fromJson(response['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, token);
    await prefs.setString(AppConstants.keyUserRole, user.role);
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.fullName);

    return {'user': user, 'token': token};
  }

  Future<Map<String, dynamic>> loginWithFirebaseToken(String idToken, {String? fullName, String? fcmToken}) async {
    final response = await _client.post('/auth/firebase-login', data: {
      'id_token': idToken,
      if (fullName != null) 'full_name': fullName,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });

    final token = response['token'];
    final user = UserModel.fromJson(response['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, token);
    await prefs.setString(AppConstants.keyUserRole, user.role);
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.fullName);

    return {'user': user, 'token': token};
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get('/auth/profile');
    return UserModel.fromJson(response);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    return token != null && token.isNotEmpty;
  }
}
