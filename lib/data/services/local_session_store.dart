import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dtos/auth_session_dto.dart';

class LocalSessionStore {
  LocalSessionStore(this._preferences);

  static const _sessionKey = 'auth_session';

  final SharedPreferences _preferences;

  Future<void> saveSession(AuthSessionDto session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSessionDto?> readSession() async {
    final payload = _preferences.getString(_sessionKey);
    if (payload == null) {
      return null;
    }

    return AuthSessionDto.fromJson(jsonDecode(payload) as Map<String, dynamic>);
  }

  Future<void> clearSession() => _preferences.remove(_sessionKey);
}
