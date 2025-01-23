class Tournament {
  final int id;
  final String name;
  final String inviteCode;
  final List<Participant> participants;
  final int userPosition;
  final int userPoints;

  Tournament({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.participants,
    required this.userPosition,
    required this.userPoints,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      inviteCode: json['inviteCode'],
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      userPosition: json['participantCount'] ?? 1,
      userPoints: 0,
    );
  }
}

class Participant {
  final int userId;
  final String username;
  final int points;

  Participant({
    required this.userId,
    required this.username,
    required this.points,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id'],
      username: json['username'],
      points: json['points'],
    );
  }
}
