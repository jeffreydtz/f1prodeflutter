class UserModel {
  final String id;
  final String email;
  final String username;
  final String password;
  int points;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    this.points = 0,
  });
}
