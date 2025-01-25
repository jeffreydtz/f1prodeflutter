class BetResult {
  final String raceName;
  final String date;
  final String circuit;
  final bool hasSprint;
  bool isComplete;

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
    this.isComplete = false,
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
    final raceData = json['race'] as Map<String, dynamic>;
    final betData = json['bet'] as Map<String, dynamic>;
    final pointsData = json['points'] as Map<String, dynamic>;

    return BetResult(
      raceName: raceData['name'] ?? '',
      date: raceData['date'] ?? '',
      circuit: raceData['circuit'] ?? '',
      hasSprint: raceData['has_sprint'] ?? false,
      isComplete: true,
      polemanUser: betData['poleman_user'] ?? '',
      polemanReal: betData['poleman_real'],
      top10User: List<String>.from(betData['top10_user'] ?? []),
      top10Real: betData['top10_real'] != null
          ? List<String>.from(betData['top10_real'])
          : null,
      dnfUser: betData['dnf_user'] ?? '',
      dnfReal: betData['dnf_real'],
      fastestLapUser: betData['fastest_lap_user'] ?? '',
      fastestLapReal: betData['fastest_lap_real'],
      sprintTop10User: betData['sprint_top10_user'] != null
          ? List<String>.from(betData['sprint_top10_user'])
          : null,
      sprintTop10Real: betData['sprint_top10_real'] != null
          ? List<String>.from(betData['sprint_top10_real'])
          : null,
      points: pointsData['total'] ?? 0,
      pointsBreakdown: List<String>.from(pointsData['breakdown'] ?? []),
    );
  }
}
