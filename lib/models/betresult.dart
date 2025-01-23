class BetResult {
  final String raceName;
  final String date;
  final bool isComplete;
  final String polemanUser;
  final String? polemanReal;
  final List<String> top10User;
  final List<String>? top10Real;
  final List<String> dnfUser;
  final List<String>? dnfReal;
  final int? points;
  final List<String> pointsBreakdown;

  BetResult({
    required this.raceName,
    required this.date,
    required this.isComplete,
    required this.polemanUser,
    this.polemanReal,
    required this.top10User,
    this.top10Real,
    required this.dnfUser,
    this.dnfReal,
    this.points,
    required this.pointsBreakdown,
  });

  factory BetResult.fromJson(Map<String, dynamic> json) {
    final raceData = json['race'] as Map<String, dynamic>;
    final betData = json['bet'] as Map<String, dynamic>;
    final pointsData = json['points'] as Map<String, dynamic>;

    return BetResult(
      raceName: raceData['name'] ?? '',
      date: raceData['date'] ?? '',
      isComplete: false,
      polemanUser: betData['poleman_user'] ?? '',
      polemanReal: betData['poleman_real'] ?? '',
      top10User: List<String>.from(betData['top10_user'] ?? []),
      top10Real: betData['top10_real'] != null
          ? List<String>.from(betData['top10_real'])
          : null,
      dnfUser: betData['dnf_user'] != null ? [betData['dnf_user']] : [],
      dnfReal: betData['dnf_real'] != null ? [betData['dnf_real']] : null,
      points: pointsData['total'] ?? 0,
      pointsBreakdown: List<String>.from(pointsData['breakdown'] ?? []),
    );
  }
}
