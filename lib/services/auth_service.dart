import 'package:flutter/foundation.dart';
import 'db_service.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final DbService _db = DbService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<UserModel?> login(String email, String password) async {
    final results = await _db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isEmpty) return null;

    _currentUser = UserModel.fromMap(results.first);
    notifyListeners();
    return _currentUser;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
