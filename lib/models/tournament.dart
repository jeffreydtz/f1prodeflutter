class Tournament {
  final int id;
  final String name;
  final String inviteCode;
  final List<Participant> participants;
  final int userPosition;
  final int userPoints;
  final LastRace? lastRace;

  Tournament({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.participants,
    required this.userPosition,
    required this.userPoints,
    this.lastRace,
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
      userPoints: json['userPoints'] ?? 0,
      lastRace:
          json['lastRace'] != null ? LastRace.fromJson(json['lastRace']) : null,
    );
  }
}

class LastRace {
  final String name;
  final String date;

  LastRace({
    required this.name,
    required this.date,
  });

  factory LastRace.fromJson(Map<String, dynamic> json) {
    return LastRace(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class Participant {
  final int userId;
  final String username;
  final int points;
  final int? lastRacePoints;

  Participant({
    required this.userId,
    required this.username,
    required this.points,
    this.lastRacePoints,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id'],
      username: json['username'],
      points: json['points'],
      lastRacePoints: json['last_race_points'],
    );
  }
}
