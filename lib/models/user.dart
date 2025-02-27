class UserModel {
  final String id;
  final String email;
  final String username;
  final String password;
  int points;
  String? avatar;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    this.points = 0,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: '', // El backend no envía el password
      points: json['points'] ?? 0,
      avatar: json['avatar'],
    );
  }
}
