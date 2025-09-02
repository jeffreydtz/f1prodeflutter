class UserModel {
  final String id;
  final String username;
  final String email;
  final int points;
  final int racesPlayed;
  final int polesGuessed;
  final String? avatar;
  final String? firstName;
  final String? lastName;
  final String? favoriteTeam;
  final DateTime? joinedAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
    this.racesPlayed = 0,
    this.polesGuessed = 0,
    this.avatar,
    this.firstName,
    this.lastName,
    this.favoriteTeam,
    this.joinedAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      points: json['points'] ?? json['total_points'] ?? 0,
      racesPlayed: json['races_played'] ?? 0,
      polesGuessed: json['poles_guessed'] ?? 0,
      avatar: json['avatar'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      favoriteTeam: json['favorite_team'],
      joinedAt: json['joined_at'] != null 
          ? DateTime.tryParse(json['joined_at']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'points': points,
      'races_played': racesPlayed,
      'poles_guessed': polesGuessed,
      'avatar': avatar,
      'first_name': firstName,
      'last_name': lastName,
      'favorite_team': favoriteTeam,
      'joined_at': joinedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    int? points,
    int? racesPlayed,
    int? polesGuessed,
    String? avatar,
    String? firstName,
    String? lastName,
    String? favoriteTeam,
    DateTime? joinedAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      points: points ?? this.points,
      racesPlayed: racesPlayed ?? this.racesPlayed,
      polesGuessed: polesGuessed ?? this.polesGuessed,
      avatar: avatar ?? this.avatar,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      favoriteTeam: favoriteTeam ?? this.favoriteTeam,
      joinedAt: joinedAt ?? this.joinedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
