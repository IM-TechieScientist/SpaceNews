class UserProfile {
  final String username;
  final List<String> interests;

  UserProfile({
    required this.username,
    required this.interests,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'interests': interests,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      interests: List<String>.from(json['interests'] as List),
    );
  }
} 