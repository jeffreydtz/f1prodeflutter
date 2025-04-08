class BetResult {
  final String raceName;
  final String date;
  final String? circuit;
  final bool hasSprint;
  final String season;
  final String round;
  final bool isComplete;
  final String userId;

  // Main Race
  final String polemanUser;
  final String? polemanReal;
  final List<String> top10User;
  final List<String>? top10Real;
  final String dnfUser;
  final String? dnfReal;
  final String fastestLapUser;
  final String? fastestLapReal;

  // Sprint Race
  final List<String>? sprintTop10User;
  final List<String>? sprintTop10Real;

  // Points
  final int points;
  final List<String> pointsBreakdown;

  BetResult({
    required this.raceName,
    required this.date,
    this.circuit,
    required this.hasSprint,
    required this.season,
    required this.round,
    required this.isComplete,
    required this.userId,
    required this.polemanUser,
    this.polemanReal,
    required this.top10User,
    this.top10Real,
    required this.dnfUser,
    this.dnfReal,
    required this.fastestLapUser,
    this.fastestLapReal,
    this.sprintTop10User,
    this.sprintTop10Real,
    required this.points,
    required this.pointsBreakdown,
  });

  factory BetResult.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item?.toString() ?? '').toList();
      }
      return [];
    }

    final race = json['race'] as Map<String, dynamic>? ?? {};
    final bet = json['bet'] as Map<String, dynamic>? ?? {};
    final pointsData = json['points'] as Map<String, dynamic>? ?? {};

    // Verificar si hay resultados reales para determinar si la carrera está completa
    bool isComplete = false;

    // Verificar de múltiples maneras si la predicción está completada
    // 1. Verificar si hay resultados reales
    final hasRealResults = bet['poleman_real'] != null ||
        (bet['top10_real'] != null && (bet['top10_real'] as List).isNotEmpty) ||
        bet['dnf_real'] != null ||
        bet['fastest_lap_real'] != null;

    // 2. Verificar si el campo isComplete está directamente en el JSON
    if (json.containsKey('is_complete')) {
      isComplete = json['is_complete'] as bool? ?? false;
    } else if (bet.containsKey('is_complete')) {
      isComplete = bet['is_complete'] as bool? ?? false;
    } else if (race.containsKey('completed')) {
      isComplete = race['completed'] as bool? ?? false;
    } else {
      // Usar la presencia de resultados reales como ultimo recurso
      isComplete = hasRealResults;
    }

    // Garantizar que season y round sean strings
    String season = '';
    String round = '';

    // Intentar extraer season y round, ya sea del objeto race o directamente del json
    if (race.containsKey('season')) {
      season = race['season'].toString();
    } else if (json.containsKey('season')) {
      season = json['season'].toString();
    }

    if (race.containsKey('round')) {
      round = race['round'].toString();
    } else if (json.containsKey('round')) {
      round = json['round'].toString();
    }

    return BetResult(
      raceName: race['name']?.toString() ?? '',
      date: race['date']?.toString() ?? '',
      circuit: race['circuit']?.toString(),
      hasSprint: race['has_sprint'] as bool? ?? false,
      season: season,
      round: round,
      isComplete: isComplete,
      userId: bet['user_id']?.toString() ?? '',
      polemanUser: bet['poleman_user']?.toString() ?? '',
      polemanReal: bet['poleman_real']?.toString(),
      top10User: parseStringList(bet['top10_user']),
      top10Real:
          bet['top10_real'] != null ? parseStringList(bet['top10_real']) : null,
      dnfUser: bet['dnf_user']?.toString() ?? '',
      dnfReal: bet['dnf_real']?.toString(),
      fastestLapUser: bet['fastest_lap_user']?.toString() ?? '',
      fastestLapReal: bet['fastest_lap_real']?.toString(),
      sprintTop10User: bet['sprint_top10_user'] != null
          ? parseStringList(bet['sprint_top10_user'])
          : null,
      sprintTop10Real: bet['sprint_top10_real'] != null
          ? parseStringList(bet['sprint_top10_real'])
          : null,
      points: (pointsData['total'] ?? 0) as int,
      pointsBreakdown: pointsData['breakdown'] != null
          ? parseStringList(pointsData['breakdown'])
          : [],
    );
  }
}
