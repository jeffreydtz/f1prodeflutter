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
      season: json['season'],
      round: json['round'],
      name: json['raceName'],
      date: json['date'],
      // Tomar circuit name de la subclave 'Circuit'
      circuit: json['Circuit']?['circuitName'] ?? 'N/A',
    );
  }
}
