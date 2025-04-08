class UserModel {
  final String id;
  final String username;
  final String email;
  final String password;
  final int points;
  final String? avatar;
  final String? firstName;
  final String? lastName;
  final String? favoriteTeam;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.points,
    this.avatar,
    this.firstName,
    this.lastName,
    this.favoriteTeam,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: '',
      points: json['points'] ?? 0,
      avatar: json['avatar'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      favoriteTeam: json['favorite_team'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'points': points,
      'avatar': avatar,
      'first_name': firstName,
      'last_name': lastName,
      'favorite_team': favoriteTeam,
    };
  }
}
