// Clase para almacenar información resumida de sanciones
class SanctionInfo {
  final int count;
  final int totalPoints;

  SanctionInfo({
    required this.count,
    required this.totalPoints,
  });

  factory SanctionInfo.fromJson(Map<String, dynamic> json) {
    return SanctionInfo(
      count: json['count'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
    );
  }
}

// Clase para representar una sanción completa
class Sanction {
  final int id;
  final int tournamentId;
  final int userId;
  final String username;
  final int points;
  final String reason;
  final bool applied;
  final String createdAt;
  final String? appliedBy;

  Sanction({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.username,
    required this.points,
    required this.reason,
    required this.applied,
    required this.createdAt,
    this.appliedBy,
  });

  factory Sanction.fromJson(Map<String, dynamic> json) {
    return Sanction(
      id: json['id'],
      tournamentId: json['tournament'] ?? json['tournament_id'],
      userId: json['user'] ?? json['user_id'],
      username: json['username'] ?? '',
      points: json['points'] ?? 0,
      reason: json['reason'] ?? '',
      applied: json['applied'] ?? true,
      createdAt: json['created_at'] ?? '',
      appliedBy: json['applied_by_username'],
    );
  }
}
