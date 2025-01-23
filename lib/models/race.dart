class Race {
  final String season;
  final String round;
  final String name; // raceName
  final String date; // date
  final String circuit; // circuitName (de Circuit)

  Race({
    required this.season,
    required this.round,
    required this.name,
    required this.date,
    required this.circuit,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      season: json['season'].toString(),
      round: json['round'].toString(),
      name: json['name'] ?? json['raceName'] ?? 'N/A',
      date: json['date'] ?? 'N/A',
      circuit: json['circuit'] ?? 'N/A',
    );
  }
}
