class Race {
  final String season;
  final String round;
  final String name; // raceName
  final String date; // date
  final String circuit; // circuitName (de Circuit)
  final bool hasSprint; // Nuevo campo
  final bool completed; // Indica si la carrera ya pasó

  Race({
    required this.season,
    required this.round,
    required this.name,
    required this.date,
    required this.circuit,
    required this.hasSprint, // Nuevo campo
    this.completed = false, // Por defecto, no está completada
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    // Verificar si la fecha de la carrera ya pasó
    bool isCompleted = false;
    try {
      final raceDate = DateTime.parse(json['date'] ?? '');
      final now = DateTime.now();
      isCompleted = raceDate.isBefore(now);
    } catch (e) {
      // Si hay error al parsear la fecha, asumimos que no está completada
      isCompleted = false;
    }

    return Race(
      season: json['season'].toString(),
      round: json['round'].toString(),
      name: json['name'] ?? json['raceName'] ?? 'N/A',
      date: json['date'] ?? 'N/A',
      circuit: json['circuit'] ?? 'N/A',
      hasSprint: json['has_sprint'] ?? false, // Nuevo campo
      completed: json['completed'] ??
          isCompleted, // Usar el valor del JSON o calcularlo
    );
  }
}
