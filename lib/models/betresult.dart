class BetResult {
  final String raceName;
  final String date;
  final String polemanUser;
  final String polemanReal;
  final List<String> top10User;
  final List<String> top10Real;
  final List<String> dnfUser;
  final List<String> dnfReal;
  final int points;
  final List<String> pointsBreakdown;

  BetResult({
    required this.raceName,
    required this.date,
    required this.polemanUser,
    required this.polemanReal,
    required this.top10User,
    required this.top10Real,
    required this.dnfUser,
    required this.dnfReal,
    required this.points,
    required this.pointsBreakdown,
  });

  factory BetResult.fromJson(Map<String, dynamic> json) {
    return BetResult(
      raceName: json['raceName'],
      date: json['date'],
      polemanUser: json['polemanUser'],
      polemanReal: json['polemanReal'],
      top10User: List<String>.from(json['top10User']),
      top10Real: List<String>.from(json['top10Real']),
      dnfUser: List<String>.from(json['dnfUser']),
      dnfReal: List<String>.from(json['dnfReal']),
      points: json['points'],
      pointsBreakdown: List<String>.from(json['pointsBreakdown']),
    );
  }
}
