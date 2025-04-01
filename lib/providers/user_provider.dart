import 'package:flutter/foundation.dart';

class User {
  final String name;
  final String email;
  final String? profilePicture;
  final List<String> interests;

  User({
    required this.name,
    required this.email,
    this.profilePicture,
    this.interests = const [],
  });
}

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
} 