import 'sanction.dart';

class Tournament {
  final int id;
  final String name;
  final String inviteCode;
  final List<Participant> participants;
  final int userPosition;
  final int userPoints;
  final LastRace? lastRace;
  final String? invitationCode;
  final bool isCreator; // Indica si el usuario actual es el creador del torneo

  Tournament({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.participants,
    required this.userPosition,
    required this.userPoints,
    this.lastRace,
    this.invitationCode,
    this.isCreator = false,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      inviteCode: json['invite_code'] ?? json['inviteCode'] ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) => Participant.fromJson(p))
          .toList(),
      userPosition: json['user_position'] ?? json['participantCount'] ?? 1,
      userPoints: json['user_points'] ?? json['userPoints'] ?? 0,
      lastRace: json['last_race'] != null
          ? LastRace.fromJson(json['last_race'])
          : json['lastRace'] != null
              ? LastRace.fromJson(json['lastRace'])
              : null,
      invitationCode: json['invitation_code'] ?? json['inviteCode'],
      isCreator: json['is_creator'] ?? false,
    );
  }
}

class LastRace {
  final String name;
  final String date;
  final String? season;
  final String? round;

  LastRace({
    required this.name,
    required this.date,
    this.season,
    this.round,
  });

  factory LastRace.fromJson(Map<String, dynamic> json) {
    return LastRace(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      season: json['season']?.toString(),
      round: json['round']?.toString(),
    );
  }
}

class Participant {
  final int userId;
  final String username;
  final int points;
  final int? lastRacePoints;
  final String? avatar;
  final SanctionInfo? sanctions;

  Participant({
    required this.userId,
    required this.username,
    required this.points,
    this.lastRacePoints,
    this.avatar,
    this.sanctions,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id'],
      username: json['username'],
      points: json['points'],
      lastRacePoints: json['last_race_points'],
      avatar: json['avatar'],
      sanctions: json.containsKey('sanctions')
          ? SanctionInfo.fromJson(json['sanctions'])
          : null,
    );
  }
}

// Clase para representar la predicción de un usuario en una carrera específica
class RacePrediction {
  final int userId;
  final String username;
  final String? avatar;
  final bool hasPredicted;
  final Map<String, dynamic>? prediction;

  RacePrediction({
    required this.userId,
    required this.username,
    this.avatar,
    required this.hasPredicted,
    this.prediction,
  });

  factory RacePrediction.fromJson(Map<String, dynamic> json) {
    return RacePrediction(
      userId: json['user_id'],
      username: json['username'],
      avatar: json['avatar'],
      hasPredicted: json['has_predicted'] ?? false,
      prediction: json['prediction'],
    );
  }
}

// Clase para representar los detalles de una carrera en un torneo
class TournamentRace {
  final String name;
  final String circuit;
  final String date;
  final int season;
  final int round;
  final bool isCompleted;
  final List<RacePrediction> predictions;
  final Map<String, dynamic>? results;

  TournamentRace({
    required this.name,
    required this.circuit,
    required this.date,
    required this.season,
    required this.round,
    required this.isCompleted,
    required this.predictions,
    this.results,
  });

  factory TournamentRace.fromJson(Map<String, dynamic> json) {
    return TournamentRace(
      name: json['name'] ?? '',
      circuit: json['circuit'] ?? '',
      date: json['date'] ?? '',
      season: json['season'] ?? 0,
      round: json['round'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      predictions: (json['predictions'] as List? ?? [])
          .map((p) => RacePrediction.fromJson(p))
          .toList(),
      results: json['results'],
    );
  }
}
