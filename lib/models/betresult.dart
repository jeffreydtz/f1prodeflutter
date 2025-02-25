class BetResult {
  final String raceName;
  final String date;
  final String circuit;
  final bool hasSprint;
  final String season;
  final String round;
  final bool isComplete;

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
    required this.circuit,
    required this.hasSprint,
    required this.season,
    required this.round,
    required this.isComplete,
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

    final bet = json['bet'] as Map<String, dynamic>? ?? {};
    final results = json['results'] as Map<String, dynamic>?;
    final comparison = results?['comparison'] as Map<String, dynamic>?;
    final pointsData = results?['points'] as Map<String, dynamic>?;

    return BetResult(
      raceName: bet['race_name']?.toString() ?? '',
      date: bet['date']?.toString() ?? '',
      circuit: bet['circuit']?.toString() ?? '',
      hasSprint: bet['has_sprint'] as bool? ?? false,
      season: bet['season']?.toString() ?? '',
      round: bet['round']?.toString() ?? '',
      isComplete: bet['is_complete'] as bool? ?? false,
      polemanUser: bet['poleman']?.toString() ?? '',
      polemanReal: comparison?['poleman_real']?.toString(),
      top10User: parseStringList(bet['top10']),
      top10Real: comparison?['top10_real'] != null
          ? parseStringList(comparison['top10_real'])
          : null,
      dnfUser: bet['dnf']?.toString() ?? '',
      dnfReal: comparison?['dnf_real']?.toString(),
      fastestLapUser: bet['fastest_lap']?.toString() ?? '',
      fastestLapReal: comparison?['fastest_lap_real']?.toString(),
      sprintTop10User: bet['sprint_top10'] != null
          ? parseStringList(bet['sprint_top10'])
          : null,
      sprintTop10Real: comparison?['sprint_top10_real'] != null
          ? parseStringList(comparison['sprint_top10_real'])
          : null,
      points: (pointsData?['total'] ?? bet['points'] ?? 0) as int,
      pointsBreakdown: pointsData?['breakdown'] != null
          ? parseStringList(pointsData['breakdown'])
          : [],
    );
  }
}
