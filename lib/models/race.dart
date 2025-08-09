class Race {
  final String season;
  final String round;
  final String name; // raceName
  final String date; // date
  final String? time; // time from API
  final String circuit; // circuitName (de Circuit)
  final String? location; // location from API
  final bool hasSprint; // Nuevo campo
  final bool completed; // Indica si la carrera ya pasó
  final bool hasBet;

  Race({
    required this.season,
    required this.round,
    required this.name,
    required this.date,
    this.time,
    required this.circuit,
    this.location,
    required this.hasSprint, // Nuevo campo
    this.completed = false, // Por defecto, no está completada
    this.hasBet = false,
  });

  Race copyWith({
    String? season,
    String? round,
    String? name,
    String? date,
    String? time,
    String? circuit,
    String? location,
    bool? hasSprint,
    bool? completed,
    bool? hasBet,
  }) {
    return Race(
      season: season ?? this.season,
      round: round ?? this.round,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      circuit: circuit ?? this.circuit,
      location: location ?? this.location,
      hasSprint: hasSprint ?? this.hasSprint,
      completed: completed ?? this.completed,
      hasBet: hasBet ?? this.hasBet,
    );
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    // Asegurar que hasBet sea siempre un booleano
    bool hasBet = false;
    if (json['has_bet'] != null) {
      // Manejar diferentes tipos de datos que podrían venir del backend
      if (json['has_bet'] is bool) {
        hasBet = json['has_bet'];
      } else if (json['has_bet'] is String) {
        hasBet = json['has_bet'].toString().toLowerCase() == 'true';
      } else if (json['has_bet'] is num) {
        hasBet = json['has_bet'] != 0;
      }
    }

    return Race(
      season: json['season'].toString(),
      round: json['round'].toString(),
      name: json['name'] ?? json['raceName'] ?? 'N/A',
      date: json['date'] ?? 'N/A',
      time: json['time'],
      circuit: json['circuit'] ?? 'N/A',
      location: json['location'],
      hasSprint: json['has_sprint'] ?? false,
      completed: json['completed'] ?? false,
      hasBet: hasBet,
    );
  }
}
