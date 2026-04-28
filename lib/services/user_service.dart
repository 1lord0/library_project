import '../models/user_model.dart';
import 'db_service.dart';

class UserService {
  final DbService _db = DbService();

  Future<List<UserModel>> getAllUsers() async {
    final results = await _db.query('users', orderBy: 'created_at DESC');
    return results.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<bool> emailExists(String email) async {
    final results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<int> createUser(UserModel user) async {
    return _db.insert('users', user.toMap());
  }

  Future<int> deleteUser(int id) async {
    return _db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
